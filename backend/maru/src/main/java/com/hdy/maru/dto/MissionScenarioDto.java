package com.hdy.maru.dto;

import lombok.Data;

import java.util.List;
import java.util.Map;

/** One scenario card (resources/scenarios/mission_scenarios.json). Starting one needs no AI call. */
@Data
public class MissionScenarioDto {
    private String id;
    private String icon;        // key the app maps to an icon
    private String title;
    private String description;
    private String role;
    private String roleEn;
    private String personality;
    private String personalityEn;
    private String hierarchy;   // relationship, English card text
    private String intimacy;    // Stranger | Acquaintance | Close
    private String speechStyle;
    private String honorificLevel;
    private String learnerSpeechLevel;
    private Map<String, Level> levels; // easy | normal | hard

    @Data
    public static class Level {
        private String firstMessage;
        private String firstMessageEn;
        private String missionTitle;
        private String missionDescription;
        private String goalCondition;
        private String languageCondition;
        private List<String> steps;
        private int minTurns;
    }
}
