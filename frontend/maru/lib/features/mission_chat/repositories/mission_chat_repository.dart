import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/chat_turn_response.dart';
import '../models/mission_clearance_model.dart';
import '../models/mission_setup_response.dart';
import '../models/chat_message_model.dart';
import '../models/suggestion_response.dart';

final missionChatRepositoryProvider = Provider<MissionChatRepository>((ref) {
  final dio = ref.read(dioProvider);
  return MissionChatRepositoryImpl(dio);
});

abstract class MissionChatRepository {
  Future<MissionSetupResponse> setupMission(Map<String, dynamic> request);
  Future<ChatTurnResponse> sendChat({
    required String userMessage,
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
  });
  Future<MissionClearanceModel> issueClearance({
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
    String? missionStatus,
  });
  Future<List<MissionClearanceModel>> getClearances();
  Future<SuggestionResponse> getSuggestion({
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
  });
}

class MissionChatRepositoryImpl implements MissionChatRepository {
  final Dio _dio;

  MissionChatRepositoryImpl(this._dio);

  @override
  Future<MissionSetupResponse> setupMission(Map<String, dynamic> request) async {
    final response = await _dio.post(
      ApiConstants.missionSetup,
      data: request,
    );
    return MissionSetupResponse.fromJson(response.data['data']);
  }

  @override
  Future<ChatTurnResponse> sendChat({
    required String userMessage,
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
  }) async {
    final response = await _dio.post(
      ApiConstants.missionChat,
      data: {
        'userMessage': userMessage,
        'conversationHistory': history.map((e) => e.toJson()).toList(),
        'setup': setup.toJson(),
      },
    );
    return ChatTurnResponse.fromJson(response.data['data']);
  }

  @override
  Future<MissionClearanceModel> issueClearance({
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
    String? missionStatus,
  }) async {
    final response = await _dio.post(
      ApiConstants.missionClearance,
      data: {
        'conversationHistory': history.map((e) => e.toJson()).toList(),
        'setup': setup.toJson(),
        if (missionStatus != null) 'missionStatus': missionStatus,
      },
    );
    return MissionClearanceModel.fromJson(response.data['data']);
  }

  @override
  Future<List<MissionClearanceModel>> getClearances() async {
    final response = await _dio.get(ApiConstants.missionClearances);
    final data = response.data['data'] as List;
    return data.map((e) => MissionClearanceModel.fromJson(e)).toList();
  }

  @override
  Future<SuggestionResponse> getSuggestion({
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
  }) async {
    final response = await _dio.post(
      ApiConstants.missionSuggestion,
      data: {
        'conversationHistory': history.map((e) => e.toJson()).toList(),
        'setup': setup.toJson(),
      },
    );
    return SuggestionResponse.fromJson(response.data['data']);
  }
}
