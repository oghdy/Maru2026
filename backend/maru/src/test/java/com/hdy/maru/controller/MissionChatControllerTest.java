package com.hdy.maru.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.ChatTurnRequestDto;
import com.hdy.maru.dto.ChatTurnResponseDto;
import com.hdy.maru.dto.MissionSetupRequestDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import com.hdy.maru.service.ChatTurnService;
import com.hdy.maru.service.MissionClearanceService;
import com.hdy.maru.service.MissionSetupService;
import com.hdy.maru.service.MissionSuggestionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.util.ArrayList;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Controller wiring test. AI-calling services are mocked so the test never hits OpenAI.
 */
// jwt.secret: dummy test-only key (real secret comes from .env, not available in tests)
@SpringBootTest(properties = "jwt.secret=bWlzc2lvbi1jb250cm9sbGVyLXRlc3QtZHVtbXkta2U=")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MissionChatControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private MissionSetupService missionSetupService;

    @MockitoBean
    private ChatTurnService chatTurnService;

    @MockitoBean
    private MissionClearanceService missionClearanceService;

    @MockitoBean
    private MissionSuggestionService missionSuggestionService;

    // Same principal shape as JwtAuthenticationFilter (principal = oauthId string)
    private static RequestPostProcessor asUser(String oauthId) {
        return authentication(new UsernamePasswordAuthenticationToken(
                oauthId, null, List.of(new SimpleGrantedAuthority("ROLE_USER"))));
    }

    @Test
    void testSetupMission() throws Exception {
        MissionSetupRequestDto request = MissionSetupRequestDto.builder()
                .hierarchy("윗사람")
                .intimacy("초면")
                .role("직장 상사")
                .personality("엄격한")
                .build();
        MissionSetupResponseDto response = MissionSetupResponseDto.builder()
                .mission(MissionSetupResponseDto.MissionDto.builder().title("Report to your boss").minTurns(5).build())
                .build();
        when(missionSetupService.generateMission(any())).thenReturn(response);

        mockMvc.perform(post("/api/v1/mission-chat/setup")
                        .with(asUser("test_user"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.mission.title").value("Report to your boss"));
    }

    @Test
    void testSetupMission_Unauthorized() throws Exception {
        MissionSetupRequestDto request = new MissionSetupRequestDto();
        mockMvc.perform(post("/api/v1/mission-chat/setup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().is4xxClientError());
    }

    @Test
    void testChatTurn() throws Exception {
        ChatTurnRequestDto request = ChatTurnRequestDto.builder()
                .userMessage("안녕하세요")
                .conversationHistory(new ArrayList<>())
                .setup(MissionSetupResponseDto.builder().build())
                .build();
        when(chatTurnService.processTurn(any(), any())).thenReturn(
                ChatTurnResponseDto.builder().rabbitReply("네, 안녕하세요.").missionStatus("in_progress").build());

        mockMvc.perform(post("/api/v1/mission-chat/chat")
                        .with(asUser("test_user"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.missionStatus").value("in_progress"));
    }

    @Test
    void testGetClearances() throws Exception {
        when(missionClearanceService.getUserClearances(eq("test_user"))).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/mission-chat/clearances").with(asUser("test_user")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }
}
