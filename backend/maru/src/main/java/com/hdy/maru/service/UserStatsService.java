package com.hdy.maru.service;

import com.hdy.maru.dto.UserStatsResponseDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserStats;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.UserStatsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserStatsService {

    private final UserStatsRepository userStatsRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public UserStatsResponseDto getUserStats(String oauthId) {
        User user = userRepository.findByOauthId(oauthId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + oauthId));

        UserStats stats = userStatsRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    // Return empty stats if none exist
                    UserStats emptyStats = new UserStats();
                    emptyStats.setTotalLessonsCompleted(0);
                    emptyStats.setTotalStudyMinutes(0);
                    emptyStats.setCurrentStreakDays(0);
                    emptyStats.setLongestStreakDays(0);
                    emptyStats.setTotalStarsEarned(0);
                    return emptyStats;
                });

        return UserStatsResponseDto.builder()
                .totalLessonsCompleted(stats.getTotalLessonsCompleted())
                .totalStudyMinutes(stats.getTotalStudyMinutes())
                .currentStreakDays(stats.getCurrentStreakDays())
                .longestStreakDays(stats.getLongestStreakDays())
                .totalStarsEarned(stats.getTotalStarsEarned())
                .lastStudyDate(stats.getLastStudyDate())
                .build();
    }

    /**
     * 레슨(문법) 또는 단어장 학습 시 공통으로 호출되는 스트릭 갱신 메서드.
     * - 오늘 이미 기록됐으면 스킵 (중복 증가 방지)
     * - 어제 학습했으면 streak +1 (연속 학습 유지)
     * - 이틀 이상 공백 → streak 1로 초기화 (하루 빠지면 리셋)
     */
    @Transactional
    public void recordStudyActivity(String oauthId) {
        User user = userRepository.findByOauthId(oauthId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + oauthId));

        UserStats stats = userStatsRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    UserStats newStats = new UserStats();
                    newStats.setUser(user);
                    newStats.setCurrentStreakDays(0);
                    newStats.setLongestStreakDays(0);
                    newStats.setTotalLessonsCompleted(0);
                    newStats.setTotalStudyMinutes(0);
                    newStats.setTotalStarsEarned(0);
                    return newStats;
                });

        java.time.LocalDate today = java.time.LocalDate.now();

        // 오늘 이미 학습 기록이 있으면 스킵 (스트릭 중복 증가 방지)
        if (today.equals(stats.getLastStudyDate())) {
            return;
        }

        if (stats.getLastStudyDate() == null) {
            // 최초 학습
            stats.setCurrentStreakDays(1);
            stats.setLongestStreakDays(1);
        } else if (stats.getLastStudyDate().equals(today.minusDays(1))) {
            // 어제 학습 → 연속 학습 유지
            stats.setCurrentStreakDays(stats.getCurrentStreakDays() + 1);
            if (stats.getCurrentStreakDays() > stats.getLongestStreakDays()) {
                stats.setLongestStreakDays(stats.getCurrentStreakDays());
            }
        } else {
            // 이틀 이상 공백 → 스트릭 초기화
            stats.setCurrentStreakDays(1);
        }

        stats.setLastStudyDate(today);
        userStatsRepository.save(stats);
    }
}
