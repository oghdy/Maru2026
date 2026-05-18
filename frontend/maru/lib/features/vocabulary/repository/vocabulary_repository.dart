import '../models/word_category.dart';
import '../models/word_card.dart';
import '../models/review_request.dart';
import '../models/word_lesson.dart';
import '../models/vocabulary_game_tile.dart';

abstract class VocabularyRepository {
  Future<List<WordCategory>> getDecks({String level = 'Beginner'});
  Future<List<WordCard>> getDueWords(int deckId, {int lessonNumber = 1, int limit = 30});
  Future<List<WordCard>> getDailyReviewWords({int limit = 30});
  Future<void> submitReview(ReviewRequest request);
  Future<List<VocabularyGameTile>> getGameTiles(int deckId, {int lessonNumber = 1});
  Future<List<WordLesson>> getLessons(int deckId);
}
