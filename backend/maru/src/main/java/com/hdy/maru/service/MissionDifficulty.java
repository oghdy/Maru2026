package com.hdy.maru.service;

import java.util.Locale;

/**
 * Mission difficulty (easy / normal / hard). Missing or unknown values fall back to EASY.
 * Each level carries the rule text injected into every mission prompt ({{difficulty_rules}})
 * plus the limits the server enforces itself (minTurns range, rabbit reply length).
 */
public enum MissionDifficulty {

    EASY(3, 4, 25,
            """
            Setup: everyday situation with ONE simple, concrete goal (e.g. order one drink, ask a price, say where you are going). \
            Use only TOPIK 1 level words, present tense and polite -요 endings. first_message: one short sentence, at most 25 Korean characters (spaces not counted). \
            Write the English title/description/conditions in very simple English. language_condition must be easy (e.g. "Use polite -요 endings"). min_turns: 3 or 4.""",
            """
            DIFFICULTY = EASY (beginner learner):
            - Reply with exactly ONE short sentence, at most 25 Korean characters (spaces not counted). Never two sentences.
            - Use only TOPIK 1 level words, present tense, polite -요 or simple endings. No idioms, slang or long connectors.
            - Ask at most one very simple question at a time. Do not give extra information the learner did not ask for.""",
            """
            DIFFICULTY = EASY (beginner learner) — be gentle:
            - Only correct mistakes that make the meaning unclear or a clearly wrong speech level (반말/존댓말).
            - A wrong speech level is "side" at this level (do not block the learner); use "immediate" ONLY for a completely off-topic message.
            - Ignore spacing, small spelling slips, missing/odd particles and awkward-but-understandable phrasing → "none".
            - Do not correct honorific vocabulary such as 드시다/계시다/성함 (too advanced for this level).
            - turtle_feedback: one short, simple Korean sentence; correct_expression: short and simple.""",
            """
            DIFFICULTY = EASY: each suggestion is ONE very short sentence (at most about 15 Korean characters), TOPIK 1 words, polite -요 ending.""",
            """
            DIFFICULTY = EASY (beginner): judge leniently — "cleared" if the learner's messages accomplished the goal, even with many small mistakes. \
            List at most 2 incorrect_expressions, only the most important ones. Use very simple English in all explanations."""),

    NORMAL(4, 6, 50,
            """
            Setup: common situation with a goal of 1-2 simple steps. Use TOPIK 2 level words and basic connectors (-고, -아서/어서). \
            first_message: at most 2 short sentences, at most 50 Korean characters (spaces not counted). min_turns: 4 to 6.""",
            """
            DIFFICULTY = NORMAL (elementary learner):
            - Reply with 1 or 2 short sentences, at most 50 Korean characters in total (spaces not counted).
            - Use TOPIK 2 level words and basic grammar. Avoid idioms and rare words.
            - Ask at most one question at a time.""",
            """
            DIFFICULTY = NORMAL (elementary learner):
            - Correct clear grammar, vocabulary and speech-level (반말/존댓말) mistakes.
            - Ignore spacing and small typos → "none". Only point out the most common honorific words (드시다, 계시다) when clearly needed.
            - turtle_feedback: one short sentence.""",
            """
            DIFFICULTY = NORMAL: each suggestion is one short sentence (at most about 30 Korean characters), TOPIK 2 words.""",
            """
            DIFFICULTY = NORMAL: judge fairly — clear the mission when the goal is met with mostly understandable Korean. \
            List at most 3 incorrect_expressions. Keep explanations short and simple."""),

    HARD(5, 10, 80,
            """
            Setup: any realistic situation, natural spoken Korean. first_message: at most 2 sentences, at most 80 Korean characters (spaces not counted). \
            min_turns: 5 to 10 depending on complexity.""",
            """
            DIFFICULTY = HARD (intermediate learner):
            - Natural spoken Korean, but keep it short: at most 2 sentences, at most 80 Korean characters (spaces not counted).
            - Ask at most one question at a time.""",
            """
            DIFFICULTY = HARD (intermediate learner): evaluate with the full rules above, including pragmatic honorific expressions.""",
            """
            DIFFICULTY = HARD: natural sentences a native speaker would say, still concise (one sentence each).""",
            """
            DIFFICULTY = HARD: judge with the full rules above.""");

    private final int minTurnsLow;
    private final int minTurnsHigh;
    private final int rabbitMaxChars;
    private final String setupRules;
    private final String rabbitRules;
    private final String turtleRules;
    private final String suggestionRules;
    private final String clearanceRules;

    MissionDifficulty(int minTurnsLow, int minTurnsHigh, int rabbitMaxChars, String setupRules, String rabbitRules,
                      String turtleRules, String suggestionRules, String clearanceRules) {
        this.minTurnsLow = minTurnsLow;
        this.minTurnsHigh = minTurnsHigh;
        this.rabbitMaxChars = rabbitMaxChars;
        this.setupRules = setupRules;
        this.rabbitRules = rabbitRules;
        this.turtleRules = turtleRules;
        this.suggestionRules = suggestionRules;
        this.clearanceRules = clearanceRules;
    }

    /** "easy" / "normal" / "hard" (case-insensitive); anything else, incl. null → EASY. */
    public static MissionDifficulty from(String value) {
        if (value == null) return EASY;
        return switch (value.trim().toLowerCase(Locale.ROOT)) {
            case "normal" -> NORMAL;
            case "hard" -> HARD;
            default -> EASY;
        };
    }

    /** API value: "easy" | "normal" | "hard". */
    public String apiValue() {
        return name().toLowerCase(Locale.ROOT);
    }

    /** The LLM picks min_turns; the server keeps it inside this level's range (0 / missing → lower bound). */
    public int clampMinTurns(int minTurns) {
        if (minTurns <= 0) return minTurnsLow;
        return Math.max(minTurnsLow, Math.min(minTurnsHigh, minTurns));
    }

    /** Length limit (Korean characters, spaces not counted) told to the rabbit. */
    public int rabbitMaxChars() {
        return rabbitMaxChars;
    }

    /** The server asks the rabbit once more when the reply is clearly over the limit (40% slack). */
    public boolean isRabbitReplyTooLong(String reply) {
        return reply != null && countChars(reply) > rabbitMaxChars * 1.4;
    }

    static int countChars(String s) {
        return s.replaceAll("\\s+", "").length();
    }

    public String setupRules() { return setupRules; }
    public String rabbitRules() { return rabbitRules; }
    public String turtleRules() { return turtleRules; }
    public String suggestionRules() { return suggestionRules; }
    public String clearanceRules() { return clearanceRules; }
}
