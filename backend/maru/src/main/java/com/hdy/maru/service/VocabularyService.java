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

    /** 평가 결과: applied=false 면 가드로 스케줄을 바꾸지 않은 것 */
    public record ReviewOutcome(FsrsProgress progress, boolean applied) {}

    /**
     * 사용자가 특정 단어에 대해 평가(GOOD, AGAIN 등)를 제출했을 때,
     * FSRS 알고리즘으로 진행도(안정성·난이도·다음 복습일 등)를 연산하여 저장합니다.
     *
     * Spacing Integrity Guard: Word Study(LESSON 모드)는 레슨 단어를 복습일과 무관하게 다시 보여주므로,
     * 이미 학습한 단어를 복습일 전에 다시 평가하면 스케줄에 반영하지 않습니다(벼락치기가 간격을 흐트러뜨리지 않도록).
     * 복습일이 지난 단어는 LESSON 모드에서도 정식 복습으로 반영합니다. DAILY_REVIEW 는 항상 반영.
     */
    @Transactional
    public ReviewOutcome submitReview(String oauthId, Long wordId, ReviewRating rating, String reviewMode) {
        Long userId = getUserIdByOauthId(oauthId);
        LocalDateTime now = LocalDateTime.now();

        if (!wordRepository.existsById(wordId)) {
            throw new java.util.NoSuchElementException("Word not found.");
        }

        // 1. 기존 학습 기록 조회
        FsrsProgress progress = fsrsProgressRepository.findByUserIdAndWordId(userId, wordId);

        // [Spacing Integrity Guard] LESSON 모드 + 이미 학습 + 아직 복습일 전 → 평가 무시
        if ("LESSON".equals(reviewMode) && isStudiedAndNotDue(progress, now)) {
            // 단어장에 들어온 것 자체는 오늘의 학습 활동으로 기록 (스트릭 갱신)
            userStatsService.recordStudyActivity(oauthId);
            return new ReviewOutcome(progress, false);
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
            currentCard = toCard(progress);
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

        return new ReviewOutcome(saved, true);
    }

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
        
        LocalDateTime now = LocalDateTime.now();
        return words.stream()
                .map(word -> {
                    FsrsProgress p = progressMap.get(word.getId());
                    if (p == null) {
                        return withIntervals(WordDueDto.fromWord(word), FsrsCard.createNewCard(), now);
                    }
                    WordDueDto dto = WordDueDto.fromProgress(p);
                    // 가드로 반영되지 않을 평가(이미 학습 + 복습일 전)에는 간격을 보여주지 않음
                    return isStudiedAndNotDue(p, now) ? dto : withIntervals(dto, toCard(p), now);
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<WordDueDto> getDailyReviewWords(String oauthId, int limit) {
        Long userId = getUserIdByOauthId(oauthId);
        List<FsrsProgress> dueCards = fsrsProgressRepository.findDueCardsByUser(
                userId, LocalDateTime.now(), PageRequest.of(0, limit)
        );

        LocalDateTime now = LocalDateTime.now();
        return dueCards.stream()
                .map(p -> withIntervals(WordDueDto.fromProgress(p), toCard(p), now))
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

    /** Spacing Integrity Guard 대상: 이미 학습했고 아직 복습일 전인 카드 */
    private static boolean isStudiedAndNotDue(FsrsProgress p, LocalDateTime now) {
        return p != null && p.getState() > 0
                && p.getNextReviewDate() != null && p.getNextReviewDate().isAfter(now);
    }

    private FsrsCard toCard(FsrsProgress progress) {
        return new FsrsCard(
                FsrsState.values()[progress.getState()],
                progress.getStability(),
                progress.getDifficulty(),
                progress.getReps(),
                progress.getLapses(),
                progress.getLastReview(),
                progress.getNextReviewDate()
        );
    }

    /** 평가 버튼별 다음 간격 라벨을 붙임 (실제 스케줄 계산과 같은 FsrsAlgorithm.preview 사용) */
    private WordDueDto withIntervals(WordDueDto dto, FsrsCard card, LocalDateTime now) {
        java.util.Map<String, String> intervals = new java.util.LinkedHashMap<>();
        fsrsAlgorithm.preview(card, now).forEach((rating, next) ->
                intervals.put(rating.name(), formatInterval(java.time.Duration.between(now, next.getNextReviewDate()))));
        return dto.toBuilder().nextIntervals(intervals).build();
    }

    /** 5m / 4d / 3mo / 1.2y */
    static String formatInterval(java.time.Duration d) {
        long minutes = d.toMinutes();
        if (minutes < 60) return Math.max(1, minutes) + "m";
        if (minutes < 24 * 60) return (minutes / 60) + "h";
        long days = d.toDays();
        if (days < 30) return days + "d";
        if (days < 365) return Math.round(days / 30.0) + "mo";
        return String.format(java.util.Locale.ROOT, "%.1fy", days / 365.0);
    }

    private Long getUserIdByOauthId(String oauthId) {
        return userRepository.findByOauthId(oauthId)
                .map(User::getId)
                .orElseThrow(() -> new IllegalArgumentException("User not found for oauthId: " + oauthId));
    }
}
