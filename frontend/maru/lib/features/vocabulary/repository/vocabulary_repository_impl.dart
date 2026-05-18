import 'package:dio/dio.dart';
import '../models/word_category.dart';
import '../models/word_card.dart';
import '../models/review_request.dart';
import '../models/word_lesson.dart';
import '../models/vocabulary_game_tile.dart';
import '../../../core/constants/api_constants.dart';
import 'vocabulary_repository.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  final Dio _dio;

  VocabularyRepositoryImpl(this._dio);

  @override
  Future<List<WordCategory>> getDecks({String level = 'Beginner'}) async {
    try {
      final response = await _dio.get(
        ApiConstants.decks,
        queryParameters: {'level': level},
      );
      
      final List<dynamic> data = response.data['data'];
      return data.map((json) => WordCategory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load decks: $e');
    }
  }

  @override
  Future<List<WordCard>> getDueWords(int deckId, {int lessonNumber = 1, int limit = 30}) async {
    try {
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
    } catch (e) {
      throw Exception('Failed to load due words: $e');
    }
  }

  @override
  Future<List<WordCard>> getDailyReviewWords({int limit = 30}) async {
    try {
      final response = await _dio.get(
        ApiConstants.dailyReview,
        queryParameters: {'limit': limit},
      );
      
      final List<dynamic> data = response.data['data'];
      return data.map((json) => WordCard.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load daily review words: $e');
    }
  }

  @override
  Future<void> submitReview(ReviewRequest request) async {
    try {
      await _dio.post(
        ApiConstants.review,
        data: request.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  @override
  Future<List<VocabularyGameTile>> getGameTiles(int deckId, {int lessonNumber = 1}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.game}/$deckId',
        queryParameters: {'lessonNumber': lessonNumber},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => VocabularyGameTile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load game tiles: $e');
    }
  }

  @override
  Future<List<WordLesson>> getLessons(int deckId) async {
    try {
      final response = await _dio.get('${ApiConstants.decks}/$deckId/lessons');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => WordLesson.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load lessons: $e');
    }
  }
}
