package com.hdy.maru.security.apple;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class ApplePublicKeyResponse {
    private List<ApplePublicKey> keys;

    public ApplePublicKey getMatchedKeyBy(String kid, String alg) {
        return keys.stream()
                .filter(key -> key.getKid().equals(kid) && key.getAlg().equals(alg))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("지원하지 않는 Apple JWT 이거나 잘못된 토큰입니다."));
    }
}
