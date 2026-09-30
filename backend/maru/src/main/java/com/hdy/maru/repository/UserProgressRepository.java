package com.hdy.maru.repository;

import com.hdy.maru.entity.UserProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface UserProgressRepository extends JpaRepository<UserProgress, Long> {
    Optional<UserProgress> findByUserIdAndLessonId(Long userId, String lessonId);

    List<UserProgress> findByUserId(Long userId);

    List<UserProgress> findByUserIdAndLessonIdIn(Long userId, Collection<String> lessonIds);

    // 사용자의 전체 레슨 학습 시간(초). 분 단위 통계를 매번 여기서 다시 계산해 반올림 손실을 없앤다.
    @Query("SELECT COALESCE(SUM(p.timeSpentSeconds), 0) FROM UserProgress p WHERE p.user.id = :userId")
    long sumTimeSpentSecondsByUserId(@Param("userId") Long userId);
}
