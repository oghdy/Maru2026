import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocabulary_game_tile.dart';
import '../repository/vocabulary_errors.dart';
import '../repository/vocabulary_repository.dart';
import 'vocabulary_provider.dart';

class VocabularyGameState {
  final List<VocabularyGameTile> allTiles;
  final List<VocabularyGameTile> leftTiles;
  final List<VocabularyGameTile> rightTiles;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedLeftIndex;
  final int? selectedRightIndex;
  final bool isProcessing;
  final int round;
  final int totalMatches;
  /// 틀린 시도 수 (완료 화면 정확도용)
  final int mistakes;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  VocabularyGameState({
    this.allTiles = const [],
    this.leftTiles = const [],
    this.rightTiles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedLeftIndex,
    this.selectedRightIndex,
    this.isProcessing = false,
    this.round = 0,
    this.totalMatches = 0,
    this.mistakes = 0,
    this.startedAt,
    this.finishedAt,
  });

  VocabularyGameState copyWith({
    List<VocabularyGameTile>? allTiles,
    List<VocabularyGameTile>? leftTiles,
    List<VocabularyGameTile>? rightTiles,
    bool? isLoading,
    String? errorMessage,
    int? selectedLeftIndex,
    int? selectedRightIndex,
    bool? isProcessing,
    int? round,
    int? totalMatches,
    int? mistakes,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return VocabularyGameState(
      allTiles: allTiles ?? this.allTiles,
      leftTiles: leftTiles ?? this.leftTiles,
      rightTiles: rightTiles ?? this.rightTiles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedLeftIndex: selectedLeftIndex ?? this.selectedLeftIndex,
      selectedRightIndex: selectedRightIndex ?? this.selectedRightIndex,
      isProcessing: isProcessing ?? this.isProcessing,
      round: round ?? this.round,
      totalMatches: totalMatches ?? this.totalMatches,
      mistakes: mistakes ?? this.mistakes,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  // 선택 해제를 명시적으로 하기 위한 특별한 메서드
  VocabularyGameState clearSelections() {
    return VocabularyGameState(
      allTiles: allTiles,
      leftTiles: leftTiles,
      rightTiles: rightTiles,
      isLoading: isLoading,
      errorMessage: errorMessage,
      selectedLeftIndex: null,
      selectedRightIndex: null,
      isProcessing: isProcessing,
      round: round,
      totalMatches: totalMatches,
      mistakes: mistakes,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
  }

  static const int pairsPerRound = 5;

  /// 이 레슨에서 실제로 받은 단어(쌍) 수 — 30 고정이 아니라 서버 응답 기준.
  int get totalPairs => allTiles.map((t) => t.pairId).toSet().length;
  int get totalRounds => (totalPairs / pairsPerRound).ceil();

  bool get isRoundOver => leftTiles.isEmpty || leftTiles.every((t) => t.isMatched);
  bool get isGameOver => totalPairs > 0 && totalMatches >= totalPairs;

  /// 정확도 = 맞힌 짝 / 전체 시도 (틀린 시도 포함)
  double get accuracy => totalMatches == 0 ? 0 : totalMatches / (totalMatches + mistakes);
  Duration get elapsed => (finishedAt ?? DateTime.now()).difference(startedAt ?? DateTime.now());
}

class GameParam {
  final int deckId;
  final int lessonNumber;
  GameParam({required this.deckId, required this.lessonNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameParam &&
          runtimeType == other.runtimeType &&
          deckId == other.deckId &&
          lessonNumber == other.lessonNumber;

  @override
  int get hashCode => deckId.hashCode ^ lessonNumber.hashCode;
}

class VocabularyGameNotifier extends Notifier<VocabularyGameState> {
  final GameParam arg;
  VocabularyGameNotifier(this.arg);

  @override
  VocabularyGameState build() {
    Future.microtask(() => startGame());
    return VocabularyGameState();
  }

  VocabularyRepository get _repository => ref.read(vocabularyRepositoryProvider);

  Future<void> startGame() async {
    // copyWith 로는 errorMessage 를 null 로 못 되돌리므로 새 상태로 시작 (Retry 대비)
    state = VocabularyGameState(isLoading: true);
    try {
      final tiles = await _repository.getGameTiles(arg.deckId, lessonNumber: arg.lessonNumber);
      if (!ref.mounted) return;
      state = state.copyWith(allTiles: tiles, isLoading: false, startedAt: DateTime.now());
      _setupRound(0);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: friendlyVocabularyError(e));
    }
  }

  void _setupRound(int round) {
    final allTiles = state.allTiles;
    if (allTiles.isEmpty) return;

    // 1. 모든 타일을 pairId별로 그룹화 (Map<pairId, List<Tile>>)
    final Map<int, List<VocabularyGameTile>> pairGroups = {};
    for (var tile in allTiles) {
      pairGroups.putIfAbsent(tile.pairId, () => []).add(tile);
    }

    // 2. 그룹화된 쌍들 리스트로 변환 (레슨마다 개수가 다름)
    final List<int> pairIds = pairGroups.keys.toList();
    
    // 3. 현재 라운드에 해당하는 최대 5개의 pairId 추출
    final int start = round * VocabularyGameState.pairsPerRound;
    if (start >= pairIds.length) return;

    final int end = min(start + VocabularyGameState.pairsPerRound, pairIds.length);
    final currentPairIds = pairIds.sublist(start, end);

    // 4. 각 pairId에서 영어는 왼쪽, 한국어는 오른쪽으로 분리
    final List<VocabularyGameTile> left = [];
    final List<VocabularyGameTile> right = [];

    for (var pid in currentPairIds) {
      final group = pairGroups[pid]!;
      final enTile = group.firstWhere((t) => t.type == 'ENGLISH', orElse: () => group.first);
      final krTile = group.firstWhere((t) => t.type == 'KOREAN', orElse: () => group.last);
      left.add(enTile);
      right.add(krTile);
    }

    // 5. 각각 셔플하여 순서 뒤섞기
    left.shuffle();
    right.shuffle();

    state = state.copyWith(
      leftTiles: left,
      rightTiles: right,
      isLoading: false,
      round: round,
      selectedLeftIndex: null,
      selectedRightIndex: null,
      isProcessing: false,
    );
  }

  void selectLeft(int index) {
    if (state.isProcessing || state.leftTiles[index].isMatched) return;
    state = state.copyWith(selectedLeftIndex: index);
    _checkMatch();
  }

  void selectRight(int index) {
    if (state.isProcessing || state.rightTiles[index].isMatched) return;
    state = state.copyWith(selectedRightIndex: index);
    _checkMatch();
  }

  Future<void> _checkMatch() async {
    if (state.selectedLeftIndex == null || state.selectedRightIndex == null) return;

    // 판정 시작: 클릭 방지
    state = state.copyWith(isProcessing: true);

    final leftTile = state.leftTiles[state.selectedLeftIndex!];
    final rightTile = state.rightTiles[state.selectedRightIndex!];

    if (leftTile.pairId == rightTile.pairId) {
      // 1. 정답: 바로 matched 처리 → 타일이 스스로 초록 pop 후 사라지는 애니메이션(VOC-1.5.2).
      //    (이전: 0.3초 동안 보드 전체를 잠가서 연속 매칭이 끊겨 보였음)
      final newLeft = List<VocabularyGameTile>.from(state.leftTiles);
      final newRight = List<VocabularyGameTile>.from(state.rightTiles);
      newLeft[state.selectedLeftIndex!] = newLeft[state.selectedLeftIndex!].copyWith(isMatched: true);
      newRight[state.selectedRightIndex!] = newRight[state.selectedRightIndex!].copyWith(isMatched: true);

      state = state.clearSelections().copyWith(
        leftTiles: newLeft,
        rightTiles: newRight,
        isProcessing: false,
        totalMatches: state.totalMatches + 1,
      );

      if (state.isGameOver) {
        // 마지막 짝이 사라지는 애니메이션을 보여준 뒤 완료 화면
        await Future.delayed(const Duration(milliseconds: 450));
        if (!ref.mounted) return;
        state = state.copyWith(finishedAt: DateTime.now());
      }

      // 라운드 종료 체크 (pop-out 애니메이션이 끝난 뒤 다음 라운드)
      if (state.isRoundOver && !state.isGameOver) {
        await Future.delayed(const Duration(milliseconds: 450));
        if (!ref.mounted) return;
        _setupRound(state.round + 1);
      }
    } else {
      // 2. 오답: 흔들림 애니메이션(약 0.45초)을 보여준 뒤 선택 해제
      state = state.copyWith(mistakes: state.mistakes + 1);
      await Future.delayed(const Duration(milliseconds: 450));
      if (!ref.mounted) return;

      state = state.clearSelections().copyWith(isProcessing: false);
    }
  }
}

// autoDispose: 화면을 나가면 게임 상태를 버리고, 다시 들어오면 새 게임으로 시작
final vocabularyGameProvider = NotifierProvider.autoDispose.family<VocabularyGameNotifier, VocabularyGameState, GameParam>((param) {
  return VocabularyGameNotifier(param);
});
