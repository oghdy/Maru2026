package com.hdy.maru.repository;

import com.hdy.maru.entity.AiCache;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
public class AiCacheRepositoryTest {

    @Autowired
    private AiCacheRepository aiCacheRepository;

    @Test
    @DisplayName("Should successfully save and find AiCache with a very long transformationType string")
    void saveAndFind_LongTransformationType_Success() {
        // Given
        String inputText = "나는 음악을 좋아해";
        String longTransformationType = "combine:modifier_politeness_honorific,modifier_tense_past,modifier_negation_not,modifier_nuance_only,modifier_question_true,modifier_emphasis_really";
        String outputText = "저는 정말 음악만 안 좋아했어요?";

        AiCache cache = new AiCache();
        cache.setInputText(inputText);
        cache.setTransformationType(longTransformationType);
        cache.setOutputText(outputText);
        cache.setEnglishTranslation("Did I really not like only music?");
        cache.setExplanation("A very complex combined sentence testing long string persistence.");

        // When
        aiCacheRepository.save(cache);

        Optional<AiCache> foundCache = aiCacheRepository.findByInputTextAndTransformationType(inputText,
                longTransformationType);

        // Then
        assertThat(foundCache).isPresent();
        assertThat(foundCache.get().getOutputText()).isEqualTo(outputText);
        assertThat(foundCache.get().getTransformationType()).isEqualTo(longTransformationType);
    }
}
