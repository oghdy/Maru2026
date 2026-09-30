package com.hdy.maru.service;

import com.hdy.maru.dto.UserProgressRequestDto;
import com.hdy.maru.dto.UserProgressResponseDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserProgress;
import com.hdy.maru.entity.UserStats;
import com.hdy.maru.repository.LessonRepository;
import com.hdy.maru.repository.UserProgressRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.UserStatsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.NoSuchElementException;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserProgressService {

    static final String STATUS_COMPLETED = "completed";
    private static final Set<String> ALLOWED_STATUSES = Set.of("in_progress", STATUS_COMPLETED);

    private final UserProgressRepository userProgressRepository;
    private final UserStatsRepository userStatsRepository;
    private final UserRepository userRepository;
    private final UserStatsService userStatsService;
    private final LessonRepository lessonRepository;

    /** 점수(0~100) → 별 개수. 80 이상 3개, 60 이상 2개, 그 외 1개. */
    static int starsForScore(int score) {
        if (score >= 80) return 3;
        if (score >= 60) return 2;
        return 1;
    }

    @Transactional
    public UserProgressResponseDto saveOrUpdateProgress(String oauthId, String lessonId,
            UserProgressRequestDto request) {
        validate(request);
        // 없는 레슨에 진행 기록·통계가 쌓이지 않도록 (GlobalExceptionHandler: NoSuchElementException → 404)
        if (!lessonRepository.existsByLessonId(lessonId)) {
            throw new NoSuchElementException("Lesson not found: " + lessonId);
        }
        User user = userRepository.findByOauthId(oauthId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        UserProgress progress = userProgressRepository.findByUserIdAndLessonId(user.getId(), lessonId)
                .orElseGet(() -> {
                    UserProgress newProgress = new UserProgress();
                    newProgress.setUser(user);
                    newProgress.setLessonId(lessonId);
                    newProgress.setAttempts(0);
                    return newProgress;
                });

        boolean wasCompleted = STATUS_COMPLETED.equals(progress.getStatus());
        boolean completesNow = STATUS_COMPLETED.equals(request.getStatus());

        // 한 번 완료한 레슨은 다시 풀다가 in_progress 를 보내도 completed 로 유지한다 (완료 수 중복 집계 방지)
        if (request.getStatus() != null && !wasCompleted) {
            progress.setStatus(request.getStatus());
        }
        if (request.getCurrentStep() != null) {
            progress.setCurrentStep(request.getCurrentStep());
        }

        // 학습 시간은 요청마다 누적 (완료 여부와 무관)
        int addedSeconds = request.getTimeSpentSeconds() != null ? Math.max(0, request.getTimeSpentSeconds()) : 0;
        int prevSeconds = progress.getTimeSpentSeconds() != null ? progress.getTimeSpentSeconds() : 0;
        progress.setTimeSpentSeconds(prevSeconds + addedSeconds);

        // 점수·별은 "최고 기록" 기준. 완료 요청일 때만 별을 매긴다.
        int starsGained = 0;
        if (completesNow) {
            int score = request.getScore() != null ? request.getScore() : 0;
            int prevBest = progress.getScore() != null ? progress.getScore() : 0;
            int prevStars = progress.getStarsEarned() != null ? progress.getStarsEarned() : 0;
            int newStars = starsForScore(score);

            progress.setScore(wasCompleted ? Math.max(prevBest, score) : score);
            if (newStars > prevStars) {
                progress.setStarsEarned(newStars);
                starsGained = newStars - prevStars;
            }
            if (!wasCompleted) {
                progress.setCompletedAt(LocalDateTime.now());
            }
        } else if (request.getScore() != null && !wasCompleted) {
            progress.setScore(request.getScore());
        }

        progress.setAttempts(progress.getAttempts() + 1);
        UserProgress saved = userProgressRepository.save(progress);

        boolean newlyCompleted = completesNow && !wasCompleted;
        if (newlyCompleted || starsGained > 0 || addedSeconds > 0) {
            updateUserStats(user, newlyCompleted, starsGained);
        }
        if (completesNow) {
            // 스트릭 갱신은 공통 메서드에 위임 (레슨 완료 = 학습 활동)
            userStatsService.recordStudyActivity(user.getOauthId());
        }

        return UserProgressResponseDto.builder()
                .lessonId(saved.getLessonId())
                .status(saved.getStatus())
                .currentStep(saved.getCurrentStep())
                .score(saved.getScore())
                .starsEarned(saved.getStarsEarned())
                .attempts(saved.getAttempts())
                .timeSpentSeconds(saved.getTimeSpentSeconds())
                .build();
    }

    // GlobalExceptionHandler: IllegalArgumentException → 400
    private static void validate(UserProgressRequestDto request) {
        if (request.getStatus() != null && !ALLOWED_STATUSES.contains(request.getStatus())) {
            throw new IllegalArgumentException("status must be 'in_progress' or 'completed'");
        }
        if (request.getScore() != null && (request.getScore() < 0 || request.getScore() > 100)) {
            throw new IllegalArgumentException("score must be between 0 and 100");
        }
    }

    private void updateUserStats(User user, boolean newlyCompleted, int starsGained) {
        UserStats stats = userStatsRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    UserStats newStats = new UserStats();
                    newStats.setUser(user);
                    newStats.setTotalLessonsCompleted(0);
                    newStats.setTotalStudyMinutes(0);
                    newStats.setTotalStarsEarned(0);
                    return newStats;
                });

        if (newlyCompleted) {
            stats.setTotalLessonsCompleted(nz(stats.getTotalLessonsCompleted()) + 1);
        }
        stats.setTotalStarsEarned(nz(stats.getTotalStarsEarned()) + starsGained);
        // 분 = 전체 레슨 누적 초 / 60 (요청마다 버림하지 않고 합계에서 한 번만 버림)
        long totalSeconds = userProgressRepository.sumTimeSpentSecondsByUserId(user.getId());
        stats.setTotalStudyMinutes((int) (totalSeconds / 60));
        userStatsRepository.save(stats);
    }

    private static int nz(Integer v) {
        return v != null ? v : 0;
    }
}
