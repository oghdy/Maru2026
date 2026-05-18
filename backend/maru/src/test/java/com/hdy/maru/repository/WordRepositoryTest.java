package com.hdy.maru.repository;

import com.hdy.maru.entity.Word;
import com.hdy.maru.entity.WordCategory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class WordRepositoryTest {

    @Autowired
    private WordRepository wordRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("특정 카테고리의 단어를 무작위로 추출한다")
    void findRandomWordsByCategory_limitsToCount() {
        // given
        WordCategory category = new WordCategory();
        category.setTitle("랜덤 테스트 카테고리");
        category.setLevel("Beginner");
        entityManager.persist(category);

        // 15개의 단어를 삽입
        for (int i = 0; i < 15; i++) {
            Word w = new Word();
            w.setKoreanWord("단어" + i);
            w.setPrimaryMeaning("word" + i);
            w.setCategory(category);
            entityManager.persist(w);
        }
        entityManager.flush();
        entityManager.clear();

        // when (8개를 제한해서 가져옴)
        List<Word> result = wordRepository.findRandomWordsByCategory(category.getId(), 8);

        // then
        assertThat(result).hasSize(8);
        for (Word w : result) {
            assertThat(w.getCategory().getId()).isEqualTo(category.getId());
        }
    }
}
