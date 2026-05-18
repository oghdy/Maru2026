package com.hdy.maru.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "users", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "oauth_provider", "oauth_id" })
})
@Getter
@Setter
@NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // PostgreSQL의 BIGSERIAL(자동 증가)과 매핑됩니다.
    private Long id;

    @Column(name = "oauth_provider", nullable = false, length = 20)
    private String oauthProvider; // 'google' or 'apple'

    @Column(name = "oauth_id", nullable = false, length = 100)
    private String oauthId;

    @Column(length = 100)
    private String email;

    @Column(length = 50)
    private String nickname; // username -> nickname (SQL 기준 반영)

    @Column(name = "profile_image_url", columnDefinition = "TEXT")
    private String profileImageUrl;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "last_login") // last_login_at -> last_login (SQL 기준 반영)
    private LocalDateTime lastLogin;
}
