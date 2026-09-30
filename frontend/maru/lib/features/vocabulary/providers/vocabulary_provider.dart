import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/word_card.dart';
import '../models/word_category.dart';
import '../models/word_lesson.dart';
import '../models/review_request.dart';
import '../repository/vocabulary_repository.dart';
import '../repository/vocabulary_repository_impl.dart';

// 1. Repository Provider
final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VocabularyRepositoryImpl(dio);
});

// 2. Category (Decks) Provider
final vocabularyCategoriesProvider = FutureProvider.family<List<WordCategory>, String>((ref, level) async {
  final repository = ref.watch(vocabularyRepositoryProvider);
  return repository.getDecks(level: level);
});

// 2-0. Lessons (30-word chunks) of a deck, with the user's progress.
// Word Study / Match 에서 돌아오면 invalidate 해서 완료·진행 표시를 갱신한다.
final vocabularyLessonsProvider = FutureProvider.autoDispose.family<List<WordLesson>, int>((ref, deckId) async {
  final repository = ref.watch(vocabularyRepositoryProvider);
  return repository.getLessons(deckId);
});

// 2-1. Daily Review Count Provider
final dailyReviewCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(vocabularyRepositoryProvider);
  final words = await repository.getDailyReviewWords(limit: 100);
  return words.length;
});

// 3. Learning Session State
class VocabularySessionState {
  final List<WordCard> words;
  final int currentIndex;
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;
  final String reviewMode; // "LESSON" or "DAILY_REVIEW"

  VocabularySessionState({
    this.words = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
    this.reviewMode = "LESSON",
  });

  VocabularySessionState copyWith({
    List<WordCard>? words,
    int? currentIndex,
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
    String? reviewMode,
  }) {
    return VocabularySessionState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
      reviewMode: reviewMode ?? this.reviewMode,
    );
  }

  WordCard? get currentWord => words.isNotEmpty && currentIndex < words.length 
      ? words[currentIndex] 
      : null;
}

// 4. Vocabulary Session Notifier (Riverpod 3.0 Notifier 방식)
class VocabularyNotifier extends Notifier<VocabularySessionState> {
  @override
  VocabularySessionState build() {
    return VocabularySessionState();
  }

  VocabularyRepository get _repository => ref.read(vocabularyRepositoryProvider);

  Future<void> loadDueWords(int deckId, {int lessonNumber = 1}) async {
    // copyWith 로는 이전 errorMessage 를 지울 수 없어서 새 상태로 시작
    state = VocabularySessionState(isLoading: true, reviewMode: "LESSON");
    try {
      final words = await _repository.getDueWords(deckId, lessonNumber: lessonNumber);
      state = state.copyWith(words: words, isLoading: false, currentIndex: 0);
      
      if (words.isEmpty) {
        state = state.copyWith(isCompleted: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadDailyReviewWords() async {
    state = VocabularySessionState(isLoading: true, reviewMode: "DAILY_REVIEW");
    try {
      final words = await _repository.getDailyReviewWords();
      state = state.copyWith(words: words, isLoading: false, currentIndex: 0);
      
      if (words.isEmpty) {
        state = state.copyWith(isCompleted: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 화면에 보이는 카드의 단어로 평가를 제출한다.
  /// (이전: state.currentIndex 의 단어로 제출 → 스와이프로 넘긴 뒤 평가하면 다른 단어가 저장됨, VOC-1.2.12)
  /// 저장 성공 여부를 돌려준다 (실패 시 화면에서 안내).
  Future<bool> submitRating(WordCard word, ReviewRating rating) async {
    try {
      await _repository.submitReview(ReviewRequest(
        wordId: word.id,
        rating: rating.value,
        reviewMode: state.reviewMode,
      ));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// PageView 의 현재 페이지와 동기화 (진행 표시 n / N 용)
  void setCurrentIndex(int index) {
    if (index != state.currentIndex) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void completeSession() {
    state = state.copyWith(isCompleted: true);
  }
}

// 5. Notifier Provider (Riverpod 3.0 방식)
final vocabularySessionProvider = NotifierProvider<VocabularyNotifier, VocabularySessionState>(() {
  return VocabularyNotifier();
});
