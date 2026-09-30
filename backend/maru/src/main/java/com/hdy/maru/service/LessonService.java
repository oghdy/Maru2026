package com.hdy.maru.service;

import com.hdy.maru.dto.LessonResponseDto;
import com.hdy.maru.entity.Lesson;
import com.hdy.maru.repository.LessonRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LessonService {

    private final LessonRepository lessonRepository;

    public List<LessonResponseDto> getLessonsByUnitId(Integer unitId) {
        return lessonRepository.findByUnitIdAndIsPublishedTrueOrderByOrderNumAsc(unitId).stream()
                .map(lesson -> new LessonResponseDto(
                        lesson.getLessonId(),
                        lesson.getUnitId(),
                        lesson.getUnitTitle(),
                        lesson.getOrderNum(),
                        lesson.getTitle(),
                        lesson.getDescription(),
                        lesson.getDifficultyLevel(),
                        lesson.getEstimatedMinutes(),
                        lesson.getContent(), // Automatic JSONB serialization!
                        lesson.getIsPublished()))
                .collect(Collectors.toList());
    }
}
