package com.hdy.maru.dto;

import com.hdy.maru.entity.MissionClearance;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MissionClearanceResponseDto {
    private Long id;
    private String missionTitle;
    private String persona;
    private int totalTurns;
    private List<Map<String, String>> goodExpressions;
    private List<Map<String, String>> incorrectExpressions;
    private String turtleComment;
    private String nextPractice;
    private LocalDateTime clearedAt;
    private Boolean cleared;       // AI-judged goal achievement; null = legacy certificate (not judged)
    private String resultReason;
    private String goalCondition;
    private String difficulty;     // easy | normal | hard; null = issued before difficulty existed

    public static MissionClearanceResponseDto fromEntity(MissionClearance entity) {
        return MissionClearanceResponseDto.builder()
                .id(entity.getId())
                .missionTitle(entity.getMissionTitle())
                .persona(entity.getPersona())
                .totalTurns(entity.getTotalTurns())
                .goodExpressions(entity.getGoodExpressions())
                .incorrectExpressions(entity.getIncorrectExpressions())
                .turtleComment(entity.getTurtleComment())
                .nextPractice(entity.getNextPractice())
                .clearedAt(entity.getClearedAt())
                .cleared(entity.getCleared())
                .resultReason(entity.getResultReason())
                .goalCondition(entity.getGoalCondition())
                .difficulty(entity.getDifficulty())
                .build();
    }
}
