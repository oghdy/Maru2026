package com.hdy.maru.demo;

import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.concurrent.DelegatingSecurityContextExecutor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Semaphore;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;

/**
 * The three demo limits, applied where a real AI request leaves the server, so a cache hit never gets here:
 * per-user counts, a global concurrency cap (with a bounded wait) and a daily cap plus kill switch.
 * <p>
 * With maru.demo.enabled=false every method is a plain pass-through.
 * <p>
 * A slot is held for one HTTP call only and never while waiting for another slot, so the parallel rabbit and
 * turtle calls of a mission turn cannot deadlock each other. State lives in memory: one instance, and a
 * restart clears every count.
 */
@Slf4j
@Component
public class DemoAiGate {

    public enum AiKind { CHAT, LAB, TTS }

    private static final ZoneId DEMO_ZONE = ZoneId.of("Asia/Seoul");
    private static final String EASY = "easy";

    /** Used until Spring injects the real gate, and in tests that build services by hand. */
    private static final DemoAiGate PASS_THROUGH = new DemoAiGate(new DemoProperties());

    private final DemoProperties props;
    private final Semaphore slots;
    private final WindowCounter<LocalDate> dailyCalls;
    private final Map<String, Usage> usageByUser = new ConcurrentHashMap<>();
    private final ExecutorService executor;

    @Autowired
    public DemoAiGate(DemoProperties props) {
        this(props, Clock.system(DEMO_ZONE));
    }

    DemoAiGate(DemoProperties props, Clock clock) {
        this.props = props;
        this.slots = new Semaphore(Math.max(1, props.getMaxConcurrentAi()), true);
        this.dailyCalls = new WindowCounter<>(() -> LocalDate.now(clock.withZone(DEMO_ZONE)));
        this.executor = props.isEnabled() ? newExecutor(props.getMaxConcurrentAi()) : null;
    }

    public static DemoAiGate passThrough() {
        return PASS_THROUGH;
    }

    /** Runs one real AI request behind the limits. */
    public <T> T call(AiKind kind, Supplier<T> realCall) {
        if (!props.isEnabled()) {
            return realCall.get();
        }
        if (!props.isAiEnabled()) {
            throw logged(DemoLimitException.aiOff());
        }
        Usage usage = currentUsage();
        if (usage != null) {
            reserve(usage, kind);
        }
        if (!dailyCalls.tryAcquire(props.getDailyAiCalls())) {
            if (usage != null) usage.refund(kind);
            throw logged(DemoLimitException.dailyCalls());
        }
        if (!acquireSlot()) {
            // The call never ran: nothing was spent, so nothing is charged.
            dailyCalls.refund();
            if (usage != null) usage.refund(kind);
            throw logged(DemoLimitException.busy());
        }
        try {
            int today = dailyCalls.count();
            if (today % 100 == 0) {
                log.info("Demo AI calls today: {}", today);
            }
            return realCall.get();
        } catch (RuntimeException e) {
            // A failed clip or lab sentence does not use up the visitor's allowance. It still counts as an attempt
            // for the per-user and daily totals, so a failing call cannot be retried forever.
            if (usage != null) usage.refundKind(kind);
            throw e;
        } finally {
            slots.release();
        }
    }

    /**
     * Starts one parallel AI call of a mission turn. Off: same as CompletableFuture.supplyAsync.
     * On: a separate pool, because waiting for a slot in the common pool would block unrelated work
     * and the common pool can be as small as one thread on a small container. The login is passed along
     * so the call counts for the right user. When the pool is full the request thread runs the call.
     */
    public <T> CompletableFuture<T> supplyAsync(Supplier<T> task) {
        if (executor == null) {
            return CompletableFuture.supplyAsync(task);
        }
        return CompletableFuture.supplyAsync(task,
                new DelegatingSecurityContextExecutor(executor, SecurityContextHolder.getContext()));
    }

    /** Counts a new mission. Conversation and report calls of a started mission are not stopped by this limit. */
    public void reserveMissionStart() {
        if (!props.isEnabled()) {
            return;
        }
        Usage usage = currentUsage();
        if (usage != null && !usage.tryStartMission(props.getMissionStartsPerUser())) {
            throw logged(DemoLimitException.missionStarts(props.getMissionStartsPerUser()));
        }
    }

    /** The mission could not be created, so it does not count as played. */
    public void refundMissionStart() {
        if (!props.isEnabled()) {
            return;
        }
        Usage usage = currentUsage();
        if (usage != null) {
            usage.refundMission();
        }
    }

