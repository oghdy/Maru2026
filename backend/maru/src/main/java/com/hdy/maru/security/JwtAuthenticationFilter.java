package com.hdy.maru.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtProvider jwtProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        try {
            // 1. Request Header에서 JWT 토큰을 꺼냅니다.
            // 토큰 원문·사용자 ID 는 로그에 남기지 않는다 (PM-1.P.5)
            String jwt = getJwtFromRequest(request);

            // 2. 토큰이 비어있지 않고, JwtProvider의 위변조 검증을 통과했다면
            if (StringUtils.hasText(jwt)) {
                if (jwtProvider.validateToken(jwt)) {
                    // 3. 토큰에서 사용자 고유 ID (oauthId) 를 추출합니다.
                    String oauthId = jwtProvider.getOauthIdFromToken(jwt);

                    // 4. Spring Security의 핵심인 'SecurityContext'에 이 인증된 유저의 정보를 올려놓습니다! (이후 컨트롤러에서
                    // 꺼내 쓸 수 있음)
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            oauthId, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                } else {
                    log.debug("JWT validation failed for {}", request.getRequestURI());
                }
            }
        } catch (Exception ex) {
            log.warn("JWT 인증 필터 오류: {}", ex.getClass().getSimpleName());
        }

        // 5. 앞의 작업이 끝나면 다음 필터(또는 컨트롤러)로 요청을 넘깁니다.
        filterChain.doFilter(request, response);
    }

    // 헤더에서 "Bearer [토큰]" 형태를 분리해서 순수 토큰 내용물만 가져오는 메서드
    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
