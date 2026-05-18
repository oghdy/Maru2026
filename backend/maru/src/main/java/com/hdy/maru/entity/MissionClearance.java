package com.hdy.maru.entity;

import com.hdy.maru.util.JsonListConverter;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Entity
@Table(name = "mission_clearances")
@Getter
@Setter
@NoArgsConstructor
public class MissionClearance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "mission_title", nullable = false)
    private String missionTitle;

    @Column(nullable = false)
    private String persona;

    @Column(name = "total_turns", nullable = false)
    private int totalTurns;

    @Convert(converter = JsonListConverter.class)
    @Column(name = "good_expressions", columnDefinition = "TEXT")
    private List<Map<String, String>> goodExpressions;

    @Convert(converter = JsonListConverter.class)
    @Column(name = "incorrect_expressions", columnDefinition = "TEXT")
    private List<Map<String, String>> incorrectExpressions;

    @Column(name = "turtle_comment", columnDefinition = "TEXT")
    private String turtleComment;

    @Column(name = "next_practice")
    private String nextPractice;

    @CreationTimestamp
    @Column(name = "cleared_at", updatable = false)
    private LocalDateTime clearedAt;
}
