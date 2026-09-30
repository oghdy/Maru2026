import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocabulary_game_tile.dart';
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
    );
  }

  static const int pairsPerRound = 5;

  /// 이 레슨에서 실제로 받은 단어(쌍) 수 — 30 고정이 아니라 서버 응답 기준.
  int get totalPairs => allTiles.map((t) => t.pairId).toSet().length;
  int get totalRounds => (totalPairs / pairsPerRound).ceil();

  bool get isRoundOver => leftTiles.isEmpty || leftTiles.every((t) => t.isMatched);
  bool get isGameOver => totalPairs > 0 && totalMatches >= totalPairs;
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
      state = state.copyWith(allTiles: tiles, isLoading: false);
      _setupRound(0);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
      // 1. 정답인 경우: 0.3초간 정답 상태(보라색 유지)를 보여줌
      await Future.delayed(const Duration(milliseconds: 300));
      if (!ref.mounted) return;

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

      // 라운드 종료 체크
      if (state.isRoundOver && !state.isGameOver) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!ref.mounted) return;
        _setupRound(state.round + 1);
      }
    } else {
      // 2. 오답인 경우: UI에서 흔들림 애니메이션이 일어날 시간을 줌
      await Future.delayed(const Duration(milliseconds: 500));
      if (!ref.mounted) return;

      state = state.clearSelections().copyWith(isProcessing: false);
    }
  }
}

// autoDispose: 화면을 나가면 게임 상태를 버리고, 다시 들어오면 새 게임으로 시작
final vocabularyGameProvider = NotifierProvider.autoDispose.family<VocabularyGameNotifier, VocabularyGameState, GameParam>((param) {
  return VocabularyGameNotifier(param);
});
