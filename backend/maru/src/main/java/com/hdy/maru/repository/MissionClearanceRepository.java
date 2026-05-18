package com.hdy.maru.repository;

import com.hdy.maru.entity.MissionClearance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MissionClearanceRepository extends JpaRepository<MissionClearance, Long> {
    
    /**
     * Finds all mission clearances for a specific user, ordered by the cleared_at date descending.
     */
    List<MissionClearance> findByUserIdOrderByClearedAtDesc(Long userId);
}
