package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.demo.DemoAiGate;
import com.hdy.maru.demo.DemoLimitException;
import com.hdy.maru.demo.DemoProperties;
import com.hdy.maru.dto.AiLabExploreRequestDto;
import com.hdy.maru.dto.ChatTurnRequestDto;
import com.hdy.maru.dto.ChatTurnResponseDto;
import com.hdy.maru.dto.MissionSetupRequestDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.entity.AiCache;
import com.hdy.maru.entity.TtsCache;
import com.hdy.maru.repository.AiCacheRepository;
import com.hdy.maru.repository.TtsCacheRepository;
import com.hdy.maru.util.PromptLoader;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * The real gate wired into the real services; only the network call is fake.
 * Shows: no deadlock in the parallel rabbit/turtle turn, cache hits are free, limit errors reach the controller.
 */
class DemoLimitsWiringTest {

    private static final String RABBIT = "{\"rabbit_reply\":\"네, 있어요.\",\"mission_status\":\"in_progress\"}";
    private static final String TURTLE = "{\"severity\":\"none\",\"issue_type\":\"none\"}";
    private static final String SETUP_JSON = """
            {"persona":{"role":"barista","personality":"kind","speech_style":"polite","honorific_level":"polite",
              "first_message":"어서 오세요","first_message_en":"Welcome"},
             "mission":{"title":"Order","description":"Order coffee",
              "clear_condition":{"goal_condition":"Order one drink","language_condition":"Use -요"},"min_turns":3}}""";
    private static final String GEMINI_BODY = """
            {"candidates":[{"content":{"parts":[{"text":"[{\\"text\\":\\"가요\\",\\"type\\":\\"A\\",\\"explanation\\":\\"a\\"},{\\"text\\":\\"갑니다\\",\\"type\\":\\"B\\",\\"explanation\\":\\"b\\"},{\\"text\\":\\"가\\",\\"type\\":\\"C\\",\\"explanation\\":\\"c\\"}]"}]}}]}""";

    /** OpenAiService with the HTTP request replaced. */
    private static final class FakeOpenAi extends OpenAiService {
        final AtomicInteger calls = new AtomicInteger();
        final AtomicInteger running = new AtomicInteger();
        final AtomicInteger peak = new AtomicInteger();
        final long delayMs;
        final String setupAnswer;

        FakeOpenAi(DemoAiGate gate, long delayMs, String setupAnswer) {
            super(new ObjectMapper());
            this.delayMs = delayMs;
            this.setupAnswer = setupAnswer;
            ReflectionTestUtils.setField(this, "demoAiGate", gate);
        }

        @Override
        String requestCompletion(String systemPrompt, List<Map<String, String>> history) {
            calls.incrementAndGet();
            peak.accumulateAndGet(running.incrementAndGet(), Math::max);
            try {
                Thread.sleep(delayMs);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                running.decrementAndGet();
            }
            if (setupAnswer != null) return setupAnswer;
            return systemPrompt.startsWith("You are playing") ? RABBIT : TURTLE;
        }
    }

    private static DemoProperties on(int slots) {
        DemoProperties props = new DemoProperties();
        props.setEnabled(true);
        props.setMaxConcurrentAi(slots);
        props.setAiWaitSeconds(30);
        return props;
    }

