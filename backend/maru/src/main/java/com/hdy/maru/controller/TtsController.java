package com.hdy.maru.controller;

import com.hdy.maru.dto.ApiResponse;
import com.hdy.maru.service.TtsException;
import com.hdy.maru.service.TtsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;

/** GET /api/tts?text=... → audio/mpeg (인증 필요). 오류는 JSON ApiResponse + 4xx/5xx. */
@RestController
@RequestMapping("/api/tts")
@RequiredArgsConstructor
public class TtsController {

    private final TtsService ttsService;

    @GetMapping
    // required=false: 누락도 서비스의 400(JSON, content-type 명시)으로 — 플레이어가 Accept: audio/mpeg 를 보내도 깨지지 않게
    public ResponseEntity<byte[]> speak(@RequestParam(required = false) String text) {
        TtsService.TtsResult result = ttsService.speak(text);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(TtsService.CONTENT_TYPE))
                // 같은 텍스트는 항상 같은 음성 → 기기에서도 오래 캐시해도 됨
                .cacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePrivate())
                .header("X-TTS-Cache", result.cacheHit() ? "HIT" : "MISS")
                .body(result.audio());
    }

    @ExceptionHandler(TtsException.class)
    public ResponseEntity<ApiResponse<Void>> handle(TtsException e) {
        return ResponseEntity.status(e.getStatus())
                .contentType(MediaType.APPLICATION_JSON)
                .body(ApiResponse.error(e.getStatus().value(), e.getMessage()));
    }
}
