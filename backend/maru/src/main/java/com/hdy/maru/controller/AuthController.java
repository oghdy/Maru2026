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

    @PostMapping("/google")
    public ApiResponse<String> googleLogin(@Valid @RequestBody AuthRequestDto requestDto) {
        try {
            String token = requestDto.getIdToken();
            String email;
            String oauthId;
            String name;
            String pictureUrl;

            if (token != null && token.startsWith("ya29.")) {
                // It's an Access Token (Flutter Web fallback)
                org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
                org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
                headers.setBearerAuth(token);
                org.springframework.http.HttpEntity<String> entity = new org.springframework.http.HttpEntity<>("",
                        headers);

                org.springframework.http.ResponseEntity<java.util.Map> response = restTemplate.exchange(
                        "https://www.googleapis.com/oauth2/v3/userinfo",
                        org.springframework.http.HttpMethod.GET,
                        entity,
                        java.util.Map.class);

                java.util.Map<String, Object> payload = response.getBody();
                if (payload == null || !payload.containsKey("email")) {
                    return ApiResponse.error(401, "Invalid Google Access Token");
                }
                email = (String) payload.get("email");
                oauthId = "google_" + payload.get("sub");
                name = (String) payload.get("name");
                pictureUrl = (String) payload.get("picture");
            } else {
                // It's an ID Token (Flutter Mobile / Normal flow)
                GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(),
                        new GsonFactory())
                        .setAudience(Collections.singletonList(googleClientId))
                        .build();

                GoogleIdToken idToken = verifier.verify(token);
                if (idToken == null) {
                    return ApiResponse.error(401, "Invalid Google ID Token");
                }

                GoogleIdToken.Payload payload = idToken.getPayload();
                email = payload.getEmail();
                oauthId = "google_" + payload.getSubject();
                name = (String) payload.get("name");
                pictureUrl = (String) payload.get("picture");
            }

            log.info("Google login successful for user: {}", email);

            // Create or update user in database
            User user = userRepository.findByOauthProviderAndOauthId("google", oauthId)
                    .orElseGet(() -> {
                        User newUser = new User();
                        newUser.setOauthProvider("google");
                        newUser.setOauthId(oauthId);
                        newUser.setEmail(email);
                        newUser.setNickname(name);
                        newUser.setProfileImageUrl(pictureUrl);
                        return newUser;
                    });
            userRepository.save(user);

            // Generate Maru JWT
            String maruJwt = jwtProvider.generateToken(oauthId, "ROLE_USER");

            return ApiResponse.success(maruJwt);

        } catch (Exception e) {
            log.error("Failed to verify Google ID token", e);
            return ApiResponse.error(500, "Google Authentication Failed: " + e.getMessage());
        }
    }

    @PostMapping("/apple")
    public ApiResponse<String> appleLogin(@Valid @RequestBody AuthRequestDto requestDto) {
        try {
            String idToken = requestDto.getIdToken();
            if (idToken == null || idToken.isEmpty()) {
                return ApiResponse.error(400, "Apple ID Token is missing");
            }

            // Verify the Apple ID token
            Claims claims = appleAuthService.verifyIdentityToken(idToken);

            String email = claims.get("email", String.class);
            String sub = claims.getSubject();
            String oauthId = "apple_" + sub;

            log.info("Apple login successful for user: {}", email);

            // Create or update user
            User user = userRepository.findByOauthProviderAndOauthId("apple", oauthId)
                    .orElseGet(() -> {
                        User newUser = new User();
                        newUser.setOauthProvider("apple");
                        newUser.setOauthId(oauthId);
                        newUser.setEmail(email);
                        // Make up a default nickname if not provided by Apple
                        newUser.setNickname("Apple User");
                        return newUser;
                    });
            userRepository.save(user);

            // Generate Maru JWT
            String maruJwt = jwtProvider.generateToken(oauthId, "ROLE_USER");

            return ApiResponse.success(maruJwt);

        } catch (Exception e) {
            log.error("Failed to verify Apple ID token", e);
            return ApiResponse.error(401, "Apple Authentication Failed: " + e.getMessage());
        }
    }
}
