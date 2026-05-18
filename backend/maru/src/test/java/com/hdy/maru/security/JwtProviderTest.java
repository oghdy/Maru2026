package com.hdy.maru.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtProviderTest {

    private JwtProvider jwtProvider;

    @BeforeEach
    void setUp() {
        // Dummy 256-bit safe Base64 string for testing
        String testSecret = "dGhpc2lzYXRlc3RzZWNyZXRrZXl0aGF0bXVzdGJlYXRsZWFzdDI1NmJpdHM=";
        long testExpirationMs = 3600000; // 1 hr
        jwtProvider = new JwtProvider(testSecret, testExpirationMs);
    }

    @Test
    @DisplayName("JWT Generation and Validation Success")
    void generateAndValidateToken() {
        // Given
        String oauthId = "google_12345";

        // When
        String token = jwtProvider.generateToken(oauthId, "ROLE_USER");

        // Then
        assertThat(token).isNotBlank();

        boolean isValid = jwtProvider.validateToken(token);
        assertThat(isValid).isTrue();

        String extractedId = jwtProvider.getOauthIdFromToken(token);
        assertThat(extractedId).isEqualTo(oauthId);
    }

    @Test
    @DisplayName("Invalid JWT token fails validation")
    void invalidTokenValidation() {
        // Given
        String invalidToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature";

        // When
        boolean isValid = jwtProvider.validateToken(invalidToken);

        // Then
        assertThat(isValid).isFalse();
    }
}
