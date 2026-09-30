package com.hdy.maru.controller;

import com.hdy.maru.dto.LessonResponseDto;
import com.hdy.maru.service.LessonService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.hdy.maru.dto.ApiResponse;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class LessonController {

    private final LessonService lessonService;

    @GetMapping("/units/{unitId}/lessons")
    public ResponseEntity<ApiResponse<List<LessonResponseDto>>> getLessonsByUnitId(@PathVariable Integer unitId) {
        List<LessonResponseDto> lessons = lessonService.getLessonsByUnitId(unitId);
        return ResponseEntity.ok(ApiResponse.success(lessons));
    }
}
