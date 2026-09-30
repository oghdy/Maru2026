package com.hdy.maru.repository;

import com.hdy.maru.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.List;

public interface LessonRepository extends JpaRepository<Lesson, Long> {
    Optional<Lesson> findByLessonId(String lessonId);

    boolean existsByLessonId(String lessonId);

    // 공개된 레슨만 (is_published = true). NULL 은 비공개로 취급한다.
    List<Lesson> findByUnitIdAndIsPublishedTrueOrderByOrderNumAsc(Integer unitId);
}
