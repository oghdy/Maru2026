package com.hdy.maru.demo;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * A demo limit stopped an AI call. Thrown only while maru.demo.enabled=true.
 * The message is shown to the learner as is; GlobalExceptionHandler turns it into {status, message, data:null}.
 */
@Getter
public class DemoLimitException extends RuntimeException {

    private final HttpStatus status;
    /** Short machine-friendly reason, for logs only. */
    private final String reason;

    private DemoLimitException(HttpStatus status, String reason, String userMessage) {
        super(userMessage);
        this.status = status;
        this.reason = reason;
    }

    static DemoLimitException missionStarts(int limit) {
        return new DemoLimitException(HttpStatus.TOO_MANY_REQUESTS, "mission-starts",
                "You've played your " + limit + " free " + (limit == 1 ? "mission" : "missions")
                        + " in this demo. Tokki says thanks! Lessons and vocabulary are still open.");
    }

    static DemoLimitException labMisses(int limit) {
        return new DemoLimitException(HttpStatus.TOO_MANY_REQUESTS, "lab-misses",
                "You've used your " + limit + " free custom " + (limit == 1 ? "sentence" : "sentences")
                        + " in this demo. The example sentences still work!");
    }

    static DemoLimitException ttsMisses(int limit) {
        return new DemoLimitException(HttpStatus.TOO_MANY_REQUESTS, "tts-misses",
                "The natural voice limit for this demo is used up (" + limit + " new clips).");
    }

    static DemoLimitException userCalls() {
        return new DemoLimitException(HttpStatus.TOO_MANY_REQUESTS, "user-calls",
                "You've reached the AI limit for this demo. Tokki needs a rest, but lessons and vocabulary are still open.");
    }

    static DemoLimitException dailyCalls() {
        return new DemoLimitException(HttpStatus.TOO_MANY_REQUESTS, "daily-calls",
                "Tokki has talked with a lot of visitors today and needs a rest. Lessons and vocabulary are still open.");
    }

    static DemoLimitException aiOff() {
        return new DemoLimitException(HttpStatus.SERVICE_UNAVAILABLE, "ai-off",
                "Tokki is taking a break, so AI features are paused. Lessons and vocabulary are still open.");
    }

    static DemoLimitException busy() {
        return new DemoLimitException(HttpStatus.SERVICE_UNAVAILABLE, "busy",
                "Tokki is busy with other visitors. Please try again in a moment.");
    }

    static DemoLimitException guestIssue() {
        return new DemoLimitException(HttpStatus.TOO_MANY_REQUESTS, "guest-issue",
                "Lots of visitors just arrived. Please try again in a minute.");
    }
}
