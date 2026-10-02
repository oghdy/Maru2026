package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MissionSetupResponseDto {
    private PersonaDto persona;
    private MissionDto mission;
    private String adjustmentNotice;
    private String difficulty; // easy | normal | hard — echoed back by the app on /chat, /suggestion, /clearance

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
