package com.hdy.maru.demo;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;

class DemoAiGateTest {

    @AfterEach
    void clearLogin() {
        SecurityContextHolder.clearContext();
    }

    private static DemoProperties on() {
        DemoProperties props = new DemoProperties();
        props.setEnabled(true);
        props.setAiWaitSeconds(1);
        return props;
    }

    private static void loginAs(String oauthId) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(oauthId, null, List.of()));
    }

    private static void expectLimit(Runnable call, HttpStatus status) {
        assertThatThrownBy(call::run)
                .isInstanceOf(DemoLimitException.class)
                .satisfies(e -> assertThat(((DemoLimitException) e).getStatus()).isEqualTo(status));
    }

    /** A clock the test can move. */
    private static final class MovableClock extends Clock {
        private Instant now;

        MovableClock(String instant) {
            this.now = Instant.parse(instant);
        }

        void advance(Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            MovableClock outer = this;
            return new Clock() {
                @Override
                public ZoneId getZone() {
                    return zone;
                }

                @Override
                public Clock withZone(ZoneId other) {
                    return outer.withZone(other);
                }

                @Override
                public Instant instant() {
                    return outer.now;
                }
            };
        }

        @Override
        public Instant instant() {
            return now;
        }
    }

    // ---- flag off ----

    @Test
    @DisplayName("Off: no limit applies, however low the numbers are, and nothing is counted")
    void off_isPlainPassThrough() {
        DemoProperties props = new DemoProperties(); // enabled=false by default
        props.setAiEnabled(false);
        props.setAiCallsPerUser(0);
        props.setDailyAiCalls(0);
        props.setMissionStartsPerUser(0);
        DemoAiGate gate = new DemoAiGate(props);
        loginAs("u1");

        for (int i = 0; i < 5; i++) {
            assertThat(gate.call(DemoAiGate.AiKind.TTS, () -> "ok")).isEqualTo("ok");
            gate.reserveMissionStart();
        }

        assertThat(gate.userCalls("u1")).isZero();
        assertThat(gate.dailyCount()).isZero();
        assertThat(gate.enforceDifficulty("hard")).isEqualTo("hard");
        assertThat(gate.supplyAsync(() -> "async").join()).isEqualTo("async");
    }

    @Test
    @DisplayName("Off: the original exception comes out unchanged")
    void off_exceptionUnchanged() {
        IllegalStateException failure = new IllegalStateException("boom");
        assertThatThrownBy(() -> DemoAiGate.passThrough().call(DemoAiGate.AiKind.CHAT, () -> {
            throw failure;
        })).isSameAs(failure);
    }

    @Test
    @DisplayName("Default properties: demo is off and limits are the agreed values")
    void defaults() {
        DemoProperties props = new DemoProperties();
        assertThat(props.isEnabled()).isFalse();
        assertThat(props.isAiEnabled()).isTrue();
        assertThat(props.isMissionEasyOnly()).isTrue();
        assertThat(props.getMissionStartsPerUser()).isEqualTo(2);
        assertThat(props.getLabMissesPerUser()).isEqualTo(3);
        assertThat(props.getTtsMissesPerUser()).isEqualTo(15);
        assertThat(props.getAiCallsPerUser()).isEqualTo(60);
        assertThat(props.getMaxConcurrentAi()).isEqualTo(8);
        assertThat(props.getAiWaitSeconds()).isEqualTo(15);
        assertThat(props.getDailyAiCalls()).isEqualTo(3000);
    }

    // ---- per-user counts ----

    @Test
    @DisplayName("Lab and TTS have their own limit per user; another user is not affected")
    void kindLimits() {
        DemoProperties props = on();
        props.setLabMissesPerUser(1);
        props.setTtsMissesPerUser(2);
        DemoAiGate gate = new DemoAiGate(props);

        loginAs("u1");
        gate.call(DemoAiGate.AiKind.LAB, () -> "ok");
        expectLimit(() -> gate.call(DemoAiGate.AiKind.LAB, () -> "ok"), HttpStatus.TOO_MANY_REQUESTS);
        gate.call(DemoAiGate.AiKind.TTS, () -> "ok");
        gate.call(DemoAiGate.AiKind.TTS, () -> "ok");
        expectLimit(() -> gate.call(DemoAiGate.AiKind.TTS, () -> "ok"), HttpStatus.TOO_MANY_REQUESTS);

        loginAs("u2");
        assertThat(gate.call(DemoAiGate.AiKind.LAB, () -> "ok")).isEqualTo("ok");
    }

    @Test
    @DisplayName("The per-user total counts every kind of AI call")
    void totalLimit() {
        DemoProperties props = on();
        props.setAiCallsPerUser(3);
        DemoAiGate gate = new DemoAiGate(props);
        loginAs("u1");

        gate.call(DemoAiGate.AiKind.CHAT, () -> "ok");
        gate.call(DemoAiGate.AiKind.TTS, () -> "ok");
        gate.call(DemoAiGate.AiKind.LAB, () -> "ok");

        expectLimit(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> "ok"), HttpStatus.TOO_MANY_REQUESTS);
        assertThat(gate.userCalls("u1")).isEqualTo(3);
    }

    @Test
    @DisplayName("Mission limit stops new missions only; the mission in progress keeps talking")
    void missionStarts_doNotStopConversation() {
        DemoProperties props = on();
        props.setMissionStartsPerUser(1);
        DemoAiGate gate = new DemoAiGate(props);
        loginAs("u1");

        gate.reserveMissionStart();
        expectLimit(gate::reserveMissionStart, HttpStatus.TOO_MANY_REQUESTS);

        assertThat(gate.call(DemoAiGate.AiKind.CHAT, () -> "turn")).isEqualTo("turn");
        assertThat(gate.call(DemoAiGate.AiKind.CHAT, () -> "report")).isEqualTo("report");
    }

    @Test
    @DisplayName("A mission that could not be created is given back")
    void missionStart_refund() {
        DemoProperties props = on();
        props.setMissionStartsPerUser(1);
        DemoAiGate gate = new DemoAiGate(props);
        loginAs("u1");

        gate.reserveMissionStart();
        gate.refundMissionStart();
        gate.reserveMissionStart();
        expectLimit(gate::reserveMissionStart, HttpStatus.TOO_MANY_REQUESTS);
    }

    @Test
    @DisplayName("A failed call gives back the lab/TTS allowance but still counts as an attempt")
    void failedCall_refundsKindOnly() {
        DemoProperties props = on();
        props.setLabMissesPerUser(1);
        DemoAiGate gate = new DemoAiGate(props);
        loginAs("u1");

        assertThatThrownBy(() -> gate.call(DemoAiGate.AiKind.LAB, () -> {
            throw new IllegalStateException("upstream down");
        })).isInstanceOf(IllegalStateException.class);

        assertThat(gate.userCalls("u1")).isEqualTo(1);
        assertThat(gate.dailyCount()).isEqualTo(1);
        assertThat(gate.availableSlots()).isEqualTo(props.getMaxConcurrentAi());
        assertThat(gate.call(DemoAiGate.AiKind.LAB, () -> "ok")).isEqualTo("ok");
    }

    @Test
    @DisplayName("Many threads at once: exactly the limit gets through")
    void counts_areThreadSafe() throws Exception {
        DemoProperties props = on();
        props.setAiCallsPerUser(50);
        props.setMaxConcurrentAi(16);
        DemoAiGate gate = new DemoAiGate(props);
        var auth = new UsernamePasswordAuthenticationToken("u1", null, List.of());

        int threads = 16;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        AtomicInteger allowed = new AtomicInteger();
        AtomicInteger refused = new AtomicInteger();
        List<Future<?>> futures = new ArrayList<>();
        for (int t = 0; t < threads; t++) {
            futures.add(pool.submit(() -> {
                SecurityContextHolder.getContext().setAuthentication(auth);
                for (int i = 0; i < 25; i++) {
                    try {
                        gate.call(DemoAiGate.AiKind.CHAT, () -> "ok");
                        allowed.incrementAndGet();
                    } catch (DemoLimitException e) {
                        refused.incrementAndGet();
                    }
                }
                SecurityContextHolder.clearContext();
            }));
        }
        for (Future<?> f : futures) f.get(20, TimeUnit.SECONDS);
        pool.shutdownNow();

        assertThat(allowed.get()).isEqualTo(50);
        assertThat(refused.get()).isEqualTo(threads * 25 - 50);
        assertThat(gate.userCalls("u1")).isEqualTo(50);
    }

    // ---- concurrency cap ----

    @Test
    @DisplayName("Never more than the cap at once; waiting calls run when a slot frees up")
    void concurrency_capAndWait() throws Exception {
        DemoProperties props = on();
        props.setMaxConcurrentAi(3);
        props.setAiWaitSeconds(10);
        DemoAiGate gate = new DemoAiGate(props);

        AtomicInteger running = new AtomicInteger();
        AtomicInteger peak = new AtomicInteger();
        ExecutorService pool = Executors.newFixedThreadPool(12);
        List<Future<String>> futures = new ArrayList<>();
        for (int i = 0; i < 12; i++) {
            futures.add(pool.submit(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> {
                int now = running.incrementAndGet();
                peak.accumulateAndGet(now, Math::max);
                try {
                    Thread.sleep(50);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
                running.decrementAndGet();
                return "ok";
            })));
        }
        for (Future<String> f : futures) assertThat(f.get(20, TimeUnit.SECONDS)).isEqualTo("ok");
        pool.shutdownNow();

        assertThat(peak.get()).isEqualTo(3);
        assertThat(gate.availableSlots()).isEqualTo(3);
    }

    @Test
    @DisplayName("Wait too long: 503 after the wait time, nothing charged, the slot still works afterwards")
    void concurrency_waitTimeout_chargesNothing() throws Exception {
        DemoProperties props = on();
        props.setMaxConcurrentAi(1);
        props.setAiWaitSeconds(1);
        DemoAiGate gate = new DemoAiGate(props);

        CountDownLatch holding = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        ExecutorService pool = Executors.newSingleThreadExecutor();
        Future<String> holder = pool.submit(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> {
            holding.countDown();
            try {
                release.await(10, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return "held";
        }));
        assertThat(holding.await(5, TimeUnit.SECONDS)).isTrue();

        loginAs("u1");
        long start = System.nanoTime();
        expectLimit(() -> gate.call(DemoAiGate.AiKind.LAB, () -> "never"), HttpStatus.SERVICE_UNAVAILABLE);
        long waitedMs = (System.nanoTime() - start) / 1_000_000;

        assertThat(waitedMs).isBetween(900L, 5_000L);
        assertThat(gate.userCalls("u1")).isZero();
        assertThat(gate.dailyCount()).isEqualTo(1); // only the holder

        release.countDown();
        assertThat(holder.get(5, TimeUnit.SECONDS)).isEqualTo("held");
        pool.shutdownNow();
        assertThat(gate.availableSlots()).isEqualTo(1);
        assertThat(gate.call(DemoAiGate.AiKind.CHAT, () -> "after")).isEqualTo("after");
    }

    @Test
    @DisplayName("The slot is released when the AI call throws")
    void concurrency_releasedOnFailure() {
        DemoProperties props = on();
        props.setMaxConcurrentAi(1);
        DemoAiGate gate = new DemoAiGate(props);

        for (int i = 0; i < 3; i++) {
            assertThatThrownBy(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> {
                throw new IllegalStateException("timeout");
            })).isInstanceOf(IllegalStateException.class);
        }

        assertThat(gate.availableSlots()).isEqualTo(1);
    }

    @Test
    @DisplayName("A call that is interrupted while waiting does not leak a slot or swallow the interrupt")
    void concurrency_interruptedWhileWaiting() throws Exception {
        DemoProperties props = on();
        props.setMaxConcurrentAi(1);
        props.setAiWaitSeconds(30);
        DemoAiGate gate = new DemoAiGate(props);

        CountDownLatch holding = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        Thread holder = new Thread(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> {
            holding.countDown();
            try {
                release.await(10, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return "held";
        }));
        holder.start();
        assertThat(holding.await(5, TimeUnit.SECONDS)).isTrue();

        AtomicInteger busy = new AtomicInteger();
        boolean[] stillInterrupted = {false};
        Thread waiter = new Thread(() -> {
            try {
                gate.call(DemoAiGate.AiKind.CHAT, () -> "never");
            } catch (DemoLimitException e) {
                busy.incrementAndGet();
                stillInterrupted[0] = Thread.currentThread().isInterrupted();
            }
        });
        waiter.start();
        Thread.sleep(100);
        waiter.interrupt();
        waiter.join(5_000);

        assertThat(busy.get()).isEqualTo(1);
        assertThat(stillInterrupted[0]).isTrue();
        release.countDown();
        holder.join(5_000);
        assertThat(gate.availableSlots()).isEqualTo(1);
    }

    // ---- daily cap and kill switch ----

    @Test
    @DisplayName("Daily cap: 429 when used up, opens again the next day in Seoul")
    void dailyCap_resetsAtSeoulMidnight() {
        DemoProperties props = on();
        props.setDailyAiCalls(2);
        // 14:30 UTC is 23:30 in Seoul
        MovableClock clock = new MovableClock("2026-11-06T14:30:00Z");
        DemoAiGate gate = new DemoAiGate(props, clock);
        loginAs("u1");

        gate.call(DemoAiGate.AiKind.CHAT, () -> "ok");
        gate.call(DemoAiGate.AiKind.CHAT, () -> "ok");
        expectLimit(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> "ok"), HttpStatus.TOO_MANY_REQUESTS);
        assertThat(gate.userCalls("u1")).isEqualTo(2); // the refused call is not charged to the user

        clock.advance(Duration.ofHours(1)); // 00:30 in Seoul
        assertThat(gate.call(DemoAiGate.AiKind.CHAT, () -> "ok")).isEqualTo("ok");
    }

    @Test
    @DisplayName("Kill switch: 503, the AI is not called, nothing is charged")
    void killSwitch() {
        DemoProperties props = on();
        props.setAiEnabled(false);
        DemoAiGate gate = new DemoAiGate(props);
        loginAs("u1");
        AtomicInteger realCalls = new AtomicInteger();

        expectLimit(() -> gate.call(DemoAiGate.AiKind.CHAT, realCalls::incrementAndGet), HttpStatus.SERVICE_UNAVAILABLE);

        assertThat(realCalls.get()).isZero();
        assertThat(gate.userCalls("u1")).isZero();
        assertThat(gate.dailyCount()).isZero();
    }

    @Test
    @DisplayName("Every limit message is a plain English sentence")
    void messages_areUserFacing() {
        List<DemoLimitException> all = List.of(DemoLimitException.missionStarts(2), DemoLimitException.labMisses(3),
                DemoLimitException.ttsMisses(15), DemoLimitException.userCalls(), DemoLimitException.dailyCalls(),
                DemoLimitException.aiOff(), DemoLimitException.busy(), DemoLimitException.guestIssue());
        for (DemoLimitException e : all) {
            assertThat(e.getMessage()).matches("[\\x20-\\x7E]+[.!]").doesNotContain("Exception");
        }
        assertThat(DemoLimitException.missionStarts(1).getMessage()).contains("1 free mission ");
        assertThat(DemoLimitException.missionStarts(2).getMessage()).contains("2 free missions ");
    }

    @Test
    @DisplayName("Easy-only rule follows its own switch")
    void easyOnly() {
        DemoProperties props = on();
        assertThat(new DemoAiGate(props).enforceDifficulty("hard")).isEqualTo("easy");
        props.setMissionEasyOnly(false);
        assertThat(new DemoAiGate(props).enforceDifficulty("hard")).isEqualTo("hard");
    }

    @Test
    @DisplayName("Without a login only the global limits apply")
    void noLogin_globalLimitsOnly() {
        DemoProperties props = on();
        props.setAiCallsPerUser(0);
        props.setDailyAiCalls(1);
        DemoAiGate gate = new DemoAiGate(props);

        assertThat(assertTimeoutPreemptively(Duration.ofSeconds(5),
                () -> gate.call(DemoAiGate.AiKind.CHAT, () -> "ok"))).isEqualTo("ok");
        expectLimit(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> "ok"), HttpStatus.TOO_MANY_REQUESTS);
    }
}
