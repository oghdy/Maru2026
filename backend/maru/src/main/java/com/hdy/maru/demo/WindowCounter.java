package com.hdy.maru.demo;

import java.util.function.Supplier;

/** Counter that restarts whenever the window key changes (a new minute, a new day). Thread-safe. */
final class WindowCounter<K> {

    private final Supplier<K> windowKey;
    private K current;
    private int count;

    WindowCounter(Supplier<K> windowKey) {
        this.windowKey = windowKey;
    }

    synchronized boolean tryAcquire(int limit) {
        roll();
        if (count >= limit) {
            return false;
        }
        count++;
        return true;
    }

    /** Gives one back (the call never ran). */
    synchronized void refund() {
        if (count > 0) {
            count--;
        }
    }

    synchronized int count() {
        roll();
        return count;
    }

    private void roll() {
        K now = windowKey.get();
        if (!now.equals(current)) {
            current = now;
            count = 0;
        }
    }
}
