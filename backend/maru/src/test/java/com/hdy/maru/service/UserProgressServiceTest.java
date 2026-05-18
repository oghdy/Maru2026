package com.hdy.maru.service;

import com.hdy.maru.dto.UserProgressRequestDto;
import com.hdy.maru.dto.UserProgressResponseDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserProgress;
import com.hdy.maru.entity.UserStats;
import com.hdy.maru.repository.UserProgressRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.UserStatsRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserProgressServiceTest {

    @Mock
    private UserProgressRepository userProgressRepository;

    @Mock
    private UserStatsRepository userStatsRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserProgressService userProgressService;

    @Test
    @DisplayName("When progress doesn't exist, it should INSERT new progress")
    void saveOrUpdateProgress_Insert() {
        // Given
        String oauthId = "google_123";
        String lessonId = "unit1_lesson1";
        UserProgressRequestDto request = new UserProgressRequestDto("in_progress", 5, 0, 120);

        User mockUser = new User();
        mockUser.setId(1L);
        mockUser.setOauthId(oauthId);

        when(userRepository.findByOauthId(oauthId)).thenReturn(Optional.of(mockUser));
        when(userProgressRepository.findByUserIdAndLessonId(1L, lessonId)).thenReturn(Optional.empty());

        UserProgress savedProgress = new UserProgress();
        savedProgress.setUser(mockUser);
        savedProgress.setLessonId(lessonId);
        savedProgress.setStatus("in_progress");
        savedProgress.setCurrentStep(5);
        savedProgress.setTimeSpentSeconds(120);
        savedProgress.setAttempts(0); // newly created means attempt starts logically at save time or controller time
        // but let's assume service increments it on first touch or handles it
        when(userProgressRepository.save(any(UserProgress.class))).thenReturn(savedProgress);

        // When
        UserProgressResponseDto response = userProgressService.saveOrUpdateProgress(oauthId, lessonId, request);

        // Then
        assertThat(response.getStatus()).isEqualTo("in_progress");
        assertThat(response.getCurrentStep()).isEqualTo(5);
        verify(userProgressRepository, times(1)).save(any(UserProgress.class));
        verify(userStatsRepository, never()).save(any(UserStats.class)); // Not completed, so no stats update
    }

    @Test
    @DisplayName("When status is 'completed', it should update UserStats")
    void saveOrUpdateProgress_Completed_UpdatesStats() {
        // Given
        String oauthId = "google_123";
        String lessonId = "unit1_lesson1";
        UserProgressRequestDto request = new UserProgressRequestDto("completed", 10, 100, 300);

        User mockUser = new User();
        mockUser.setId(1L);
        mockUser.setOauthId(oauthId);

        UserProgress existingProgress = new UserProgress();
        existingProgress.setUser(mockUser);
        existingProgress.setLessonId(lessonId);
        existingProgress.setStatus("in_progress");
        existingProgress.setAttempts(1);
        existingProgress.setTimeSpentSeconds(0);

        UserStats mockStats = new UserStats();
        mockStats.setUser(mockUser);
        mockStats.setTotalLessonsCompleted(0);
        mockStats.setTotalStudyMinutes(0);
        mockStats.setLastStudyDate(LocalDate.now().minusDays(1)); // Yesterday
        mockStats.setCurrentStreakDays(2);

        when(userRepository.findByOauthId(oauthId)).thenReturn(Optional.of(mockUser));
        when(userProgressRepository.findByUserIdAndLessonId(1L, lessonId)).thenReturn(Optional.of(existingProgress));
        when(userStatsRepository.findByUserId(1L)).thenReturn(Optional.of(mockStats));

        UserProgress savedProgress = new UserProgress();
        savedProgress.setStatus("completed");
        savedProgress.setLessonId(lessonId);
        when(userProgressRepository.save(any(UserProgress.class))).thenReturn(savedProgress);
        // Do not strict stub userStatsRepository.save, lenient is better if not
        // strictly returning
        lenient().when(userStatsRepository.save(any(UserStats.class))).thenReturn(mockStats);

        // When
        userProgressService.saveOrUpdateProgress(oauthId, lessonId, request);

        // Then
        // Verified stats are updated
        verify(userStatsRepository, times(1)).save(any(UserStats.class));
        assertThat(mockStats.getTotalLessonsCompleted()).isEqualTo(1);
        // 300 seconds = 5 minutes
        assertThat(mockStats.getTotalStudyMinutes()).isEqualTo(5);
        // Played yesterday and today, streak should go up to 3!
        assertThat(mockStats.getCurrentStreakDays()).isEqualTo(3);
    }
}
