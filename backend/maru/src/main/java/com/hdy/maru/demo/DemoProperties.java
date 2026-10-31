package com.hdy.maru.demo;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Web demo settings (prefix maru.demo). Everything is inert unless {@link #enabled} is true,
 * so the production server and the mobile apps behave as if this class did not exist.
 * Values and env vars: application.yaml, docs/features/web-demo/API_CONTRACT.md.
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "maru.demo")
public class DemoProperties {

    /** Master switch. false = guest API is 404 and every gate is a plain pass-through. */
    private boolean enabled = false;
    /** Kill switch for AI features only; lessons, vocabulary, Hangul lab and cached answers keep working. */
    private boolean aiEnabled = true;
    /** Guests only get Easy missions (forced by the server, whatever the client sends). */
    private boolean missionEasyOnly = true;

    /** Guest JWT lifetime. Capped at 24 hours by the guest API. */
    private long guestTokenTtlMs = 12 * 60 * 60 * 1000L;
    /** Guest tokens issued per minute across all visitors. */
    private int guestIssuePerMinute = 300;

    private int missionStartsPerUser = 2;
    /** Sentence Lab requests that miss the cache and reach Gemini. */
    private int labMissesPerUser = 3;
    /** TTS requests that miss the cache and reach OpenAI. */
    private int ttsMissesPerUser = 15;
    /** Every real AI call by one user: mission turns, hints, reports, lab, TTS. */
    private int aiCallsPerUser = 60;

    /** Real AI calls running at the same time across all users. */
    private int maxConcurrentAi = 8;
    /** How long a call may wait for a free slot before it fails with 503. */
    private int aiWaitSeconds = 15;
    /** Real AI calls per day (Asia/Seoul) across all users. */
    private int dailyAiCalls = 3000;
}
