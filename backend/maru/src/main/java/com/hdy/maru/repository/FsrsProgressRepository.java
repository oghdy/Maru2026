package com.hdy.maru.repository;

import com.hdy.maru.entity.FsrsProgress;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FsrsProgressRepository extends JpaRepository<FsrsProgress, Long> {

    @Query("SELECT f FROM FsrsProgress f " +
           "JOIN FETCH f.word w " +
           "WHERE f.userId = :userId " +
           "AND w.category.id = :categoryId " +
           "AND f.nextReviewDate <= :now " +
           "ORDER BY f.state ASC, f.nextReviewDate ASC")
    List<FsrsProgress> findDueCardsByCategory(
            @Param("userId") Long userId,
            @Param("categoryId") Long categoryId,
            @Param("now") LocalDateTime now,
            Pageable pageable
    );

    @Query("SELECT f FROM FsrsProgress f " +
           "JOIN FETCH f.word w " +
           "WHERE f.userId = :userId " +
           "AND f.nextReviewDate <= :now " +
           "ORDER BY f.state ASC, f.nextReviewDate ASC")
    List<FsrsProgress> findDueCardsByUser(
            @Param("userId") Long userId,
            @Param("now") LocalDateTime now,
            Pageable pageable
    );

    // 복합키(유저, 단어)를 통해 해당 유저의 특정 단어 학습 상태 단건 조회
    @Query("SELECT f FROM FsrsProgress f WHERE f.userId = :userId AND f.word.id = :wordId")
    FsrsProgress findByUserIdAndWordId(
            @Param("userId") Long userId,
            @Param("wordId") Long wordId
    );

    @Query("SELECT f FROM FsrsProgress f JOIN FETCH f.word w WHERE f.userId = :userId AND f.word.id IN :wordIds")
    List<FsrsProgress> findByUserIdAndWordIdIn(
            @Param("userId") Long userId,
            @Param("wordIds") List<Long> wordIds
    );
}
