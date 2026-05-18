package com.hdy.maru.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_stats")
@Getter
@Setter
@NoArgsConstructor
public class UserStats {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // One-to-One relationship with User.
    // The user_id acts as both a FK and part of the relationship.
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "total_lessons_completed")
    private Integer totalLessonsCompleted = 0;

    @Column(name = "total_study_minutes")
    private Integer totalStudyMinutes = 0;

    @Column(name = "current_streak_days")
    private Integer currentStreakDays = 0;

    @Column(name = "longest_streak_days")
    private Integer longestStreakDays = 0;

    @Column(name = "total_stars_earned")
    private Integer totalStarsEarned = 0;

    @Column(name = "last_study_date")
    private LocalDate lastStudyDate;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
