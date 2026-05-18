package com.hdy.maru.security.apple;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.RSAPublicKeySpec;
import java.util.Base64;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AppleAuthService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private static final String APPLE_PUBLIC_KEYS_URL = "https://appleid.apple.com/auth/keys";

    public Claims verifyIdentityToken(String identityToken) {
        try {
            // 1. 헤더에서 kid, alg 추출
            String headerOfIdentityToken = identityToken.substring(0, identityToken.indexOf("."));
            Map<String, String> header = objectMapper.readValue(
                    new String(Base64.getUrlDecoder().decode(headerOfIdentityToken)),
                    new TypeReference<Map<String, String>>() {
                    });
            String kid = header.get("kid");
            String alg = header.get("alg");

            // 2. Apple 공개키 목록 가져오기
            ApplePublicKeyResponse response = restTemplate.getForObject(APPLE_PUBLIC_KEYS_URL,
                    ApplePublicKeyResponse.class);
            if (response == null) {
                throw new IllegalStateException("Apple 공개키를 가져올 수 없습니다.");
            }

            // 3. kid와 alg가 일치하는 응답키 가져오기
            ApplePublicKey applePublicKey = response.getMatchedKeyBy(kid, alg);

            // 4. 추출한 키로 PublicKey 생성
            PublicKey publicKey = getPublicKey(applePublicKey);

            // 5. PublicKey로 JWT 검증 및 body(Claims) 부분 반환
            return Jwts.parser()
                    .verifyWith(publicKey)
                    .build()
                    .parseSignedClaims(identityToken)
                    .getPayload();

        } catch (JsonProcessingException e) {
            log.error("Failed to parse token header: {}", e.getMessage());
            throw new IllegalArgumentException("유효하지 않은 Apple Identity Token 입니다.");
        } catch (Exception e) {
            log.error("Apple JWT validation failed: {}", e.getMessage());
            throw new IllegalArgumentException("Apple 토큰 검증에 실패했습니다. " + e.getMessage());
        }
    }

    private PublicKey getPublicKey(ApplePublicKey key) throws NoSuchAlgorithmException, InvalidKeySpecException {
        byte[] nBytes = java.util.Base64.getUrlDecoder().decode(key.getN());
        byte[] eBytes = java.util.Base64.getUrlDecoder().decode(key.getE());

        BigInteger n = new BigInteger(1, nBytes);
        BigInteger e = new BigInteger(1, eBytes);

        RSAPublicKeySpec publicKeySpec = new RSAPublicKeySpec(n, e);
        KeyFactory keyFactory = KeyFactory.getInstance(key.getKty());
        return keyFactory.generatePublic(publicKeySpec);
    }
}
