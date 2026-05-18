package com.hdy.maru.service;

import com.hdy.maru.dto.UserProgressRequestDto;
import com.hdy.maru.dto.UserProgressResponseDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserProgress;
import com.hdy.maru.entity.UserStats;
import com.hdy.maru.repository.UserProgressRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.UserStatsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserProgressService {

    private final UserProgressRepository userProgressRepository;
    private final UserStatsRepository userStatsRepository;
    private final UserRepository userRepository;
    private final UserStatsService userStatsService;

    @Transactional
    public UserProgressResponseDto saveOrUpdateProgress(String oauthId, String lessonId,
            UserProgressRequestDto request) {
        User user = userRepository.findByOauthId(oauthId)
                .orElseThrow(() -> new IllegalArgumentException("User not found with oauthId: " + oauthId));

        UserProgress progress = userProgressRepository.findByUserIdAndLessonId(user.getId(), lessonId)
                .orElseGet(() -> {
                    UserProgress newProgress = new UserProgress();
                    newProgress.setUser(user);
                    newProgress.setLessonId(lessonId);
                    newProgress.setAttempts(0);
                    return newProgress;
                });

        boolean isNewlyCompleted = "completed".equals(request.getStatus()) && !"completed".equals(progress.getStatus());

        // Update basic progress info
        progress.setStatus(request.getStatus() != null ? request.getStatus() : "not_started");
        if (request.getCurrentStep() != null)
            progress.setCurrentStep(request.getCurrentStep());
        if (request.getScore() != null)
            progress.setScore(request.getScore());

        // Increment time spent
        if (request.getTimeSpentSeconds() != null) {
            progress.setTimeSpentSeconds((progress.getTimeSpentSeconds() != null ? progress.getTimeSpentSeconds() : 0)
                    + request.getTimeSpentSeconds());
        }

        // Logic for completion
        if (isNewlyCompleted) {
            log.info("Entering completed logic branch!");
            // It's newly completed!
            progress.setCompletedAt(LocalDateTime.now());
            // Calculate stars (example logic: >80 score = 3 stars, >50 = 2 stars, else 1)
            int score = request.getScore() != null ? request.getScore() : 0;
            int stars = score >= 80 ? 3 : (score >= 50 ? 2 : 1);
            progress.setStarsEarned(stars);

            // Important: Update global User Stats (passing total accumulated time for this
            // lesson)
            updateUserStats(user, progress.getTimeSpentSeconds() != null ? progress.getTimeSpentSeconds() : 0, stars);
        }

        progress.setAttempts(progress.getAttempts() + 1);

        UserProgress saved = userProgressRepository.save(progress);

        return UserProgressResponseDto.builder()
                .lessonId(saved.getLessonId())
                .status(saved.getStatus())
                .currentStep(saved.getCurrentStep())
                .score(saved.getScore())
                .starsEarned(saved.getStarsEarned())
                .attempts(saved.getAttempts())
                .build();
    }

    private void updateUserStats(User user, int newTimeSpentSeconds, int newStars) {
        UserStats stats = userStatsRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    UserStats newStats = new UserStats();
                    newStats.setUser(user);
                    return newStats;
                });

        stats.setTotalLessonsCompleted(stats.getTotalLessonsCompleted() + 1);
        stats.setTotalStudyMinutes(stats.getTotalStudyMinutes() + (newTimeSpentSeconds / 60));
        stats.setTotalStarsEarned(stats.getTotalStarsEarned() + newStars);
        userStatsRepository.save(stats);

        // 스트릭 갱신은 공통 메서드에 위임
        userStatsService.recordStudyActivity(user.getOauthId());
    }
}
