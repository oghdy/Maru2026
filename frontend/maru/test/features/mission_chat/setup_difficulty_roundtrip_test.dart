import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/mission_chat/models/mission_clearance_model.dart';
import 'package:maru/features/mission_chat/models/mission_difficulty.dart';
import 'package:maru/features/mission_chat/models/mission_setup_response.dart';

// MSN-1.8.5: the setup echoed back to /chat, /suggestion and /clearance must keep `difficulty`
// (API_CONTRACT 1-8 B) and any other top-level field the model doesn't know.

Map<String, dynamic> _setupJson({Object? difficulty = 'normal', Map<String, dynamic> extra = const {}}) => {
      'persona': {
        'role': '카페 직원',
        'personality': '친절한',
        'speechStyle': '해요체',
        'honorificLevel': 'polite',
        'firstMessage': '안녕하세요!',
        'firstMessageEn': 'Hello!',
      },
      'mission': {
        'title': 'Order a drink',
        'description': 'Order an iced tea.',
        'clearCondition': {'goalCondition': 'Order one drink.', 'languageCondition': 'Use -요.'},
        'minTurns': 3,
      },
      'adjustmentNotice': null,
      if (difficulty != null) 'difficulty': difficulty,
      ...extra,
    };

void main() {
  test('difficulty survives fromJson → toJson', () {
    final setup = MissionSetupResponse.fromJson(_setupJson());
    expect(setup.difficultyLevel, MissionDifficulty.normal);
    expect(setup.toJson()['difficulty'], 'normal');
    expect(setup.toJson()['mission']['minTurns'], 3);
  });

  test('unknown top-level fields are echoed back too', () {
    final setup = MissionSetupResponse.fromJson(_setupJson(extra: {'futureField': {'a': 1}}));
    expect(setup.toJson()['futureField'], {'a': 1});
  });

  test('older servers without difficulty: no badge, no field sent', () {
    final setup = MissionSetupResponse.fromJson(_setupJson(difficulty: null));
    expect(setup.difficultyLevel, isNull);
    expect(setup.toJson().containsKey('difficulty'), isFalse);
  });

  test('clearance difficulty parses, null for old reports', () {
    Map<String, dynamic> c(Object? d) => {
          'missionTitle': 't', 'persona': 'p', 'totalTurns': 3,
          'goodExpressions': [], 'incorrectExpressions': [],
          'turtleComment': '', 'nextPractice': '',
          'difficulty': d,
        };
    expect(MissionClearanceModel.fromJson(c('EASY')).difficulty, MissionDifficulty.easy);
    expect(MissionClearanceModel.fromJson(c(null)).difficulty, isNull);
    expect(MissionClearanceModel.fromJson(c('weird')).difficulty, isNull);
  });
}
