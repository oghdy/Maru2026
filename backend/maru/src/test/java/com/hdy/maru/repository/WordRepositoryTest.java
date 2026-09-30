package com.hdy.maru.repository;

import com.hdy.maru.entity.Word;
import com.hdy.maru.entity.WordCategory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.data.domain.PageRequest;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class WordRepositoryTest {

    @Autowired
    private WordRepository wordRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("레슨 완료 계산용 단어 ID 순서가 레슨 페이징(/due) 순서와 같다 (등급 A->B->C, ID)")
    void idOrderMatchesLessonPaging() {
        // given: 등급이 섞인 단어 35개 → 레슨 30 / 5
        WordCategory category = new WordCategory();
        category.setTitle("정렬 테스트 카테고리");
        category.setLevel("Beginner");
        entityManager.persist(category);

        String[] levels = {"C", "A", "B"};
        for (int i = 0; i < 35; i++) {
            Word w = new Word();
            w.setKoreanWord("단어" + i);
            w.setPrimaryMeaning("word" + i);
            w.setLevel(levels[i % 3]);
            w.setCategory(category);
            entityManager.persist(w);
        }
        entityManager.flush();
        entityManager.clear();

        // when
        List<Long> ids = wordRepository.findIdsByCategoryIdOrderByLevelAscIdAsc(category.getId());
        List<Long> paged = new ArrayList<>();
        for (int page = 0; page < 2; page++) {
            wordRepository.findByCategoryIdOrderByLevelAscIdAsc(category.getId(), PageRequest.of(page, 30))
                    .forEach(w -> paged.add(w.getId()));
        }

        // then
        assertThat(ids).hasSize(35);
        assertThat(ids).containsExactlyElementsOf(paged);
        assertThat(wordRepository.findById(ids.get(0)).orElseThrow().getLevel()).isEqualTo("A");
        assertThat(wordRepository.findById(ids.get(34)).orElseThrow().getLevel()).isEqualTo("C");
    }
}
