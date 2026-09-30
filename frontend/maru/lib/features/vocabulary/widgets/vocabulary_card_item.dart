import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word_card.dart';
import '../models/review_request.dart';
import '../providers/vocabulary_provider.dart';
import '../../../../core/utils/tts_helper.dart';

class VocabularyCardItem extends ConsumerStatefulWidget {
  final WordCard word;
  final bool isLast;
  final ValueChanged<ReviewRating> onRate;
  final VoidCallback onNext;

  const VocabularyCardItem({
    super.key,
    required this.word,
    required this.isLast,
    required this.onRate,
    required this.onNext,
  });

  @override
  ConsumerState<VocabularyCardItem> createState() => _VocabularyCardItemState();
}

class _VocabularyCardItemState extends ConsumerState<VocabularyCardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(_flipController);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(vocabularySessionProvider);
    final isLessonMode = sessionState.reviewMode == "LESSON";
    final isAlreadyStudied = widget.word.state != FsrsState.newCard;

    // 카드는 남은 공간을 채우고 평가 바는 그 아래에 둔다 (작은 화면에서 겹치지 않도록)
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  min(constraints.maxWidth * 0.85, 440),
                  constraints.maxHeight * 0.92,
                );
                return GestureDetector(
                  onTap: _toggleCard,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value;
                        final isFront = angle < pi / 2;

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: isFront
                              ? _buildFrontCard(size)
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(pi),
                                  child: _buildBackCard(size),
                                ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: (isLessonMode && isAlreadyStudied)
                ? _buildAlreadyStudiedBar()
                : _buildRatingBar(),
          ),
        ],
      ),
    );
  }

  // 이미 학습한 단어: Word Study 에서는 평가를 저장하지 않으므로(서버 spacing guard) 버튼 대신 다음/완료만 제공.
  // (이전: "Swipe up" 배지만 있어서 마지막 카드가 학습한 단어면 완료 화면에 갈 수 없었음, VOC-1.2.9)
  Widget _buildAlreadyStudiedBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Already learned. It will come back in Daily Review.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onNext,
              icon: Icon(widget.isLast ? Icons.check : Icons.arrow_downward),
              label: Text(widget.isLast ? 'Finish' : 'Next word'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(Size size) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.word.koreanWord,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            onPressed: () => TtsHelper.speak(widget.word.koreanWord),
            icon: Icon(Icons.volume_up, size: 32, color: colorScheme.primary),
          ),
          const SizedBox(height: 40),
          const Text(
            'Tap to reveal meaning',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Size size) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.word.primaryMeaning,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              if (widget.word.partOfSpeech != null) ...[
                const SizedBox(height: 8),
                Text(
                  '[${widget.word.partOfSpeech}]',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
              const SizedBox(height: 32),
              if (widget.word.exampleSentence != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  widget.word.exampleSentence!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.word.exampleTranslation ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ratingButton('Again', Colors.red, ReviewRating.again),
          _ratingButton('Hard', Colors.orange, ReviewRating.hard),
          _ratingButton('Good', Colors.green, ReviewRating.good),
          _ratingButton('Easy', Colors.blue, ReviewRating.easy),
        ],
      ),
    );
  }

  Widget _ratingButton(String label, Color color, ReviewRating rating) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => widget.onRate(rating),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
