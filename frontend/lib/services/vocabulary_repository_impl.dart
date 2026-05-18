import 'package:dio/dio.dart';
import '../models/vocabulary/word_category.dart';
import '../models/vocabulary/word_card.dart';
import '../models/vocabulary/review_request.dart';
import '../utils/api_constants.dart';
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
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => WordCategory.fromJson(json)).toList();
      }
      throw Exception('Failed to load decks');
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  @override
  Future<List<WordCard>> getDueWords(int deckId, {int limit = 30}) async {
    try {
      final response = await _dio.get(
        ApiConstants.due,
        queryParameters: {
          'deckId': deckId,
          'limit': limit,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => WordCard.fromJson(json)).toList();
      }
      throw Exception('Failed to load due words');
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  @override
  Future<void> submitReview(ReviewRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.review,
        data: request.toJson(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  @override
  Future<List<WordCard>> getGameWords(int deckId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.game}/$deckId',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => WordCard.fromJson(json)).toList();
      }
      throw Exception('Failed to load game words');
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
