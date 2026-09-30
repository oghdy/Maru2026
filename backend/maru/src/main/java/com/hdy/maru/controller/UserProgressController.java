package com.hdy.maru.controller;

import com.hdy.maru.dto.UserProgressRequestDto;
import com.hdy.maru.dto.UserProgressResponseDto;
import com.hdy.maru.dto.ApiResponse;
import com.hdy.maru.service.UserProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.List;

@RestController
@RequestMapping("/api/progress")
@RequiredArgsConstructor
public class UserProgressController {

    private final UserProgressService userProgressService;

    // 레슨 목록 완료 표시·이어하기용. 예: GET /api/progress/lessons?unitId=1
    @GetMapping("/lessons")
    public ResponseEntity<ApiResponse<List<UserProgressResponseDto>>> getProgress(
            @RequestParam(required = false) Integer unitId,
            @AuthenticationPrincipal String oauthId) {
        return ResponseEntity.ok(ApiResponse.success(userProgressService.getProgress(oauthId, unitId)));
    }

    @PostMapping("/lessons/{lessonId}")
    public ResponseEntity<ApiResponse<UserProgressResponseDto>> updateProgress(
            @PathVariable String lessonId,
            @RequestBody UserProgressRequestDto request,
            @AuthenticationPrincipal String oauthId) {

        UserProgressResponseDto response = userProgressService.saveOrUpdateProgress(oauthId, lessonId, request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // ?unitId=abc 처럼 숫자가 아닐 때 500 대신 400
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<Void>> handleTypeMismatch(MethodArgumentTypeMismatchException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(HttpStatus.BAD_REQUEST.value(), e.getName() + " must be a number"));
    }
}