    /** Easy-only rule: returns "easy" while it is on, otherwise the value unchanged. */
    public String enforceDifficulty(String difficulty) {
        return props.isEnabled() && props.isMissionEasyOnly() ? EASY : difficulty;
    }

    /** Called by the guest API for its own rate limit error message. */
    static DemoLimitException guestIssueLimit() {
        return logged(DemoLimitException.guestIssue());
    }

    @PreDestroy
    void shutdown() {
        if (executor != null) {
            executor.shutdown();
        }
    }

    // ---- for tests ----

    int availableSlots() {
        return slots.availablePermits();
    }

    int dailyCount() {
        return dailyCalls.count();
    }

    int userCalls(String oauthId) {
        Usage usage = usageByUser.get(oauthId);
        return usage == null ? 0 : usage.calls();
    }

    // ---- internals ----

    private void reserve(Usage usage, AiKind kind) {
        int kindLimit = switch (kind) {
            case LAB -> props.getLabMissesPerUser();
            case TTS -> props.getTtsMissesPerUser();
            case CHAT -> Integer.MAX_VALUE;
        };
        switch (usage.tryReserve(kind, kindLimit, props.getAiCallsPerUser())) {
            case OK -> { }
            case KIND_LIMIT -> throw logged(kind == AiKind.LAB
                    ? DemoLimitException.labMisses(kindLimit)
                    : DemoLimitException.ttsMisses(kindLimit));
            case TOTAL_LIMIT -> throw logged(DemoLimitException.userCalls());
        }
    }

    private boolean acquireSlot() {
        try {
            return slots.tryAcquire(props.getAiWaitSeconds(), TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    private Usage currentUsage() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken) {
            return null;
        }
        return usageByUser.computeIfAbsent(auth.getName(), key -> new Usage());
    }

    private static DemoLimitException logged(DemoLimitException e) {
        log.info("Demo limit reached: {}", e.getReason()); // no user id or content
        return e;
    }

    private static ExecutorService newExecutor(int maxConcurrentAi) {
        AtomicInteger threadNumber = new AtomicInteger();
        // Room for the calls that are running plus the ones waiting for a slot. No queue: when it is full the
        // caller runs the task, so the only waiting is the bounded wait for a slot.
        ThreadPoolExecutor pool = new ThreadPoolExecutor(0, Math.max(4, maxConcurrentAi * 4), 30, TimeUnit.SECONDS,
                new SynchronousQueue<>(), task -> {
                    Thread thread = new Thread(task, "demo-ai-" + threadNumber.incrementAndGet());
                    thread.setDaemon(true);
                    return thread;
                }, new ThreadPoolExecutor.CallerRunsPolicy());
        return pool;
    }

    private enum Reservation { OK, KIND_LIMIT, TOTAL_LIMIT }

    /** One user's counts. */
    private static final class Usage {
        private int missionStarts;
        private int labMisses;
        private int ttsMisses;
        private int calls;

        synchronized Reservation tryReserve(AiKind kind, int kindLimit, int totalLimit) {
            if (kindCount(kind) >= kindLimit) {
                return Reservation.KIND_LIMIT;
            }
            if (calls >= totalLimit) {
                return Reservation.TOTAL_LIMIT;
            }
            addKind(kind, 1);
            calls++;
            return Reservation.OK;
        }

        synchronized void refund(AiKind kind) {
            addKind(kind, -1);
            calls = Math.max(0, calls - 1);
        }

        synchronized void refundKind(AiKind kind) {
            addKind(kind, -1);
        }

        synchronized boolean tryStartMission(int limit) {
            if (missionStarts >= limit) {
                return false;
            }
            missionStarts++;
            return true;
        }

        synchronized void refundMission() {
            missionStarts = Math.max(0, missionStarts - 1);
        }

        synchronized int calls() {
            return calls;
        }

        private int kindCount(AiKind kind) {
            return switch (kind) {
                case LAB -> labMisses;
                case TTS -> ttsMisses;
                case CHAT -> 0;
            };
        }

        private void addKind(AiKind kind, int delta) {
            switch (kind) {
                case LAB -> labMisses = Math.max(0, labMisses + delta);
                case TTS -> ttsMisses = Math.max(0, ttsMisses + delta);
                case CHAT -> { }
            }
        }
    }
}
