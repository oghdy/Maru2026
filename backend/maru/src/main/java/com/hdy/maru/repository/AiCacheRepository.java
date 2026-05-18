package com.hdy.maru.repository;

import com.hdy.maru.entity.AiCache;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AiCacheRepository extends JpaRepository<AiCache, Long> {

    // Per user's strict 85-point feedback: MUST use composite key lookup!
    Optional<AiCache> findByInputTextAndTransformationType(String inputText, String transformationType);
}
