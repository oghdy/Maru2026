import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vocabulary_game_provider.dart';
import '../models/word_category.dart';
import '../widgets/vocabulary_error_view.dart';

class VocabularyGameScreen extends ConsumerStatefulWidget {
  final WordCategory category;
  final int lessonNumber;

  const VocabularyGameScreen({
    super.key,
    required this.category,
    required this.lessonNumber,
  });

  @override
  ConsumerState<VocabularyGameScreen> createState() => _VocabularyGameScreenState();
}

class _VocabularyGameScreenState extends ConsumerState<VocabularyGameScreen> {
  // 오답 흔들림은 타일별 _ShakeAnimatedWidget 이 처리한다.

  @override
  Widget build(BuildContext context) {
    final param = GameParam(deckId: widget.category.id, lessonNumber: widget.lessonNumber);
    final gameState = ref.watch(vocabularyGameProvider(param));
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.category.title} - Lesson ${widget.lessonNumber}', 
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('Match Madness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (gameState.totalRounds > 0 && !gameState.isGameOver)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Round ${gameState.round + 1}/${gameState.totalRounds}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                ),
              ),
            ),
          )
        ],
      ),
      body: gameState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : gameState.errorMessage != null
              ? VocabularyErrorView(
                  message: gameState.errorMessage!,
                  onRetry: () => ref.read(vocabularyGameProvider(param).notifier).startGame(),
                )
              : _buildGameContent(context, gameState, param),
    );
  }

  Widget _buildGameContent(BuildContext context, VocabularyGameState state, GameParam param) {
    if (state.isGameOver) {
      return _buildGameOverView(state, param);
    }

    if (state.totalPairs == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'There are no words in this lesson yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // 상단 프로그레스 바
        LinearProgressIndicator(
          value: state.totalMatches / state.totalPairs,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(primary),
          minHeight: 6,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Row(
              children: [
                // 왼쪽: 영어
                Expanded(
                  child: Column(
                    children: List.generate(state.leftTiles.length, (index) {
                      final tile = state.leftTiles[index];
                      final isSelected = state.selectedLeftIndex == index;
                      
                      // 진짜 오답일 때만 빨간색이 나오도록 수정
                      bool isActuallyError = false;
                      if (isSelected && state.isProcessing && 
                          state.selectedLeftIndex != null && state.selectedRightIndex != null) {
                        final leftId = state.leftTiles[state.selectedLeftIndex!].pairId;
                        final rightId = state.rightTiles[state.selectedRightIndex!].pairId;
                        isActuallyError = leftId != rightId;
                      }

                      return _buildAnimatedTile(
                        text: tile.text,
                        isMatched: tile.isMatched,
                        isSelected: isSelected,
                        onTap: () => ref.read(vocabularyGameProvider(param).notifier).selectLeft(index),
                        isError: isActuallyError,
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 20),
                // 오른쪽: 한국어
                Expanded(
                  child: Column(
                    children: List.generate(state.rightTiles.length, (index) {
                      final tile = state.rightTiles[index];
                      final isSelected = state.selectedRightIndex == index;

                      // 진짜 오답일 때만 빨간색이 나오도록 수정
                      bool isActuallyError = false;
                      if (isSelected && state.isProcessing && 
                          state.selectedLeftIndex != null && state.selectedRightIndex != null) {
                        final leftId = state.leftTiles[state.selectedLeftIndex!].pairId;
                        final rightId = state.rightTiles[state.selectedRightIndex!].pairId;
                        isActuallyError = leftId != rightId;
                      }

                      return _buildAnimatedTile(
                        text: tile.text,
                        isMatched: tile.isMatched,
                        isSelected: isSelected,
                        onTap: () => ref.read(vocabularyGameProvider(param).notifier).selectRight(index),
                        isError: isActuallyError,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTile({
    required String text,
    required bool isMatched,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isError,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isMatched ? 0.0 : 1.0,
          curve: Curves.easeIn,
          child: IgnorePointer(
            ignoring: isMatched,
            child: _ShakeAnimatedWidget(
              enabled: isError,
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: isMatched ? 1.15 : (isSelected ? 1.05 : 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isError 
                          ? const Color(0xFFFFEBEE) // 오답 시 연한 빨강 배경
                          : (isMatched 
                              ? const Color(0xFF4CAF50) // 정답 시 초록
                              : (isSelected ? Theme.of(context).colorScheme.primary : Colors.white)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isError
                              ? Colors.red.withValues(alpha: 0.2)
                              : (isMatched
                                  ? Colors.green.withValues(alpha: 0.4)
                                  : (isSelected
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.05))),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isError 
                            ? Colors.red // 오답 시 빨간 테두리
                            : (isMatched ? Colors.green : (isSelected ? Colors.white : Colors.grey.withValues(alpha: 0.1))),
                        width: 2.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (isSelected || isMatched) ? Colors.white : (isError ? Colors.red : Colors.black87),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverView(VocabularyGameState state, GameParam param) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          const Text(
            'Amazing Match!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('You matched all ${state.totalPairs} words in Lesson ${widget.lessonNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => ref.read(vocabularyGameProvider(param).notifier).startGame(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
            child: const Text('Play Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Finish', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// 오답 시 흔들림 애니메이션 위젯
class _ShakeAnimatedWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _ShakeAnimatedWidget({required this.child, required this.enabled});

  @override
  State<_ShakeAnimatedWidget> createState() => _ShakeAnimatedWidgetState();
}

class _ShakeAnimatedWidgetState extends State<_ShakeAnimatedWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_ShakeAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double offset = sin(_controller.value * pi * 4.0) * 6.0;
        return Transform.translate(
          offset: Offset(widget.enabled ? offset : 0, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
