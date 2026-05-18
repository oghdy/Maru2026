import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocabulary/word_card.dart';
import '../models/vocabulary/word_category.dart';
import '../models/vocabulary/review_request.dart';
import '../services/vocabulary_repository.dart';
import '../services/vocabulary_repository_impl.dart';
import '../utils/api_constants.dart';

// 1. Dio Provider
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
});

// 2. Repository Provider
final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VocabularyRepositoryImpl(dio);
});

// 3. Category (Decks) Provider (Simple FutureProvider)
final vocabularyCategoriesProvider = FutureProvider.family<List<WordCategory>, String>((ref, level) async {
  final repository = ref.watch(vocabularyRepositoryProvider);
  return repository.getDecks(level: level);
});

// 4. Learning Session State
class VocabularySessionState {
  final List<WordCard> words;
  final int currentIndex;
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  VocabularySessionState({
    this.words = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  VocabularySessionState copyWith({
    List<WordCard>? words,
    int? currentIndex,
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return VocabularySessionState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  WordCard? get currentWord => words.isNotEmpty && currentIndex < words.length 
      ? words[currentIndex] 
      : null;
}

// 5. Vocabulary Session Notifier
class VocabularyNotifier extends StateNotifier<VocabularySessionState> {
  final VocabularyRepository _repository;

  VocabularyNotifier(this._repository) : super(VocabularySessionState());

  Future<void> loadDueWords(int deckId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isCompleted: false);
    try {
      final words = await _repository.getDueWords(deckId);
      state = state.copyWith(words: words, isLoading: false, currentIndex: 0);
      
      if (words.isEmpty) {
        state = state.copyWith(isCompleted: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> submitRating(ReviewRating rating) async {
    final currentWord = state.currentWord;
    if (currentWord == null) return;

    // 1. 서버에 결과 전송 (백그라운드에서 실행)
    _repository.submitReview(ReviewRequest(
      wordId: currentWord.id,
      rating: rating.value,
    )).catchError((e) {
      // 실구현 시 에러 핸들링 로직 추가 (예: 로컬 큐 저장)
      print('Failed to submit review: $e');
    });

    // 2. UI 상태 업데이트 (다음 단어로 이동)
    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.words.length) {
      state = state.copyWith(currentIndex: nextIndex);
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }
}

// 6. Notifier Provider
final vocabularySessionProvider = StateNotifierProvider<VocabularyNotifier, VocabularySessionState>((ref) {
  final repository = ref.watch(vocabularyRepositoryProvider);
  return VocabularyNotifier(repository);
});
