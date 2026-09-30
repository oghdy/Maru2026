package com.hdy.maru.service;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Mission chat error with an HTTP status and a user-facing (English) message.
 * Handled by MissionChatController; the message is safe to show in the app.
 */
@Getter
public class MissionChatException extends RuntimeException {

    public static final String MSG_BAD_REQUEST = "Some mission information is missing. Please start the mission again.";
    public static final String MSG_AI_UNAVAILABLE = "The conversation partner is not available right now. Please try again later.";
    public static final String MSG_AI_TIMEOUT = "The AI took too long to respond. Please try again.";
    public static final String MSG_AI_FAILED = "The AI service is having trouble. Please try again in a moment.";
    public static final String MSG_AI_BAD_ANSWER = "The AI gave an unexpected answer. Please try again.";
    public static final String MSG_USER_NOT_FOUND = "Your account could not be found. Please sign in again.";

    private final HttpStatus status;

    public MissionChatException(HttpStatus status, String userMessage) {
        super(userMessage);
        this.status = status;
    }

    public MissionChatException(HttpStatus status, String userMessage, Throwable cause) {
        super(userMessage, cause);
        this.status = status;
    }

    public static MissionChatException badRequest() {
        return new MissionChatException(HttpStatus.BAD_REQUEST, MSG_BAD_REQUEST);
    }

    public static MissionChatException badAiAnswer(Throwable cause) {
        return new MissionChatException(HttpStatus.BAD_GATEWAY, MSG_AI_BAD_ANSWER, cause);
    }
}
