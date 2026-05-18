package com.hdy.maru.repository;

import com.hdy.maru.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.List;

public interface LessonRepository extends JpaRepository<Lesson, Long> {
    Optional<Lesson> findByLessonId(String lessonId);

    // Custom finder to support the new API
    List<Lesson> findByUnitIdOrderByOrderNumAsc(Integer unitId);
}
