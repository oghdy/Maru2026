package com.hdy.maru.controller;

import com.hdy.maru.dto.AiLabExploreRequestDto;
import com.hdy.maru.dto.AiLabExploreResponseDto;
import com.hdy.maru.dto.ApiResponse;
import com.hdy.maru.service.AiLabService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/lab")
@RequiredArgsConstructor
public class AiLabController {

    private final AiLabService aiLabService;

    @PostMapping("/explore")
    public ResponseEntity<ApiResponse<List<AiLabExploreResponseDto>>> exploreGrammar(
            @RequestBody AiLabExploreRequestDto request) {
        List<AiLabExploreResponseDto> result = aiLabService.exploreCategory(request);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @PostMapping("/combine")
    public ResponseEntity<ApiResponse<com.hdy.maru.dto.AiLabCombineResponseDto>> combineGrammar(
            @RequestBody com.hdy.maru.dto.AiLabCombineRequestDto request) {
        com.hdy.maru.dto.AiLabCombineResponseDto result = aiLabService.combineModifiers(request);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // Local handler: GlobalExceptionHandler would turn these into a generic 500
    @ExceptionHandler(AiLabService.AiLabException.class)
    public ResponseEntity<ApiResponse<Void>> handleAiLabException(AiLabService.AiLabException e) {
        log.warn("AI Lab request failed: {} {}", e.getStatus().value(), e.getMessage());
        return ResponseEntity.status(e.getStatus())
                .body(ApiResponse.error(e.getStatus().value(), e.getMessage()));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnreadableBody(HttpMessageNotReadableException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(HttpStatus.BAD_REQUEST.value(), "Invalid request."));
    }
}
