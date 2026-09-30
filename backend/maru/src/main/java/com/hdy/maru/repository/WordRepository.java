package com.hdy.maru.repository;

import com.hdy.maru.entity.Word;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WordRepository extends JpaRepository<Word, Long> {

    long countByCategoryId(Long categoryId);

    List<Word> findByCategoryIdOrderByLevelAscIdAsc(Long categoryId, org.springframework.data.domain.Pageable pageable);

    /**
     * 덱의 단어 ID 를 레슨 페이징과 같은 순서(등급 A->B->C, ID)로 반환합니다. 레슨별 완료 여부 계산용.
     */
    @Query("SELECT w.id FROM Word w WHERE w.category.id = :categoryId ORDER BY w.level ASC, w.id ASC")
    List<Long> findIdsByCategoryIdOrderByLevelAscIdAsc(@Param("categoryId") Long categoryId);
}
