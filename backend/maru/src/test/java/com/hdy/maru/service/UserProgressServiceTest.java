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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.NoSuchElementException;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UserProgressServiceTest {

    private static final String OAUTH_ID = "google_123";
    private static final String LESSON_ID = "u1-l1";

    @Mock
    private UserProgressRepository userProgressRepository;

    @Mock
    private UserStatsRepository userStatsRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserStatsService userStatsService;

    @Mock
    private LessonRepository lessonRepository;

    @InjectMocks
    private UserProgressService userProgressService;

    private User user;
    private UserStats stats;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        user.setOauthId(OAUTH_ID);

        stats = new UserStats();
        stats.setUser(user);
        stats.setTotalLessonsCompleted(0);
        stats.setTotalStudyMinutes(0);
        stats.setTotalStarsEarned(0);

        when(userRepository.findByOauthId(OAUTH_ID)).thenReturn(Optional.of(user));
        when(lessonRepository.existsByLessonId(LESSON_ID)).thenReturn(true);
        when(userStatsRepository.findByUserId(1L)).thenReturn(Optional.of(stats));
        when(userProgressRepository.save(any(UserProgress.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private UserProgress existing(String status, Integer score, Integer stars, int seconds) {
        UserProgress p = new UserProgress();
        p.setUser(user);
        p.setLessonId(LESSON_ID);
        p.setStatus(status);
        p.setScore(score);
        p.setStarsEarned(stars);
        p.setAttempts(1);
        p.setTimeSpentSeconds(seconds);
        when(userProgressRepository.findByUserIdAndLessonId(1L, LESSON_ID)).thenReturn(Optional.of(p));
        return p;
    }

    @Test
    @DisplayName("별 개수: 80점 이상 3개, 60점 이상 2개, 그 외 1개")
    void starsForScore() {
        assertThat(UserProgressService.starsForScore(100)).isEqualTo(3);
        assertThat(UserProgressService.starsForScore(80)).isEqualTo(3);
        assertThat(UserProgressService.starsForScore(79)).isEqualTo(2);
        assertThat(UserProgressService.starsForScore(60)).isEqualTo(2);
        assertThat(UserProgressService.starsForScore(59)).isEqualTo(1);
        assertThat(UserProgressService.starsForScore(0)).isEqualTo(1);
    }

    @Test
    @DisplayName("진행 중 저장: 새 행 INSERT, 완료 수·별은 그대로, 학습 시간은 통계에 반영")
    void saveOrUpdateProgress_Insert() {
        when(userProgressRepository.findByUserIdAndLessonId(1L, LESSON_ID)).thenReturn(Optional.empty());
        when(userProgressRepository.sumTimeSpentSecondsByUserId(1L)).thenReturn(120L);

        UserProgressResponseDto response = userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("in_progress", 5, null, 120));

        assertThat(response.getStatus()).isEqualTo("in_progress");
        assertThat(response.getCurrentStep()).isEqualTo(5);
        assertThat(response.getStarsEarned()).isNull();
        assertThat(response.getTimeSpentSeconds()).isEqualTo(120);
        assertThat(stats.getTotalLessonsCompleted()).isZero();
        assertThat(stats.getTotalStarsEarned()).isZero();
        assertThat(stats.getTotalStudyMinutes()).isEqualTo(2);
        verify(userStatsService, never()).recordStudyActivity(any());
    }

    @Test
    @DisplayName("첫 완료: 실제 점수로 별 계산, 완료 수 +1, 학습 분 = 전체 누적 초 / 60, 스트릭 위임")
    void saveOrUpdateProgress_Completed_UpdatesStats() {
        existing("in_progress", null, null, 30);
        when(userProgressRepository.sumTimeSpentSecondsByUserId(1L)).thenReturn(330L);

        UserProgressResponseDto response = userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("completed", 10, 70, 300));

        assertThat(response.getScore()).isEqualTo(70);
        assertThat(response.getStarsEarned()).isEqualTo(2);
        assertThat(response.getTimeSpentSeconds()).isEqualTo(330);
        assertThat(stats.getTotalLessonsCompleted()).isEqualTo(1);
        assertThat(stats.getTotalStarsEarned()).isEqualTo(2);
        assertThat(stats.getTotalStudyMinutes()).isEqualTo(5); // 330초 → 5분
        verify(userStatsService, times(1)).recordStudyActivity(OAUTH_ID);
    }

    @Test
    @DisplayName("재완료(더 높은 점수): 최고 점수 갱신, 늘어난 별만 통계에 더함, 완료 수는 그대로")
    void recomplete_HigherScore_AddsStarDelta() {
        stats.setTotalLessonsCompleted(1);
        stats.setTotalStarsEarned(1);
        existing("completed", 40, 1, 60);

        UserProgressResponseDto response = userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("completed", 10, 90, 60));

        assertThat(response.getScore()).isEqualTo(90);
        assertThat(response.getStarsEarned()).isEqualTo(3);
        assertThat(stats.getTotalLessonsCompleted()).isEqualTo(1);
        assertThat(stats.getTotalStarsEarned()).isEqualTo(3);
    }

    @Test
    @DisplayName("재완료(더 낮은 점수): 최고 점수·별 유지")
    void recomplete_LowerScore_KeepsBest() {
        stats.setTotalLessonsCompleted(1);
        stats.setTotalStarsEarned(3);
        existing("completed", 100, 3, 60);

        UserProgressResponseDto response = userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("completed", 10, 40, 60));

        assertThat(response.getScore()).isEqualTo(100);
        assertThat(response.getStarsEarned()).isEqualTo(3);
        assertThat(stats.getTotalStarsEarned()).isEqualTo(3);
    }

    @Test
    @DisplayName("완료한 레슨을 다시 풀며 in_progress 를 보내도 completed 유지 → 이후 완료 때 완료 수 중복 없음")
    void completedLesson_NotDowngraded() {
        stats.setTotalLessonsCompleted(1);
        UserProgress p = existing("completed", 100, 3, 60);

        userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("in_progress", 3, null, 20));
        assertThat(p.getStatus()).isEqualTo("completed");

        userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("completed", 10, 100, 20));
        assertThat(stats.getTotalLessonsCompleted()).isEqualTo(1);
    }

    @Test
    @DisplayName("없는 lessonId → NoSuchElementException(404), 아무것도 저장하지 않음")
    void unknownLesson_Throws() {
        assertThatThrownBy(() -> userProgressService.saveOrUpdateProgress(OAUTH_ID, "NOPE",
                new UserProgressRequestDto("completed", 1, 100, 10)))
                .isInstanceOf(NoSuchElementException.class);
        verify(userProgressRepository, never()).save(any());
        verify(userStatsRepository, never()).save(any());
    }

    @Test
    @DisplayName("잘못된 status·score → IllegalArgumentException(400)")
    void invalidRequest_Throws() {
        assertThatThrownBy(() -> userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("done", 1, 100, 10)))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> userProgressService.saveOrUpdateProgress(OAUTH_ID, LESSON_ID,
                new UserProgressRequestDto("completed", 1, 150, 10)))
                .isInstanceOf(IllegalArgumentException.class);
        verify(userProgressRepository, never()).save(any());
    }
}
