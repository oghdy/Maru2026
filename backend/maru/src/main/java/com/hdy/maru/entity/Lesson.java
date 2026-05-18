package com.hdy.maru.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;

@Entity
@Table(name = "lessons", indexes = {
        @Index(name = "idx_lessons_unit", columnList = "unit_id"),
        @Index(name = "idx_lessons_published", columnList = "is_published")
// Note: GIN index for JSONB content is database-specific and typically needs to
// be created via custom SQL (e.g., Flyway/Liquibase or manual query) because
// standard JPA @Index doesn't support specifying 'USING GIN'.
})
@Getter
@Setter
@NoArgsConstructor
public class Lesson {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "lesson_id", nullable = false, unique = true, length = 50)
    private String lessonId;

    @Column(name = "unit_id", nullable = false)
    private Integer unitId;

    @Column(name = "unit_title", nullable = false, length = 100)
    private String unitTitle;

    @Column(name = "order_num", nullable = false)
    private Integer orderNum;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "difficulty_level")
    private Integer difficultyLevel = 1;

    @Column(name = "estimated_minutes")
    private Integer estimatedMinutes = 15;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    private com.hdy.maru.dto.LessonContentDto content; // Properly mapped to DTO for automatic JSONB serialization

    @Column(name = "is_published")
    private Boolean isPublished = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
