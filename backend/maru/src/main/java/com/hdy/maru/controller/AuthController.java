package com.hdy.maru.controller;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.hdy.maru.dto.ApiResponse;
import com.hdy.maru.dto.AuthRequestDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.security.JwtProvider;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;

import com.hdy.maru.security.apple.AppleAuthService;
import io.jsonwebtoken.Claims;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final JwtProvider jwtProvider;
    private final AppleAuthService appleAuthService;

    @Value("${spring.security.oauth2.client.registration.google.client-id:}")
    private String googleClientId;

    /** 검증된 소셜 계정 정보 (검증 실패 시 null). */
    private record VerifiedAccount(String oauthId, String email, String name, String pictureUrl) {
    }

    @PostMapping("/google")
    public ResponseEntity<ApiResponse<String>> googleLogin(@Valid @RequestBody AuthRequestDto requestDto) {
        String token = requestDto.getIdToken();
        if (token == null || token.isBlank()) {
            return error(HttpStatus.BAD_REQUEST, "Google sign-in token is missing.");
        }
        VerifiedAccount account;
        try {
            account = verifyGoogle(token);
        } catch (Exception e) {
            log.warn("Google token verification error: {}", e.getClass().getSimpleName());
            account = null;
        }
        if (account == null) {
            return error(HttpStatus.UNAUTHORIZED, "Google sign-in failed. Please try again.");
        }
        return issueToken("google", account, account.name());
    }

    private VerifiedAccount verifyGoogle(String token) throws Exception {
        if (token.startsWith("ya29.")) {
            // Access Token (Flutter Web fallback)
            org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.setBearerAuth(token);
            org.springframework.http.ResponseEntity<java.util.Map> response = restTemplate.exchange(
                    "https://www.googleapis.com/oauth2/v3/userinfo",
                    org.springframework.http.HttpMethod.GET,
                    new org.springframework.http.HttpEntity<>("", headers),
                    java.util.Map.class);
            java.util.Map<String, Object> payload = response.getBody();
            if (payload == null || !payload.containsKey("email")) {
                return null;
            }
            return new VerifiedAccount("google_" + payload.get("sub"), (String) payload.get("email"),
                    (String) payload.get("name"), (String) payload.get("picture"));
        }
        // ID Token (Flutter Mobile / Normal flow)
        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                .setAudience(Collections.singletonList(googleClientId))
                .build();
        GoogleIdToken idToken = verifier.verify(token);
        if (idToken == null) {
            return null;
        }
        GoogleIdToken.Payload payload = idToken.getPayload();
        return new VerifiedAccount("google_" + payload.getSubject(), payload.getEmail(),
                (String) payload.get("name"), (String) payload.get("picture"));
    }

    @PostMapping("/apple")
    public ResponseEntity<ApiResponse<String>> appleLogin(@Valid @RequestBody AuthRequestDto requestDto) {
        String idToken = requestDto.getIdToken();
        if (idToken == null || idToken.isBlank()) {
            return error(HttpStatus.BAD_REQUEST, "Apple sign-in token is missing.");
        }
        VerifiedAccount account;
        try {
            Claims claims = appleAuthService.verifyIdentityToken(idToken);
            account = new VerifiedAccount("apple_" + claims.getSubject(), claims.get("email", String.class), null, null);
        } catch (Exception e) {
            log.warn("Apple token verification error: {}", e.getClass().getSimpleName());
            return error(HttpStatus.UNAUTHORIZED, "Apple sign-in failed. Please try again.");
        }
        // Apple 은 이름을 주지 않으므로 기본 닉네임
        return issueToken("apple", account, "Apple User");
    }

    /** 사용자 생성/조회 후 Maru JWT 발급. DB 오류는 500. */
    private ResponseEntity<ApiResponse<String>> issueToken(String provider, VerifiedAccount account, String defaultNickname) {
        try {
            User user = userRepository.findByOauthProviderAndOauthId(provider, account.oauthId())
                    .orElseGet(() -> {
                        User newUser = new User();
                        newUser.setOauthProvider(provider);
                        newUser.setOauthId(account.oauthId());
                        newUser.setEmail(account.email());
                        newUser.setNickname(defaultNickname);
                        newUser.setProfileImageUrl(account.pictureUrl());
                        return newUser;
                    });
            userRepository.save(user);
            log.info("{} login successful", provider); // 이메일 등 개인정보는 로그에 남기지 않음
            return ResponseEntity.ok(ApiResponse.success(jwtProvider.generateToken(account.oauthId(), "ROLE_USER")));
        } catch (Exception e) {
            log.error("Failed to complete {} login", provider, e);
            return error(HttpStatus.INTERNAL_SERVER_ERROR, "Sign-in failed on the server. Please try again later.");
        }
    }

    private static ResponseEntity<ApiResponse<String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(ApiResponse.error(status.value(), message));
    }
}
