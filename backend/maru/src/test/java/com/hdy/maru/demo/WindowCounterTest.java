package com.hdy.maru.demo;

import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;

class WindowCounterTest {

    @Test
    void countsUntilLimit_thenRestartsInNextWindow() {
        AtomicLong minute = new AtomicLong(1);
        WindowCounter<Long> counter = new WindowCounter<>(minute::get);

        assertThat(counter.tryAcquire(2)).isTrue();
        assertThat(counter.tryAcquire(2)).isTrue();
        assertThat(counter.tryAcquire(2)).isFalse();

        counter.refund();
        assertThat(counter.tryAcquire(2)).isTrue();

        minute.incrementAndGet();
        assertThat(counter.count()).isZero();
        assertThat(counter.tryAcquire(2)).isTrue();
    }

    @Test
    void refundNeverGoesNegative() {
        WindowCounter<Long> counter = new WindowCounter<>(() -> 1L);
        counter.refund();
        assertThat(counter.count()).isZero();
    }
}
