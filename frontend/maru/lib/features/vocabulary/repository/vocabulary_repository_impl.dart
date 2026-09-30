import 'package:dio/dio.dart';
import '../models/word_category.dart';
import '../models/word_card.dart';
import '../models/review_request.dart';
import '../models/word_lesson.dart';
import '../models/vocabulary_game_tile.dart';
import '../../../core/constants/api_constants.dart';
import 'vocabulary_repository.dart';

// 오류는 감싸지 않고 그대로 던진다 (화면에서 friendlyVocabularyError 로 영어 문구 변환)
class VocabularyRepositoryImpl implements VocabularyRepository {
  final Dio _dio;

  VocabularyRepositoryImpl(this._dio);

  @override
  Future<List<WordCategory>> getDecks({String level = 'Beginner'}) async {
    final response = await _dio.get(
      ApiConstants.decks,
      queryParameters: {'level': level},
    );
    
    final List<dynamic> data = response.data['data'];
    return data.map((json) => WordCategory.fromJson(json)).toList();
  }

  @override
  Future<List<WordCard>> getDueWords(int deckId, {int lessonNumber = 1, int limit = 30}) async {
    final response = await _dio.get(
      ApiConstants.due,
      queryParameters: {
        'deckId': deckId,
        'lessonNumber': lessonNumber,
        'limit': limit,
      },
    );
    
    final List<dynamic> data = response.data['data'];
    return data.map((json) => WordCard.fromJson(json)).toList();
  }

  @override
  Future<List<WordCard>> getDailyReviewWords({int limit = 30}) async {
    final response = await _dio.get(
      ApiConstants.dailyReview,
      queryParameters: {'limit': limit},
    );
    
    final List<dynamic> data = response.data['data'];
    return data.map((json) => WordCard.fromJson(json)).toList();
  }

  @override
  Future<void> submitReview(ReviewRequest request) async {
    await _dio.post(
      ApiConstants.review,
      data: request.toJson(),
    );
  }

  @override
  Future<List<VocabularyGameTile>> getGameTiles(int deckId, {int lessonNumber = 1}) async {
    final response = await _dio.get(
      '${ApiConstants.game}/$deckId',
      queryParameters: {'lessonNumber': lessonNumber},
    );
    final List<dynamic> data = response.data['data'];
    return data.map((json) => VocabularyGameTile.fromJson(json)).toList();
  }

  @override
  Future<List<WordLesson>> getLessons(int deckId) async {
    final response = await _dio.get('${ApiConstants.decks}/$deckId/lessons');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => WordLesson.fromJson(json)).toList();
  }
}
