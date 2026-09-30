package com.hdy.maru.repository;

import com.hdy.maru.entity.TtsCache;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TtsCacheRepository extends JpaRepository<TtsCache, Long> {
    Optional<TtsCache> findByCacheKey(String cacheKey);
}
