import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vocabulary_game_provider.dart';
import '../models/word_category.dart';

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

class _VocabularyGameScreenState extends ConsumerState<VocabularyGameScreen> with TickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final param = GameParam(deckId: widget.category.id, lessonNumber: widget.lessonNumber);
    final gameState = ref.watch(vocabularyGameProvider(param));

    // 오답 시 흔들림 트리거 (Notifier에서 에러 상태일 때 처리하도록 로직이 보강될 수 있음)
    // 현재는 로직 흐름상 정답이 아닐 때 Notifier가 isProcessing을 풀기 전에 처리하도록 유도

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
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Round ${gameState.round + 1}/6',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                ),
              ),
            ),
          )
        ],
      ),
      body: gameState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : gameState.errorMessage != null
              ? Center(child: Text('Error: ${gameState.errorMessage}'))
              : _buildGameContent(context, gameState, param),
    );
  }

  Widget _buildGameContent(BuildContext context, VocabularyGameState state, GameParam param) {
    if (state.isGameOver) {
      return _buildGameOverView(state, param);
    }

    return Column(
      children: [
        // 상단 프로그레스 바
        LinearProgressIndicator(
          value: state.totalMatches / 30,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
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
                              : (isSelected ? const Color(0xFF6C63FF) : Colors.white)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isError
                              ? Colors.red.withOpacity(0.2)
                              : (isMatched 
                                  ? Colors.green.withOpacity(0.4)
                                  : (isSelected ? const Color(0xFF6C63FF).withOpacity(0.3) : Colors.black.withOpacity(0.05))),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isError 
                            ? Colors.red // 오답 시 빨간 테두리
                            : (isMatched ? Colors.green : (isSelected ? Colors.white : Colors.grey.withOpacity(0.1))),
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
          Text('You mastered all 30 words in Lesson ${widget.lessonNumber}', 
            style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => ref.read(vocabularyGameProvider(param).notifier).startGame(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
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
