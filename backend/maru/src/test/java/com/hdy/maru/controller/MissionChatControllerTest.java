package com.hdy.maru.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.dto.ChatTurnRequestDto;
import com.hdy.maru.dto.MissionSetupRequestDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class MissionChatControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @WithMockUser(username = "test_user")
    void testSetupMission() throws Exception {
        MissionSetupRequestDto request = MissionSetupRequestDto.builder()
                .hierarchy("윗사람")
                .intimacy("초면")
                .formality("공적")
                .role("직장 상사")
                .build();

        mockMvc.perform(post("/api/v1/mission-chat/setup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());
    }

    @Test
    void testSetupMission_Unauthorized() throws Exception {
        MissionSetupRequestDto request = new MissionSetupRequestDto();
        mockMvc.perform(post("/api/v1/mission-chat/setup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized()); // Or 403 depending on security config
    }

    @Test
    @WithMockUser(username = "test_user")
    void testChatTurn() throws Exception {
        ChatTurnRequestDto request = ChatTurnRequestDto.builder()
                .userMessage("안녕하세요")
                .conversationHistory(new ArrayList<>())
                .build();

        mockMvc.perform(post("/api/v1/mission-chat/chat")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "test_user")
    void testGetClearances() throws Exception {
        mockMvc.perform(get("/api/v1/mission-chat/clearances"))
                .andExpect(status().isOk());
    }
}
