package com.hdy.maru.repository;

import com.hdy.maru.entity.FsrsProgress;
import com.hdy.maru.entity.Word;
import com.hdy.maru.entity.WordCategory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class FsrsProgressRepositoryTest {

    @Autowired
    private FsrsProgressRepository fsrsProgressRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    @DisplayName("오늘의 복습: 기한이 도래한 카드를 지정한 갯수 제한만큼, state 오름차순으로 조회한다")
    void findDueCardsByUser_limitsToPageSize() {
        // given
        Long userId = 100L;
        WordCategory category = new WordCategory();
        category.setTitle("테스트 카테고리");
        category.setLevel("Beginner");
        entityManager.persist(category);

        for (int i = 0; i < 50; i++) {
            Word word = new Word();
            word.setKoreanWord("단어" + i);
            word.setPrimaryMeaning("word" + i);
            word.setCategory(category);
            entityManager.persist(word);

            FsrsProgress progress = new FsrsProgress();
            progress.setUserId(userId);
            progress.setWord(word);
            progress.setState(i % 4); // 0: New, 1: Learning, 2: Review, 3: Relearning 다양하게 섞음
            // 모두 과거 시간으로 설정하여 복습 기한 도래 상태로 만듦
            progress.setNextReviewDate(LocalDateTime.now().minusDays(1)); 
            entityManager.persist(progress);
        }
        entityManager.flush();
        entityManager.clear();

        // when
        LocalDateTime now = LocalDateTime.now();
        List<FsrsProgress> result = fsrsProgressRepository.findDueCardsByUser(
                userId, 
                now, 
                PageRequest.of(0, 30) // 최대 30개 제한
        );

        // then
        assertThat(result).hasSize(30); // 50개를 넣었으나 30개만 나와야 함
        // 정렬 순서 검증: state 오름차순이므로 0 (New)가 먼저 나와야 함
        assertThat(result.get(0).getState()).isEqualTo(0);
    }
    
    @Test
    @DisplayName("오늘의 복습: 복습 기한이 아직 도래하지 않은 단어는 조회 대상에서 제외된다")
    void ignoresFutureReviewDates() {
        // given
        Long userId = 101L;
        WordCategory category = new WordCategory();
        category.setTitle("테스트 카테고리2");
        category.setLevel("Beginner");
        entityManager.persist(category);

        Word word1 = new Word();
        word1.setKoreanWord("과거단어");
        word1.setPrimaryMeaning("word1");
        word1.setCategory(category);
        entityManager.persist(word1);
        
        Word word2 = new Word();
        word2.setKoreanWord("미래단어");
        word2.setPrimaryMeaning("word2");
        word2.setCategory(category);
        entityManager.persist(word2);

        FsrsProgress pastProgress = new FsrsProgress();
        pastProgress.setUserId(userId);
        pastProgress.setWord(word1);
        pastProgress.setNextReviewDate(LocalDateTime.now().minusMinutes(5));
        entityManager.persist(pastProgress);
        
        FsrsProgress futureProgress = new FsrsProgress();
        futureProgress.setUserId(userId);
        futureProgress.setWord(word2);
        futureProgress.setNextReviewDate(LocalDateTime.now().plusHours(5));
        entityManager.persist(futureProgress);

        entityManager.flush();
        entityManager.clear();

        // when
        LocalDateTime now = LocalDateTime.now();
        List<FsrsProgress> result = fsrsProgressRepository.findDueCardsByUser(
                userId, 
                now, 
                PageRequest.of(0, 10)
        );

        // then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getWord().getKoreanWord()).isEqualTo("과거단어");
    }
}
