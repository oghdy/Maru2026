package com.hdy.maru.domain.fsrs;

public enum FsrsState {
    NEW(0),
    LEARNING(1),
    REVIEW(2),
    RELEARNING(3);

    private final int value;

    FsrsState(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }
}
