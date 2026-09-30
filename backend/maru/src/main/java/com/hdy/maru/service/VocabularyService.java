package com.hdy.maru.service;

import com.hdy.maru.domain.fsrs.FsrsAlgorithm;
import com.hdy.maru.domain.fsrs.FsrsCard;
import com.hdy.maru.domain.fsrs.FsrsState;
import com.hdy.maru.domain.fsrs.ReviewRating;
import com.hdy.maru.dto.WordCategoryDto;
import com.hdy.maru.dto.*;
import com.hdy.maru.entity.FsrsProgress;
import com.hdy.maru.entity.User;
import com.hdy.maru.entity.Word;
import com.hdy.maru.repository.FsrsProgressRepository;
import com.hdy.maru.repository.UserRepository;
import com.hdy.maru.repository.WordCategoryRepository;
import com.hdy.maru.repository.WordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class VocabularyService {

    private final FsrsProgressRepository fsrsProgressRepository;
    private final WordRepository wordRepository;
    private final WordCategoryRepository wordCategoryRepository;
    private final UserRepository userRepository;
    private final FsrsAlgorithm fsrsAlgorithm;
    private final UserStatsService userStatsService;

    private static final int LESSON_SIZE = 30;

    /**
     * 특정 레벨의 단어장 목록을 조회하며 각 단어장의 총 단어 수를 포함합니다.
     */
    @Transactional(readOnly = true)
    public List<WordCategoryDto> getDecksWithCount(String level) {
        return wordCategoryRepository.findByLevelOrderByDeckOrderAsc(level).stream()
                .map(cat -> WordCategoryDto.builder()
                        .id(cat.getId())
                        .title(cat.getTitle())
                        .level(cat.getLevel())
                        .totalWords((int) wordRepository.countByCategoryId(cat.getId()))
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * 사용자가 특정 단어에 대해 평가(GOOD, AGAIN 등)를 제출했을 때,
     * 알고리즘 로직에 따라 진행도(진도율, 다음 복습일 등)를 연산하여 저장합니다.
     */
    @Transactional
    public FsrsProgress submitReview(String oauthId, Long wordId, ReviewRating rating, String reviewMode) {
        Long userId = getUserIdByOauthId(oauthId);
        LocalDateTime now = LocalDateTime.now();

        // 1. 기존 학습 기록 조회
        FsrsProgress progress = fsrsProgressRepository.findByUserIdAndWordId(userId, wordId);

        // [방어 로직] 본단어장(LESSON) 모드에서 이미 학습 중인 단어는 평가를 무시함 (데이터 오염 방지)
        if ("LESSON".equals(reviewMode) && progress != null && progress.getState() > 0) {
            // 단어장에 들어온 것 자체를 오늘의 학습 활동으로 기록 (스트릭 갱신)
            userStatsService.recordStudyActivity(oauthId);
            return progress;
        }

        FsrsCard currentCard;
        if (progress == null) {
            // 새 단어일 경우 초기 상태 생성
            progress = new FsrsProgress();
            progress.setUserId(userId);
            progress.setWord(wordRepository.getReferenceById(wordId));
            
            currentCard = FsrsCard.createNewCard();
        } else {
            // 기존 카드 상태 파싱
            currentCard = new FsrsCard(
                    FsrsState.values()[progress.getState()],
                    progress.getStability(),
                    progress.getDifficulty(),
                    progress.getReps(),
                    progress.getLapses(),
                    progress.getLastReview(),
                    progress.getNextReviewDate()
            );
        }

        // 2. FSRS 알고리즘을 통한 스케줄링 연산 (Strategy 적용)
        FsrsCard nextCard = fsrsAlgorithm.calculateNextState(currentCard, rating, now);

        // 3. 연산 결과 엔티티에 반영
        progress.setState(nextCard.getState().getValue());
        progress.setStability(nextCard.getStability());
        progress.setDifficulty(nextCard.getDifficulty());
        progress.setReps(nextCard.getReps());
        progress.setLapses(nextCard.getLapses());
        progress.setLastReview(now);
        progress.setNextReviewDate(nextCard.getNextReviewDate());

        // 4. DB 저장
        FsrsProgress saved = fsrsProgressRepository.save(progress);

        // 5. 오늘 학습 기록 갱신 (단어장 학습도 스트릭에 반영)
        userStatsService.recordStudyActivity(oauthId);

        return saved;
    }

    /**
     * 카드 매칭 게임을 위해 카테고리에서 무작위 8개의 단어를 뽑아 DTO로 변환합니다.
     */
    @Transactional(readOnly = true)
    public List<WordGameDto> getRandomWordsForGame(Long categoryId) {
        return wordRepository.findRandomWordsByCategory(categoryId, 8)
                .stream()
                .map(WordGameDto::fromEntity)
                .collect(Collectors.toList());
    }
    
    /**
     * 오늘 복습해야 할 단어 큐를 구성하여 반환합니다.
     * 복습 기한이 된 기존 단어들 + 한 번도 보지 않은 신규 단어를 섞어 최대 LIMIT 개 반환.
     */
    /**
     * 특정 레슨(30개 단위)에 해당하는 단어들을 조회합니다.
     * 난이도(A->B->C) 순서로 정렬하여 레슨의 일관성을 유지합니다.
     */
    @Transactional(readOnly = true)
    public List<WordDueDto> getDueWordsByLesson(String oauthId, Long categoryId, int lessonNumber, int limit) {
        Long userId = getUserIdByOauthId(oauthId);
        // 0-based index 페이징 처리
        PageRequest pageRequest = PageRequest.of(lessonNumber - 1, limit);
        
        // 카테고리 내 단어들을 등급(A->B->C) 및 ID 순으로 조회
        List<Word> words = wordRepository.findByCategoryIdOrderByLevelAscIdAsc(categoryId, pageRequest);
        
        if (words.isEmpty()) {
            return List.of();
        }

        // 해당 단어들의 학습 기록을 일괄 조회
        List<Long> wordIds = words.stream().map(Word::getId).collect(Collectors.toList());
        List<FsrsProgress> progresses = fsrsProgressRepository.findByUserIdAndWordIdIn(userId, wordIds);
        java.util.Map<Long, FsrsProgress> progressMap = progresses.stream()
                .collect(Collectors.toMap(p -> p.getWord().getId(), p -> p));
        
        return words.stream()
                .map(word -> {
                    FsrsProgress p = progressMap.get(word.getId());
                    if (p != null) {
                        return WordDueDto.fromProgress(p);
                    } else {
                        return WordDueDto.fromWord(word);
                    }
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<WordDueDto> getDueWords(String oauthId, Long categoryId, int limit) {
        Long userId = getUserIdByOauthId(oauthId);
        // 1. 기존 학습 단어 중 오늘 기한이 도래한 카드 조회 (복습 우선)
        List<FsrsProgress> dueCards = fsrsProgressRepository.findDueCardsByCategory(
                userId, categoryId, LocalDateTime.now(), PageRequest.of(0, limit)
        );

        List<WordDueDto> result = dueCards.stream()
                .map(WordDueDto::fromProgress)
                .collect(Collectors.toList());

        // 2. 만약 목표치(limit)에 미달한다면 신규 단어로 채움
        int remaining = limit - result.size();
        if (remaining > 0) {
            List<Word> unstudied = wordRepository.findUnstudiedWordsByCategoryForUser(
                    userId, categoryId, PageRequest.of(0, remaining)
            );
            unstudied.forEach(word -> result.add(WordDueDto.fromWord(word)));
        }

        return result;
    }

    @Transactional(readOnly = true)
    public List<WordDueDto> getDailyReviewWords(String oauthId, int limit) {
        Long userId = getUserIdByOauthId(oauthId);
        List<FsrsProgress> dueCards = fsrsProgressRepository.findDueCardsByUser(
                userId, LocalDateTime.now(), PageRequest.of(0, limit)
        );

        return dueCards.stream()
                .map(WordDueDto::fromProgress)
                .collect(Collectors.toList());
    }
    /**
     * 특정 단어장의 레슨 목록을 30단어씩 끊어서 반환합니다.
     * 레슨의 모든 단어를 한 번 이상 평가했으면(학습 기록 state > 0) 완료로 봅니다.
     */
    @Transactional(readOnly = true)
    public List<WordLessonDto> getLessonsByDeckId(String oauthId, Long deckId) {
        Long userId = getUserIdByOauthId(oauthId);
        // 레슨 페이징(getDueWordsByLesson)과 같은 순서의 단어 ID
        List<Long> wordIds = wordRepository.findIdsByCategoryIdOrderByLevelAscIdAsc(deckId);
        java.util.Set<Long> studied = new java.util.HashSet<>(
                fsrsProgressRepository.findStudiedWordIdsByCategory(userId, deckId));

        java.util.ArrayList<WordLessonDto> lessons = new java.util.ArrayList<>();
        for (int start = 0; start < wordIds.size(); start += LESSON_SIZE) {
            List<Long> lessonWordIds = wordIds.subList(start, Math.min(start + LESSON_SIZE, wordIds.size()));
            int studiedCount = (int) lessonWordIds.stream().filter(studied::contains).count();

            lessons.add(WordLessonDto.builder()
                    .lessonNumber(start / LESSON_SIZE + 1)
                    .totalWords(lessonWordIds.size())
                    .studiedWords(studiedCount)
                    .isCompleted(studiedCount == lessonWordIds.size())
                    .build());
        }

        return lessons;
    }

    /**
     * 특정 레슨(30단어 구역)의 단어로 짝맞추기 타일(단어당 한국어·영어 2장)을 만듭니다.
     * 라운드 구성(5쌍씩)과 셔플은 프론트에서 합니다.
     * 같은 레슨 안에서 뜻이나 한국어 표기가 겹치는 단어(예: 시/도시 = "city")는 짝이 모호해지므로 먼저 나온 것만 씁니다.
     */
    @Transactional(readOnly = true)
    public List<VocabularyGameTileDto> generateGameTiles(Long categoryId, int lessonNumber) {
        if (lessonNumber < 1) {
            throw new IllegalArgumentException("lessonNumber must be 1 or greater.");
        }
        // 1. 해당 레슨의 단어 30개를 가져옴 (/due 와 같은 순서)
        PageRequest pageRequest = PageRequest.of(lessonNumber - 1, LESSON_SIZE);
        List<Word> lessonWords = wordRepository.findByCategoryIdOrderByLevelAscIdAsc(categoryId, pageRequest);

        // 2. 뜻·표기가 겹치는 단어 제외
        java.util.Set<String> seenMeanings = new java.util.HashSet<>();
        java.util.Set<String> seenKorean = new java.util.HashSet<>();
        List<Word> gameWords = new java.util.ArrayList<>();
        for (Word word : lessonWords) {
            String meaning = word.getPrimaryMeaning() == null ? "" : word.getPrimaryMeaning().trim().toLowerCase();
            String korean = word.getKoreanWord() == null ? "" : word.getKoreanWord().trim();
            if (meaning.isEmpty() || korean.isEmpty()) continue;
            if (seenMeanings.contains(meaning) || seenKorean.contains(korean)) continue;
            seenMeanings.add(meaning);
            seenKorean.add(korean);
            gameWords.add(word);
        }

        if (gameWords.isEmpty()) {
            throw new java.util.NoSuchElementException("No words found for this lesson.");
        }

        // 3. 단어마다 한국어·영어 타일 생성
        int totalWords = gameWords.size();
        List<VocabularyGameTileDto> tiles = new java.util.ArrayList<>();
        for (Word word : gameWords) {
            tiles.add(VocabularyGameTileDto.builder()
                    .id(word.getId() + "_KR")
                    .pairId(word.getId())
                    .text(word.getKoreanWord())
                    .type("KOREAN")
                    .totalWords(totalWords)
                    .build());
            tiles.add(VocabularyGameTileDto.builder()
                    .id(word.getId() + "_EN")
                    .pairId(word.getId())
                    .text(word.getPrimaryMeaning())
                    .type("ENGLISH")
                    .totalWords(totalWords)
                    .build());
        }

        return tiles;
    }

    private Long getUserIdByOauthId(String oauthId) {
        return userRepository.findByOauthId(oauthId)
                .map(User::getId)
                .orElseThrow(() -> new IllegalArgumentException("User not found for oauthId: " + oauthId));
    }
}