    private static void loginAs(String oauthId) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(oauthId, null, List.of()));
    }

    private static MissionSetupResponseDto setup() {
        return MissionSetupResponseDto.builder()
                .persona(MissionSetupResponseDto.PersonaDto.builder()
                        .role("카페 직원").personality("친절한").speechStyle("존댓말").honorificLevel("존댓말")
                        .firstMessage("어서 오세요!").build())
                .mission(MissionSetupResponseDto.MissionDto.builder()
                        .title("Order a drink").description("Order coffee")
                        .clearCondition(MissionSetupResponseDto.MissionDto.ClearConditionDto.builder()
                                .goalCondition("Order one drink").languageCondition("Use 존댓말").build())
                        .minTurns(4).build())
                .difficulty("hard")
                .build();
    }

    private static ChatTurnRequestDto turn() {
        List<Map<String, String>> history = new ArrayList<>();
        history.add(Map.of("role", "assistant", "content", "어서 오세요!"));
        return ChatTurnRequestDto.builder().userMessage("커피 주세요").conversationHistory(history).setup(setup()).build();
    }

    private static ChatTurnService chatService(OpenAiService openAi, DemoAiGate gate) {
        ChatTurnService service = new ChatTurnService(openAi, new PromptLoader(), new ObjectMapper());
        ReflectionTestUtils.setField(service, "demoAiGate", gate);
        return service;
    }

    @BeforeEach
    @AfterEach
    void clearLogin() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("One slot only: rabbit and turtle take turns, the mission turn finishes (no deadlock)")
    void oneSlot_turnStillCompletes() {
        DemoAiGate gate = new DemoAiGate(on(1));
        FakeOpenAi openAi = new FakeOpenAi(gate, 20, null);
        ChatTurnService service = chatService(openAi, gate);

        ChatTurnResponseDto response = assertTimeoutPreemptively(Duration.ofSeconds(10),
                () -> service.processTurn(turn(), turn().getSetup()));

        assertThat(response.getRabbitReply()).isEqualTo("네, 있어요.");
        assertThat(openAi.calls.get()).isEqualTo(2);
        assertThat(openAi.peak.get()).isEqualTo(1);
    }

    @Test
    @DisplayName("Many visitors at once, few slots: every turn finishes, the cap holds, all slots come back")
    void manyTurns_fewSlots_noDeadlock() throws Exception {
        DemoAiGate gate = new DemoAiGate(on(2));
        FakeOpenAi openAi = new FakeOpenAi(gate, 10, null);
        ChatTurnService service = chatService(openAi, gate);

        int visitors = 20;
        ExecutorService requests = Executors.newFixedThreadPool(visitors);
        CountDownLatch start = new CountDownLatch(1);
        List<Future<ChatTurnResponseDto>> futures = new ArrayList<>();
        for (int i = 0; i < visitors; i++) {
            String user = "guest_" + i;
            futures.add(requests.submit(() -> {
                loginAs(user);
                start.await();
                return service.processTurn(turn(), turn().getSetup());
            }));
        }
        start.countDown();
        for (Future<ChatTurnResponseDto> f : futures) {
            assertThat(f.get(30, TimeUnit.SECONDS).getRabbitReply()).isNotBlank();
        }
        requests.shutdownNow();

        assertThat(openAi.calls.get()).isEqualTo(visitors * 2);
        assertThat(openAi.peak.get()).isLessThanOrEqualTo(2);
        assertThat(ReflectionTestUtils.<Integer>invokeMethod(gate, "availableSlots")).isEqualTo(2);
    }

    @Test
    @DisplayName("Parallel calls still count for the logged-in user (login reaches the pool threads)")
    void parallelCalls_countForTheUser() {
        DemoAiGate gate = new DemoAiGate(on(8));
        ChatTurnService service = chatService(new FakeOpenAi(gate, 1, null), gate);
        loginAs("guest_a");

        service.processTurn(turn(), turn().getSetup());

        assertThat(ReflectionTestUtils.<Integer>invokeMethod(gate, "userCalls", "guest_a")).isEqualTo(2);
    }

    @Test
    @DisplayName("Limit inside the parallel calls comes out as the limit error, not as 502")
    void limitInsideTurn_keepsItsStatus() {
        DemoProperties props = on(8);
        props.setAiCallsPerUser(1);
        DemoAiGate gate = new DemoAiGate(props);
        ChatTurnService service = chatService(new FakeOpenAi(gate, 1, null), gate);
        loginAs("guest_a");

        assertThatThrownBy(() -> service.processTurn(turn(), turn().getSetup()))
                .isInstanceOf(DemoLimitException.class)
                .satisfies(e -> assertThat(((DemoLimitException) e).getStatus()).isEqualTo(HttpStatus.TOO_MANY_REQUESTS));
    }

    @Test
    @DisplayName("Kill switch: a mission turn answers 503 and never reaches OpenAI")
    void killSwitch_turn() {
        DemoProperties props = on(8);
        props.setAiEnabled(false);
        DemoAiGate gate = new DemoAiGate(props);
        FakeOpenAi openAi = new FakeOpenAi(gate, 1, null);
        ChatTurnService service = chatService(openAi, gate);
        loginAs("guest_a");

        assertThatThrownBy(() -> service.processTurn(turn(), turn().getSetup()))
                .isInstanceOf(DemoLimitException.class)
                .satisfies(e -> assertThat(((DemoLimitException) e).getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
        assertThat(openAi.calls.get()).isZero();
    }

    @Test
    @DisplayName("Flag off: the turn runs through the same code with no limit at all")
    void flagOff_turnUnlimited() {
        DemoProperties props = new DemoProperties();
        props.setAiCallsPerUser(0);
        props.setDailyAiCalls(0);
        props.setAiEnabled(false);
        DemoAiGate gate = new DemoAiGate(props);
        FakeOpenAi openAi = new FakeOpenAi(gate, 1, null);
        ChatTurnService service = chatService(openAi, gate);

        for (int i = 0; i < 3; i++) {
            assertThat(service.processTurn(turn(), turn().getSetup()).getRabbitReply()).isNotBlank();
        }

        assertThat(openAi.calls.get()).isEqualTo(6);
    }

    @Test
    @DisplayName("Mission limit: third mission refused before any AI call; failed setup does not count")
    void missionStarts() {
        DemoProperties props = on(8);
        props.setMissionStartsPerUser(1);
        DemoAiGate gate = new DemoAiGate(props);
        loginAs("guest_a");
        MissionSetupRequestDto request = MissionSetupRequestDto.builder()
                .hierarchy("peer").intimacy("close").difficulty("hard").build();

        // The model answers garbage: mission not created, allowance given back
        MissionSetupService broken = setupService(new FakeOpenAi(gate, 1, "not json"), gate);
        assertThatThrownBy(() -> broken.generateMission(request)).isInstanceOf(MissionChatException.class);

        FakeOpenAi openAi = new FakeOpenAi(gate, 1, SETUP_JSON);
        MissionSetupService service = setupService(openAi, gate);
        assertThat(service.generateMission(request).getDifficulty()).isEqualTo("easy");
        assertThat(openAi.calls.get()).isEqualTo(1);

        assertThatThrownBy(() -> service.generateMission(request)).isInstanceOf(DemoLimitException.class);
        assertThat(openAi.calls.get()).isEqualTo(1);
    }

    private static MissionSetupService setupService(OpenAiService openAi, DemoAiGate gate) {
        MissionSetupService service = new MissionSetupService(openAi, new PromptLoader(), new ObjectMapper());
        ReflectionTestUtils.setField(service, "demoAiGate", gate);
        return service;
    }

    // ---- cache hits are free ----

    private static OpenAiTtsClient fakeTts(DemoAiGate gate, AtomicInteger calls) {
        OpenAiTtsClient client = new OpenAiTtsClient() {
            @Override
            byte[] requestSpeech(String text, String model, String voice, String instructions) {
                calls.incrementAndGet();
                return new byte[]{1};
            }
        };
        ReflectionTestUtils.setField(client, "demoAiGate", gate);
        return client;
    }

    @Test
    @DisplayName("TTS: cached clips never count or wait; a new clip over the limit is refused")
    void tts_cacheHitIsFree() {
        DemoProperties props = on(1);
        props.setTtsMissesPerUser(1);
        props.setAiWaitSeconds(0);
        DemoAiGate gate = new DemoAiGate(props);
        AtomicInteger calls = new AtomicInteger();
        TtsCacheRepository repo = mock(TtsCacheRepository.class);
        TtsCache cached = new TtsCache();
        cached.setAudio(new byte[]{9});
        when(repo.findByCacheKey(anyString())).thenReturn(Optional.of(cached));
        TtsService service = new TtsService(repo, fakeTts(gate, calls));
        loginAs("guest_a");

        // All AI capacity is in use and the daily limit would not matter: the hit returns anyway
        Thread holder = holdOnlySlot(gate);
        for (int i = 0; i < 5; i++) {
            assertThat(service.speak("안녕").cacheHit()).isTrue();
        }
        holder.interrupt();
        assertThat(calls.get()).isZero();
        assertThat(ReflectionTestUtils.<Integer>invokeMethod(gate, "userCalls", "guest_a")).isZero();

        when(repo.findByCacheKey(anyString())).thenReturn(Optional.empty());
        props.setAiWaitSeconds(5);
        assertThat(service.speak("새 문장").cacheHit()).isFalse();
        assertThatThrownBy(() -> service.speak("또 새 문장")).isInstanceOf(DemoLimitException.class);
        assertThat(calls.get()).isEqualTo(1);
    }

    /** Fills the single slot from another thread until interrupted. */
    private static Thread holdOnlySlot(DemoAiGate gate) {
        CountDownLatch holding = new CountDownLatch(1);
        Thread holder = new Thread(() -> gate.call(DemoAiGate.AiKind.CHAT, () -> {
            holding.countDown();
            try {
                Thread.sleep(30_000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return "held";
        }));
        holder.setDaemon(true);
        holder.start();
        try {
            assertThat(holding.await(5, TimeUnit.SECONDS)).isTrue();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return holder;
    }

    @Test
    @DisplayName("Sentence Lab: a cached answer works even past the limit and with AI switched off")
    void lab_cacheHitIsFree() {
        DemoProperties props = on(8);
        props.setLabMissesPerUser(1);
        props.setAiWaitSeconds(1);
        DemoAiGate gate = new DemoAiGate(props);
        RestTemplate rest = mock(RestTemplate.class);
        when(rest.postForObject(anyString(), any(HttpEntity.class), eq(String.class))).thenReturn(GEMINI_BODY);
        GeminiService gemini = new GeminiService(rest, new ObjectMapper());
        ReflectionTestUtils.setField(gemini, "geminiApiKey", "test");
        ReflectionTestUtils.setField(gemini, "geminiApiUrl", "http://test");
        ReflectionTestUtils.setField(gemini, "demoAiGate", gate);
        AiCacheRepository cache = mock(AiCacheRepository.class);
        AiLabService service = new AiLabService(cache, gemini, new ObjectMapper());
        loginAs("guest_a");

        AiCache hit = new AiCache();
        hit.setOutputText("""
                [{"text":"가요","type":"A","explanation":"a"},{"text":"갑니다","type":"B","explanation":"b"},{"text":"가","type":"C","explanation":"c"}]""");
        when(cache.findByInputTextAndTransformationType(eq("저는 가요"), anyString())).thenReturn(Optional.of(hit));
        when(cache.findByInputTextAndTransformationType(eq("새 문장이에요"), anyString())).thenReturn(Optional.empty());
        when(cache.findByInputTextAndTransformationType(eq("또 새 문장이에요"), anyString())).thenReturn(Optional.empty());

        assertThat(service.exploreCategory(explore("새 문장이에요"))).hasSize(3); // miss: uses the 1 allowed
        assertThatThrownBy(() -> service.exploreCategory(explore("또 새 문장이에요")))
                .isInstanceOf(DemoLimitException.class);
        verify(rest, org.mockito.Mockito.times(1)).postForObject(anyString(), any(HttpEntity.class), eq(String.class));

        // Past the limit: the cached sentence still answers
        assertThat(service.exploreCategory(explore("저는 가요"))).hasSize(3);
    }

    @Test
    @DisplayName("Sentence Lab with AI switched off: cached answer works, new sentence gets the 503 message")
    void lab_killSwitch() {
        DemoProperties props = on(8);
        props.setAiEnabled(false);
        DemoAiGate gate = new DemoAiGate(props);
        RestTemplate rest = mock(RestTemplate.class);
        GeminiService gemini = new GeminiService(rest, new ObjectMapper());
        ReflectionTestUtils.setField(gemini, "demoAiGate", gate);
        AiCacheRepository cache = mock(AiCacheRepository.class);
        AiLabService service = new AiLabService(cache, gemini, new ObjectMapper());
        loginAs("guest_a");

        AiCache hit = new AiCache();
        hit.setOutputText("""
                [{"text":"가요","type":"A","explanation":"a"},{"text":"갑니다","type":"B","explanation":"b"},{"text":"가","type":"C","explanation":"c"}]""");
        when(cache.findByInputTextAndTransformationType(eq("저는 가요"), anyString())).thenReturn(Optional.of(hit));
        when(cache.findByInputTextAndTransformationType(eq("새 문장이에요"), anyString())).thenReturn(Optional.empty());

        assertThat(service.exploreCategory(explore("저는 가요"))).hasSize(3);
        assertThatThrownBy(() -> service.exploreCategory(explore("새 문장이에요")))
                .isInstanceOf(DemoLimitException.class)
                .satisfies(e -> assertThat(((DemoLimitException) e).getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
        verify(rest, never()).postForObject(anyString(), any(HttpEntity.class), eq(String.class));
    }

    private static AiLabExploreRequestDto explore(String input) {
        AiLabExploreRequestDto request = new AiLabExploreRequestDto();
        request.setInputText(input);
        request.setCategory("tense");
        return request;
    }
}
