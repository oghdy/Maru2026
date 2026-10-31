package com.hdy.maru.demo;

import com.hdy.maru.dto.ApiResponse;
import com.hdy.maru.entity.User;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.security.JwtProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Clock;
import java.util.UUID;

/**
 * POST /api/demo/guest: creates a guest user and returns a JWT, same shape as /api/auth/*.
 * The bean only exists while maru.demo.enabled=true; otherwise the path is a normal 404.
 * <p>
 * The rate limit is global on purpose. Exhibition visitors share one Wi-Fi (one public IP), and behind the
 * hosting proxy the client IP comes from a header anyone can set, so a per-IP limit would block real visitors
 * and stop nobody else. What a guest can spend is capped by the AI gate.
 */
@Slf4j
@RestController
@ConditionalOnProperty(name = "maru.demo.enabled", havingValue = "true")
public class GuestTokenController {

    static final String PROVIDER = "guest";
    static final String OAUTH_ID_PREFIX = "guest_";
    static final String NICKNAME = "Guest";
    static final long MAX_TOKEN_TTL_MS = 24 * 60 * 60 * 1000L;

    private final UserRepository userRepository;
    private final JwtProvider jwtProvider;
    private final DemoProperties props;
    private final WindowCounter<Long> issuedThisMinute;

    @Autowired
    public GuestTokenController(UserRepository userRepository, JwtProvider jwtProvider, DemoProperties props) {
        this(userRepository, jwtProvider, props, Clock.systemUTC());
    }

    GuestTokenController(UserRepository userRepository, JwtProvider jwtProvider, DemoProperties props, Clock clock) {
        this.userRepository = userRepository;
        this.jwtProvider = jwtProvider;
        this.props = props;
        this.issuedThisMinute = new WindowCounter<>(() -> clock.millis() / 60_000);
    }

    @PostMapping("/api/demo/guest")
    public ResponseEntity<ApiResponse<String>> issueGuestToken() {
        if (!issuedThisMinute.tryAcquire(props.getGuestIssuePerMinute())) {
            throw DemoAiGate.guestIssueLimit();
        }
        String oauthId = OAUTH_ID_PREFIX + UUID.randomUUID();

        User guest = new User();
        guest.setOauthProvider(PROVIDER);
        guest.setOauthId(oauthId);
        guest.setNickname(NICKNAME);
        userRepository.save(guest);

        long ttlMs = Math.min(props.getGuestTokenTtlMs(), MAX_TOKEN_TTL_MS);
        return ResponseEntity.ok(ApiResponse.success(jwtProvider.generateToken(oauthId, "ROLE_USER", ttlMs)));
    }
}
