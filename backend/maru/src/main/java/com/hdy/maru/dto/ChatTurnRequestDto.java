package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatTurnRequestDto {
    private String userMessage;
    private List<Map<String, String>> conversationHistory;
    private MissionSetupResponseDto setup; // Stateless: client sends context every turn
    private List<Integer> completedSteps;  // Optional: the last /chat value, so finished steps stay finished
}
