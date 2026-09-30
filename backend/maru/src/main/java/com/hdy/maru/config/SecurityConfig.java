package com.hdy.maru.config;

import com.hdy.maru.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

        private final JwtAuthenticationFilter jwtAuthenticationFilter;

        @Bean
        public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
                http
                                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                                .csrf(AbstractHttpConfigurer::disable)
                                .sessionManagement(session -> session.sessionCreationPolicy(
                                                org.springframework.security.config.http.SessionCreationPolicy.STATELESS))
                                .authorizeHttpRequests(authz -> authz
                                                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll() // Allow
                                                                                                        // preflight
                                                .requestMatchers("/api/auth/**").permitAll()
                                                .requestMatchers("/api/units/**", "/api/lessons/**").permitAll() // Allow
                                                                                                                 // unauthenticated
                                                                                                                 // access
                                                                                                                 // to
                                                                                                                 // lessons
                                                .requestMatchers("/h2-console/**").permitAll()
                                                .anyRequest().authenticated())
                                // JWT 인증 필터를 UsernamePasswordAuthenticationFilter(기본 폼로그인)보다 먼저 실행되게 끼워넣습니다.
                                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

                return http.build();
        }

        @Bean
        public CorsConfigurationSource corsConfigurationSource() {
                CorsConfiguration configuration = new CorsConfiguration();
                // Allow specific origins (Emulator and Local Web)
                configuration.setAllowedOrigins(Arrays.asList("http://localhost:8080", "http://localhost:3000",
                                "http://localhost:5000", "http://10.0.2.2:8080"));
                // Allow specific HTTP methods
                configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
                // Allow specific headers
                configuration.setAllowedHeaders(Arrays.asList("Authorization", "Cache-Control", "Content-Type"));
                configuration.setAllowCredentials(true);

                UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
                source.registerCorsConfiguration("/**", configuration);
                return source;
        }
}
