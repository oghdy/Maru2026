package com.hdy.maru.repository;

import com.hdy.maru.entity.WordCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WordCategoryRepository extends JpaRepository<WordCategory, Long> {
    
    // 등급별로 정렬순서에 맞춰 조회
    List<WordCategory> findByLevelOrderByDeckOrderAsc(String level);
}
