package com.hdy.maru.repository;

import com.hdy.maru.entity.Word;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WordRepository extends JpaRepository<Word, Long> {

    /**
     * 특정 카테고리에 속한 단어들 중 게임을 위해 로컬 DB 무작위 순서로 N개를 반환합니다.
     * (PostgreSQL 전용 문법인 ORDER BY RANDOM()을 활용)
     */
    @Query(value = "SELECT * FROM words w WHERE w.category_id = :categoryId ORDER BY RANDOM() LIMIT :limit", nativeQuery = true)
    List<Word> findRandomWordsByCategory(
            @Param("categoryId") Long categoryId,
            @Param("limit") int limit
    );

    /**
     * 해당 유저가 아직 한 번도 학습하지 않은 (FsrsProgress 레코드가 없는) 신규 단어 조회
     */
    @Query("SELECT w FROM Word w WHERE w.category.id = :categoryId " +
           "AND w.id NOT IN (SELECT f.word.id FROM FsrsProgress f WHERE f.userId = :userId) " +
           "ORDER BY w.id ASC")
    List<Word> findUnstudiedWordsByCategoryForUser(
            @Param("userId") Long userId,
            @Param("categoryId") Long categoryId,
            org.springframework.data.domain.Pageable pageable
    );

    long countByCategoryId(Long categoryId);

    List<Word> findByCategoryIdOrderByLevelAscIdAsc(Long categoryId, org.springframework.data.domain.Pageable pageable);
}
