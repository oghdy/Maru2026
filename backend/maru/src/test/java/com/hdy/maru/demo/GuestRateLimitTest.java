package com.hdy.maru.demo;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.security.JwtProvider;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class GuestRateLimitTest {

    @Test
    @DisplayName("Global issue limit: 429 inside the minute without creating a user, open again next minute")
    void limitPerMinute() {
        UserRepository users = Mockito.mock(UserRepository.class);
        JwtProvider jwt = Mockito.mock(JwtProvider.class);
        when(jwt.generateToken(anyString(), anyString(), anyLong())).thenReturn("jwt");
        DemoProperties props = new DemoProperties();
        props.setEnabled(true);
        props.setGuestIssuePerMinute(2);
        Instant[] now = {Instant.parse("2026-11-06T01:00:00Z")};
        Clock clock = new Clock() {
            @Override
            public java.time.ZoneId getZone() {
                return ZoneOffset.UTC;
            }

            @Override
            public Clock withZone(java.time.ZoneId zone) {
                return this;
            }

            @Override
            public Instant instant() {
                return now[0];
            }
        };
        GuestTokenController controller = new GuestTokenController(users, jwt, props, clock);

        controller.issueGuestToken();
        controller.issueGuestToken();
        assertThatThrownBy(controller::issueGuestToken).isInstanceOf(DemoLimitException.class)
                .hasMessageContaining("Lots of visitors");
        verify(users, times(2)).save(any());

        now[0] = now[0].plus(Duration.ofMinutes(1));
        assertThat(controller.issueGuestToken().getStatusCode().value()).isEqualTo(200);
    }

    @Test
    @DisplayName("A longer lifetime setting is capped at 24 hours")
    void ttlCapped() {
        UserRepository users = Mockito.mock(UserRepository.class);
        JwtProvider jwt = Mockito.mock(JwtProvider.class);
        DemoProperties props = new DemoProperties();
        props.setEnabled(true);
        props.setGuestTokenTtlMs(7L * 24 * 60 * 60 * 1000);
        when(jwt.generateToken(anyString(), anyString(), anyLong())).thenReturn("jwt");

        new GuestTokenController(users, jwt, props).issueGuestToken();

        verify(jwt).generateToken(anyString(), anyString(), org.mockito.ArgumentMatchers.eq(24L * 60 * 60 * 1000));
        verify(jwt, never()).generateToken(anyString(), anyString());
    }
}
