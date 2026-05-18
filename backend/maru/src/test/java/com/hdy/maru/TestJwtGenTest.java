package com.hdy.maru;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.io.Decoders;
import org.junit.jupiter.api.Test;
import java.util.Date;

public class TestJwtGenTest {
    @Test
    public void printToken() {
        String secretKey = "bWFydS1zZWNyZXQta2V5LWN1c3RvbS1rZXktZm9yLWxvY2FsLWRldmVsb3BtZW50LW9ubHk=";
        long tokenValidTime = 24 * 60 * 60 * 1000L;
        Date now = new Date();

        java.security.Key key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(secretKey));

        String token = Jwts.builder()
                .setSubject("test_user_stats")
                .claim("role", "ROLE_USER")
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + tokenValidTime))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();

        System.out.println("FRESH_TOKEN=" + token);
    }
}
