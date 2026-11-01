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
public class ChatTurnResponseDto {
    private String rabbitReply;
    private String rabbitReplyEn;
    private CorrectionDto correction;
    private String missionStatus; // in_progress | cleared | failed (server-enforced 3-zone)
    private int userTurn;   // user turns including this one
    private int minTurns;
    private int maxTurns;   // conversation always ends (cleared/failed) by this turn
    private String zone;    // A | B | C
    private List<Integer> completedSteps; // 1-based numbers of setup.steps finished so far; [] when none
    private String praise;   // short turtle praise, only on some error-free turns; otherwise null
    private String praiseEn;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CorrectionDto {
        private String severity; // immediate | side | none
        private String issueType; // honorific_mismatch | grammar_error | vocabulary | pragmatic | off_topic | none
        private String userInputProblematic;
        private String correctExpression;
        private String turtleFeedback;
        private String turtleFeedbackEn;
    }
}
