package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MissionSetupResponseDto {
    private PersonaDto persona;
    private MissionDto mission;
    private String adjustmentNotice;
    private String difficulty; // easy | normal | hard — echoed back by the app on /chat, /suggestion, /clearance
    private List<String> steps;        // 2-3 conversation steps in easy English; a guide, never a condition. null on old setups
    private String learnerSpeechLevel; // 존댓말 | 반말: what the LEARNER should use (the persona's own level may differ)

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PersonaDto {
        private String role;
        private String personality;
        private String speechStyle;
        private String honorificLevel;
        private String firstMessage;
        private String firstMessageEn;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MissionDto {
        private String title;
        private String description;
        private ClearConditionDto clearCondition;
        private int minTurns;

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class ClearConditionDto {
            private String goalCondition;
            private String languageCondition;
        }
    }
}
