package com.hdy.maru.service;

import com.hdy.maru.domain.fsrs.FsrsAlgorithm;
import com.hdy.maru.domain.fsrs.FsrsCard;
import com.hdy.maru.domain.fsrs.FsrsState;
import com.hdy.maru.domain.fsrs.ReviewRating;
import com.hdy.maru.dto.WordCategoryDto;
import com.hdy.maru.dto.WordGameDto;
import com.hdy.maru.dto.WordLessonDto;
import com.hdy.maru.dto.VocabularyGameTileDto;
import com.hdy.maru.entity.FsrsProgress;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.Word;
import com.hdy.maru.entity.WordCategory;
import com.hdy.maru.repository.FsrsProgressRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.WordCategoryRepository;
import com.hdy.maru.repository.WordRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class VocabularyServiceTest {

    @InjectMocks
    private VocabularyService vocabularyService;

    @Mock
    private FsrsProgressRepository fsrsProgressRepository;

    @Mock
    private WordRepository wordRepository;

    @Mock
    private WordCategoryRepository wordCategoryRepository;
    
    @Mock
    private UserRepository userRepository;

    @Mock
    private UserStatsService userStatsService;

    // FsrsAlgorithm은 Mock하지 않고 실제 인스턴스 주입 (순수 로직이므로)
    private final FsrsAlgorithm fsrsAlgorithm = new FsrsAlgorithm();

    @BeforeEach
    void setUp() {
        vocabularyService = new VocabularyService(
            fsrsProgressRepository, 
            wordRepository, 
            wordCategoryRepository, 
            userRepository, 
            fsrsAlgorithm,
            userStatsService
        );
    }

    @Test
    @DisplayName("신규 단어 최초 평가 시 FsrsProgress 레코드가 새로 생성된다")
    void submitReview_createsNewProgress_whenFirstTime() {
        // given
        String oauthId = "test_oauth_id";
        Long userId = 1L;
        Long wordId = 100L;
        
        User mockUser = new User();
        mockUser.setId(userId);
        mockUser.setOauthId(oauthId);
        
        Word mockWord = new Word();
        mockWord.setId(wordId);
        
        given(userRepository.findByOauthId(oauthId)).willReturn(java.util.Optional.of(mockUser));
        given(wordRepository.existsById(wordId)).willReturn(true);
        given(wordRepository.getReferenceById(wordId)).willReturn(mockWord);
        given(fsrsProgressRepository.findByUserIdAndWordId(userId, wordId)).willReturn(null); // 신규 단어
        given(fsrsProgressRepository.save(any(FsrsProgress.class))).willAnswer(i -> i.getArgument(0));

        // when
        FsrsProgress result = vocabularyService.submitReview(oauthId, wordId, ReviewRating.GOOD, "LESSON");

        // then
        // GOOD 평가 시 state는 REVIEW가 되고, 다음 리뷰날짜가 계산되어야 함
        assertThat(result.getState()).isEqualTo(FsrsState.REVIEW.getValue());
        // FSRS-4.5 기본 파라미터: S0(GOOD) = w2, D0(GOOD) = w4
        assertThat(result.getStability()).isCloseTo(3.7145, org.assertj.core.api.Assertions.within(1e-9));
        assertThat(result.getDifficulty()).isCloseTo(5.1618, org.assertj.core.api.Assertions.within(1e-9));
        assertThat(result.getReps()).isEqualTo(1);
        
        verify(fsrsProgressRepository).save(any(FsrsProgress.class));
    }

    @Test
    @DisplayName("기존 단어 평가 시 기존 레코드가 정확히 업데이트된다")
    void submitReview_updatesExistingProgress_whenAlreadyStudied() {
        // given
        String oauthId = "test_oauth_id";
        Long userId = 1L;
        Long wordId = 100L;
        
        User mockUser = new User();
        mockUser.setId(userId);
        
        Word mockWord = new Word();
        mockWord.setId(wordId);
        
        FsrsProgress existingProgress = new FsrsProgress();
        existingProgress.setId(10L);
        existingProgress.setUserId(userId);
        existingProgress.setWord(mockWord);
        existingProgress.setState(FsrsState.REVIEW.getValue());
        existingProgress.setStability(4.0);
        existingProgress.setDifficulty(5.0);
        existingProgress.setReps(1);
        existingProgress.setLapses(0);
        existingProgress.setLastReview(LocalDateTime.now().minusDays(4));
        
        given(userRepository.findByOauthId(oauthId)).willReturn(java.util.Optional.of(mockUser));
        given(wordRepository.existsById(wordId)).willReturn(true);
        given(fsrsProgressRepository.findByUserIdAndWordId(userId, wordId)).willReturn(existingProgress);
        given(fsrsProgressRepository.save(existingProgress)).willAnswer(i -> i.getArgument(0));

        // when (기존 1회 복습 카드에 AGAIN 틀림 판정)
        FsrsProgress result = vocabularyService.submitReview(oauthId, wordId, ReviewRating.AGAIN, "DAILY_REVIEW");

        // then
        assertThat(result.getId()).isEqualTo(10L); // 기존 엔티티 재사용
        assertThat(result.getState()).isEqualTo(FsrsState.RELEARNING.getValue());
        assertThat(result.getLapses()).isEqualTo(1);
        assertThat(result.getReps()).isEqualTo(2);
        assertThat(result.getStability()).isLessThan(4.0); // 안정기가 떨어짐
        
        verify(fsrsProgressRepository).save(existingProgress);
    }

    @Test
    @DisplayName("LESSON 모드에서 이미 학습된 단어(state > 0)에 대한 평가 요청은 무시된다")
    void submitReview_shouldIgnore_whenAlreadyStudiedInLessonMode() {
        // given
        String oauthId = "test_oauth_id";
        Long userId = 1L;
        Long wordId = 100L;
        
        User mockUser = new User();
        mockUser.setId(userId);
        
        FsrsProgress existingProgress = new FsrsProgress();
        existingProgress.setUserId(userId);
        existingProgress.setState(FsrsState.REVIEW.getValue()); // 이미 학습됨
        
        given(userRepository.findByOauthId(oauthId)).willReturn(java.util.Optional.of(mockUser));
        given(wordRepository.existsById(wordId)).willReturn(true);
        given(fsrsProgressRepository.findByUserIdAndWordId(userId, wordId)).willReturn(existingProgress);

        // when
        FsrsProgress result = vocabularyService.submitReview(oauthId, wordId, ReviewRating.GOOD, "LESSON");

        // then
        assertThat(result).isSameAs(existingProgress);
        // 저장이 호출되지 않아야 함 (가드 로직 확인)
        verify(fsrsProgressRepository, org.mockito.Mockito.never()).save(any());
        // 단어장 진입 자체는 학습 활동으로 기록됨 (스트릭)
        verify(userStatsService).recordStudyActivity(oauthId);
    }

    @Test
    @DisplayName("게임용 랜덤 단어 추출 시 정확히 DTO로 변환된다")
    void getRandomWordsForGame_mapsToDtoCorrectly() {
        // given
        Long categoryId = 5L;

        Word mockWord1 = new Word();
        mockWord1.setId(10L);
        mockWord1.setKoreanWord("사과");
        mockWord1.setPrimaryMeaning("apple");
        mockWord1.setPartOfSpeech("Noun");

        Word mockWord2 = new Word();
        mockWord2.setId(20L);
        mockWord2.setKoreanWord("달리다");
        mockWord2.setPrimaryMeaning("to run");
        mockWord2.setPartOfSpeech("Verb");

        given(wordRepository.findRandomWordsByCategory(categoryId, 8))
                .willReturn(List.of(mockWord1, mockWord2));

        // when
        List<WordGameDto> results = vocabularyService.getRandomWordsForGame(categoryId);

        // then
        assertThat(results).hasSize(2);
        assertThat(results.get(0).getKorean()).isEqualTo("사과");
        assertThat(results.get(0).getMeaning()).isEqualTo("apple");
        assertThat(results.get(1).getKorean()).isEqualTo("달리다");
    }

    @Test
    @DisplayName("덱 목록 조회 시 단어 수가 포함된 DTO로 변환된다")
    void getDecksWithCount_returnsDtoWithWordCount() {
        // given
        String level = "Beginner";
        WordCategory cat = new WordCategory();
        cat.setId(1L);
        cat.setTitle("초급");
        cat.setLevel(level);

        given(wordCategoryRepository.findByLevelOrderByDeckOrderAsc(level)).willReturn(List.of(cat));
        given(wordRepository.countByCategoryId(1L)).willReturn(155L);

        // when
        List<WordCategoryDto> results = vocabularyService.getDecksWithCount(level);

        // then
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getTotalWords()).isEqualTo(155);
        assertThat(results.get(0).getTitle()).isEqualTo("초급");
    }

    @Test
    @DisplayName("레슨 목록: 30단어씩 끊고, 모든 단어를 평가한 레슨만 완료로 표시한다")
    void getLessonsByDeckId_marksCompletedFromStudyRecords() {
        // given: 단어 65개 → 레슨 30 / 30 / 5
        String oauthId = "test_oauth_id";
        User mockUser = new User();
        mockUser.setId(1L);
        List<Long> wordIds = java.util.stream.LongStream.rangeClosed(1, 65).boxed().toList();
        // 레슨 1 전부 + 레슨 2 의 10개 학습
        List<Long> studied = java.util.stream.LongStream.rangeClosed(1, 40).boxed().toList();

        given(userRepository.findByOauthId(oauthId)).willReturn(java.util.Optional.of(mockUser));
        given(wordRepository.findIdsByCategoryIdOrderByLevelAscIdAsc(7L)).willReturn(wordIds);
        given(fsrsProgressRepository.findStudiedWordIdsByCategory(1L, 7L)).willReturn(studied);

        // when
        List<WordLessonDto> lessons = vocabularyService.getLessonsByDeckId(oauthId, 7L);

        // then
        assertThat(lessons).extracting(WordLessonDto::getLessonNumber).containsExactly(1, 2, 3);
        assertThat(lessons).extracting(WordLessonDto::getTotalWords).containsExactly(30, 30, 5);
        assertThat(lessons).extracting(WordLessonDto::getStudiedWords).containsExactly(30, 10, 0);
        assertThat(lessons).extracting(WordLessonDto::isCompleted).containsExactly(true, false, false);
    }

    private Word word(long id, String korean, String meaning) {
        Word w = new Word();
        w.setId(id);
        w.setKoreanWord(korean);
        w.setPrimaryMeaning(meaning);
        return w;
    }

    @Test
    @DisplayName("게임 타일: 뜻/표기가 겹치는 단어는 제외하고, 모든 타일에 단어 수를 싣는다")
    void generateGameTiles_skipsAmbiguousPairs_andCarriesTotalWords() {
        given(wordRepository.findByCategoryIdOrderByLevelAscIdAsc(any(), any())).willReturn(List.of(
                word(1L, "도시", "city"),
                word(2L, "시", "City "),     // 뜻 중복 → 제외
                word(3L, "골목", "alley"),
                word(4L, "골목", "lane")));  // 표기 중복 → 제외

        List<VocabularyGameTileDto> tiles = vocabularyService.generateGameTiles(12L, 1);

        assertThat(tiles).hasSize(4);
        assertThat(tiles).extracting(VocabularyGameTileDto::getPairId).containsExactly(1L, 1L, 3L, 3L);
        assertThat(tiles).allSatisfy(t -> assertThat(t.getTotalWords()).isEqualTo(2));
    }

    @Test
    @DisplayName("게임 타일: 단어가 없는 레슨은 NoSuchElementException(404), lessonNumber<1 은 IllegalArgumentException(400)")
    void generateGameTiles_rejectsEmptyOrInvalidLesson() {
        given(wordRepository.findByCategoryIdOrderByLevelAscIdAsc(any(), any())).willReturn(List.of());

        org.assertj.core.api.Assertions.assertThatThrownBy(() -> vocabularyService.generateGameTiles(12L, 99))
                .isInstanceOf(java.util.NoSuchElementException.class);
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> vocabularyService.generateGameTiles(12L, 0))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("없는 단어 평가는 NoSuchElementException(404)이고 기록을 만들지 않는다")
    void submitReview_rejectsUnknownWord() {
        User mockUser = new User();
        mockUser.setId(1L);
        given(userRepository.findByOauthId("test_oauth_id")).willReturn(java.util.Optional.of(mockUser));
        given(wordRepository.existsById(404L)).willReturn(false);

        org.assertj.core.api.Assertions.assertThatThrownBy(
                        () -> vocabularyService.submitReview("test_oauth_id", 404L, ReviewRating.GOOD, "LESSON"))
                .isInstanceOf(java.util.NoSuchElementException.class);
        verify(fsrsProgressRepository, org.mockito.Mockito.never()).save(any());
    }
}
