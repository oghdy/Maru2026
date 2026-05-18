package com.hdy.maru.controller;

import com.hdy.maru.dto.UserStatsResponseDto;
import com.hdy.maru.dto.ApiResponse;
import com.hdy.maru.service.UserStatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/me/stats")
@RequiredArgsConstructor
public class UserStatsController {

    private final UserStatsService userStatsService;

    @GetMapping
    public ResponseEntity<ApiResponse<UserStatsResponseDto>> getMyStats(
            @AuthenticationPrincipal String oauthId) {

        UserStatsResponseDto response = userStatsService.getUserStats(oauthId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
