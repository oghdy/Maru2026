package com.hdy.maru.demo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.entity.User;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.security.JwtProvider;
import com.hdy.maru.service.OpenAiService;
import com.hdy.maru.service.TtsService;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Date;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Demo enabled: guest entry, error format of the limits, extra CORS origin. AI itself is a fake. */
@SpringBootTest(properties = {
        "maru.demo.enabled=true",
        "maru.demo.guest-token-ttl-ms=3600000",
        "maru.demo.mission-starts-per-user=1",
        "maru.demo.mission-easy-only=true", // default is now false; this switch is still tested here
        "maru.cors.extra-origins= https://demo.example.com ,*",
        "maru.cors.max-age-seconds=1800"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GuestApiOnTest {

    private static final String SETUP_JSON = """
            {"persona":{"role":"barista","personality":"kind","speech_style":"polite","honorific_level":"polite",
              "first_message":"어서 오세요","first_message_en":"Welcome"},
             "mission":{"title":"Order","description":"Order coffee",
              "clear_condition":{"goal_condition":"Order one drink","language_condition":"Use -요"},"min_turns":3}}""";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Value("${jwt.secret}")
    private String jwtSecret;

    @MockitoBean
    private OpenAiService openAiService;

    @MockitoBean
    private TtsService ttsService;

    private String newGuestToken() throws Exception {
        String body = mockMvc.perform(post("/api/demo/guest"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(200))
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).path("data").asText();
    }

    @Test
    @DisplayName("Guest API: no login needed, a new user with a nickname and a working JWT each time")
    void guestEntry() throws Exception {
        String token = newGuestToken();
        String other = newGuestToken();
        assertThat(token).isNotBlank().isNotEqualTo(other);

        String me = mockMvc.perform(get("/api/me").header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nickname").value("Guest"))
                .andExpect(jsonPath("$.oauthProvider").value("guest"))
                .andReturn().getResponse().getContentAsString();

        JsonNode meJson = objectMapper.readTree(me);
        assertThat(meJson.path("oauthId").asText()).startsWith("guest_");
        User saved = userRepository.findByOauthId(meJson.path("oauthId").asText()).orElseThrow();
        assertThat(saved.getNickname()).isEqualTo("Guest");
    }

    @Test
    @DisplayName("Guest token lifetime follows the setting")
    void guestToken_ttl() throws Exception {
        var claims = Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtSecret)))
                .build()
                .parseSignedClaims(newGuestToken())
                .getPayload();
        long ttlMs = claims.getExpiration().getTime() - new Date().getTime();

        assertThat(ttlMs).isBetween(3_500_000L, 3_600_000L);
    }

    @Test
    @DisplayName("Second mission: HTTP 429 {status, message, data:null}. Hard request is played as Easy")
    void missionLimit_andEasyOnly() throws Exception {
        when(openAiService.askWithHistory(anyString(), any())).thenReturn(SETUP_JSON);
        String token = newGuestToken();
        String body = """
                {"hierarchy":"peer","intimacy":"close","difficulty":"hard"}""";

        mockMvc.perform(post("/api/v1/mission-chat/setup")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.difficulty").value("easy"));

        mockMvc.perform(post("/api/v1/mission-chat/setup")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.status").value(429))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("1 free mission")))
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    @Test
    @DisplayName("TTS limit answers JSON even when the player asks for audio")
    void ttsLimit_isJsonForAudioClient() throws Exception {
        when(ttsService.speak(anyString())).thenThrow(DemoLimitException.ttsMisses(15));

        mockMvc.perform(get("/api/tts").param("text", "안녕")
                        .accept(MediaType.parseMediaType("audio/mpeg"))
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + newGuestToken()))
                .andExpect(status().isTooManyRequests())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.status").value(429));
    }

    @Test
    @DisplayName("CORS: the extra origin is allowed with max-age, a wildcard in the list is ignored")
    void cors_extraOrigin() throws Exception {
        mockMvc.perform(options("/api/demo/guest")
                        .header(HttpHeaders.ORIGIN, "https://demo.example.com")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "https://demo.example.com"))
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_MAX_AGE, "1800"));

        mockMvc.perform(options("/api/demo/guest")
                        .header(HttpHeaders.ORIGIN, "https://evil.example.com")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST"))
                .andExpect(status().isForbidden());
    }

    @Autowired
    private JwtProvider jwtProvider;

    @Test
    @DisplayName("Regular tokens keep the configured 24 hour lifetime")
    void regularToken_unchanged() {
        var claims = Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtSecret)))
                .build()
                .parseSignedClaims(jwtProvider.generateToken("google_1", "ROLE_USER"))
                .getPayload();
        long ttlMs = claims.getExpiration().getTime() - new Date().getTime();

        assertThat(ttlMs).isBetween(86_300_000L, 86_400_000L);
    }
}
