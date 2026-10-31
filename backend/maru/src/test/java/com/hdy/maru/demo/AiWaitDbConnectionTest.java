package com.hdy.maru.demo;

import com.hdy.maru.entity.User;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.security.JwtProvider;
import com.hdy.maru.service.OpenAiTtsClient;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

/**
 * Why the demo server runs with SPRING_JPA_OPENINVIEW=false: requests that sit in a slow AI call must not keep a
 * database connection, or lessons and vocabulary stop working while Tokki is busy. Pool of 2, three slow AI calls.
 */
@SpringBootTest(properties = {
        "maru.demo.enabled=true",
        "spring.jpa.open-in-view=false",
        "spring.datasource.hikari.maximum-pool-size=2",
        "spring.datasource.hikari.connection-timeout=1000"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AiWaitDbConnectionTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtProvider jwtProvider;

    @Autowired
    private UserRepository userRepository;

    @MockitoBean
    private OpenAiTtsClient ttsClient;

    @Test
    @DisplayName("While AI calls are in progress, other requests still get a DB connection")
    void slowAiCalls_doNotBlockLessons() throws Exception {
        int slowCalls = 3;
        CountDownLatch allInAi = new CountDownLatch(slowCalls);
        CountDownLatch finishAi = new CountDownLatch(1);
        when(ttsClient.synthesize(any(), any(), any(), any())).thenAnswer(invocation -> {
            allInAi.countDown();
            finishAi.await(20, TimeUnit.SECONDS);
            return new byte[]{1};
        });

        User user = new User();
        user.setOauthProvider("guest");
        user.setOauthId("guest_db_wait");
        user.setNickname("Guest");
        userRepository.save(user);
        String auth = "Bearer " + jwtProvider.generateToken("guest_db_wait", "ROLE_USER");
        ExecutorService pool = Executors.newFixedThreadPool(slowCalls);
        List<Future<Integer>> ttsRequests = new ArrayList<>();
        AtomicInteger number = new AtomicInteger();
        for (int i = 0; i < slowCalls; i++) {
            ttsRequests.add(pool.submit(() -> mockMvc.perform(get("/api/tts")
                            .param("text", "새로운 문장 " + number.incrementAndGet())
                            .header(HttpHeaders.AUTHORIZATION, auth))
                    .andReturn().getResponse().getStatus()));
        }
        boolean reachedAi = allInAi.await(10, TimeUnit.SECONDS);

        // Any plain DB read stands for lessons and vocabulary here (the lessons table needs PostgreSQL's jsonb).
        int otherRequestStatus = mockMvc.perform(get("/api/me").header(HttpHeaders.AUTHORIZATION, auth))
                .andReturn().getResponse().getStatus();

        finishAi.countDown();
        for (Future<Integer> request : ttsRequests) {
            assertThat(request.get(20, TimeUnit.SECONDS)).isEqualTo(200);
        }
        pool.shutdownNow();

        assertThat(reachedAi).isTrue();
        assertThat(otherRequestStatus).isEqualTo(200);
    }
}
