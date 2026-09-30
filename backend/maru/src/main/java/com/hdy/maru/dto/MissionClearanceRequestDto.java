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
public class MissionClearanceRequestDto {
    private MissionSetupResponseDto setup;
    private List<Map<String, String>> conversationHistory;
    private String missionStatus; // optional: last /chat status (cleared | failed), hint only
}
