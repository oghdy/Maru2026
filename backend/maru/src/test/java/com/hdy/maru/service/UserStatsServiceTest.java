package com.hdy.maru.service;

import com.hdy.maru.dto.UserStatsResponseDto;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.UserStats;
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
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserStatsServiceTest {

    @Mock
    private UserStatsRepository userStatsRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserStatsService userStatsService;

    @Test
    @DisplayName("Should return empty/zero stats if user has never studied")
    void getUserStats_NoStats_ReturnsZeroes() {
        // Given
        String oauthId = "google_newbie";
        User mockUser = new User();
        mockUser.setId(1L);
        mockUser.setOauthId(oauthId);

        when(userRepository.findByOauthId(oauthId)).thenReturn(Optional.of(mockUser));
        when(userStatsRepository.findByUserId(1L)).thenReturn(Optional.empty());

        // When
        UserStatsResponseDto response = userStatsService.getUserStats(oauthId);

        // Then
        assertThat(response.getTotalLessonsCompleted()).isEqualTo(0);
        assertThat(response.getCurrentStreakDays()).isEqualTo(0);
        assertThat(response.getTotalStarsEarned()).isEqualTo(0);
        assertThat(response.getLastStudyDate()).isNull();
    }

    @Test
    @DisplayName("Should return existing stats correctly")
    void getUserStats_ExistingStats_ReturnsCorrectDto() {
        // Given
        String oauthId = "google_veteran";
        User mockUser = new User();
        mockUser.setId(2L);
        mockUser.setOauthId(oauthId);

        UserStats mockStats = new UserStats();
        mockStats.setTotalLessonsCompleted(50);
        mockStats.setTotalStudyMinutes(600);
        mockStats.setCurrentStreakDays(7);
        mockStats.setLongestStreakDays(14);
        mockStats.setTotalStarsEarned(120);
        LocalDate yesterday = LocalDate.now().minusDays(1);
        mockStats.setLastStudyDate(yesterday);

        when(userRepository.findByOauthId(oauthId)).thenReturn(Optional.of(mockUser));
        when(userStatsRepository.findByUserId(2L)).thenReturn(Optional.of(mockStats));

        // When
        UserStatsResponseDto response = userStatsService.getUserStats(oauthId);

        // Then
        assertThat(response.getTotalLessonsCompleted()).isEqualTo(50);
        assertThat(response.getCurrentStreakDays()).isEqualTo(7);
        assertThat(response.getLastStudyDate()).isEqualTo(yesterday);
    }
}
