package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatTurnResponseDto {
    private String rabbitReply;
    private String rabbitReplyEn;
    private CorrectionDto correction;
    private String missionStatus; // in_progress | cleared | failed

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
