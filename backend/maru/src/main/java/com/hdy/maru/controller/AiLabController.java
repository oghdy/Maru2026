package com.hdy.maru.controller;

import com.hdy.maru.dto.AiLabExploreRequestDto;
import com.hdy.maru.dto.AiLabExploreResponseDto;
import com.hdy.maru.dto.ApiResponse;
import com.hdy.maru.service.AiLabService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

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
}
