import '../../models/vocabulary/word_category.dart';
import '../../models/vocabulary/word_card.dart';
import '../../models/vocabulary/review_request.dart';

abstract class VocabularyRepository {
  Future<List<WordCategory>> getDecks({String level = 'Beginner'});
  Future<List<WordCard>> getDueWords(int deckId, {int limit = 30});
  Future<void> submitReview(ReviewRequest request);
  Future<List<WordCard>> getGameWords(int deckId);
}
