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
  late final AnimationController _flipController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  // 앞뒤 전환: 부드러운 ease + 뒤집는 도중 살짝 작아졌다 돌아오는 깊이감
  late final Animation<double> _flip = CurvedAnimation(
    parent: _flipController,
    curve: Curves.easeInOutCubic,
  );
  bool _showFront = true;

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
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(vocabularySessionProvider);
    final isLessonMode = sessionState.reviewMode == "LESSON";
    // 서버 가드: 이미 학습했고 복습일 전인 단어는 Word Study 평가가 반영되지 않음 (VOC-1.3.2)
    final ratingIgnored = isLessonMode && !widget.word.ratingAppliesInLesson;

    // 카드는 남은 공간을 채우고 평가 바는 그 아래에 둔다 (작은 화면에서 겹치지 않도록)
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  min(constraints.maxWidth - 40, 440),
                  constraints.maxHeight * 0.94,
                );
                return GestureDetector(
                  onTap: _toggleCard,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _flip,
                      builder: (context, child) {
                        final t = _flip.value;
                        final angle = t * pi;
                        final isFront = angle < pi / 2;
                        final scale = 1 - 0.06 * sin(t * pi);

                        final flipped = Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
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
                        return Transform.scale(scale: scale, child: flipped);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: ratingIgnored ? _buildAlreadyStudiedBar() : _buildRatingBar(),
            ),
          ),
        ],
      ),
    );
  }

  // 이미 학습한 단어: Word Study 에서는 평가를 저장하지 않으므로(서버 spacing guard) 버튼 대신 다음/완료만 제공.
  // (이전: "Swipe up" 배지만 있어서 마지막 카드가 학습한 단어면 완료 화면에 갈 수 없었음, VOC-1.2.9)
  Widget _buildAlreadyStudiedBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Already learned. It will come back in Daily Review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: widget.onNext,
              icon: Icon(widget.isLast ? Icons.check_rounded : Icons.arrow_downward_rounded),
              label: Text(widget.isLast ? 'Finish' : 'Next word'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardShell({required Size size, required Widget child, required Color color, Border? border}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        border: border,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _posChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFrontCard(Size size) {
    final colorScheme = Theme.of(context).colorScheme;
    return _cardShell(
      size: size,
      color: colorScheme.surfaceContainerLowest,
      child: Stack(
        children: [
          // 상단 브랜드색 띠
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, Color.lerp(colorScheme.primary, Colors.white, 0.45)!],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (widget.word.partOfSpeech != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: _posChip(
                        widget.word.partOfSpeech!,
                        colorScheme.primaryContainer,
                        colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.word.koreanWord,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  IconButton.filledTonal(
                    onPressed: () => TtsHelper.speak(widget.word.koreanWord),
                    iconSize: 28,
                    padding: const EdgeInsets.all(14),
                    icon: const Icon(Icons.volume_up_rounded),
                    tooltip: 'Listen',
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 18, color: colorScheme.outline),
                      const SizedBox(width: 6),
                      Text('Tap to see the meaning', style: TextStyle(color: colorScheme.outline)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Size size) {
    final colorScheme = Theme.of(context).colorScheme;
    final example = widget.word.exampleSentence;
    final translation = widget.word.exampleTranslation?.trim();
    return _cardShell(
      size: size,
      color: colorScheme.surfaceContainerLowest,
      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35), width: 1.5),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.word.koreanWord,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.word.primaryMeaning,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: colorScheme.primary,
                  ),
                ),
                if (widget.word.partOfSpeech != null) ...[
                  const SizedBox(height: 10),
                  _posChip(
                    widget.word.partOfSpeech!,
                    colorScheme.secondaryContainer,
                    colorScheme.onSecondaryContainer,
                  ),
                ],
                if (example != null) ...[
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote_rounded, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Example',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          example,
                          style: TextStyle(fontSize: 18, height: 1.4, color: colorScheme.onSurface),
                        ),
                        if (translation != null && translation.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            translation,
                            style: TextStyle(fontSize: 14, height: 1.4, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How well did you know it?',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ratingButton('Again', Colors.red, ReviewRating.again),
              _ratingButton('Hard', Colors.orange, ReviewRating.hard),
              _ratingButton('Good', Colors.green, ReviewRating.good),
              _ratingButton('Easy', Colors.blue, ReviewRating.easy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratingButton(String label, MaterialColor color, ReviewRating rating) {
    final interval = widget.word.nextIntervals?[rating.name.toUpperCase()];
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => widget.onRate(rating),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color.shade800),
                  ),
                  // 이 버튼을 누르면 다음 복습까지 걸리는 시간 (서버 스케줄러와 같은 계산, VOC-1.3.4)
                  if (interval != null) ...[
                    const SizedBox(height: 2),
                    Text(interval, style: TextStyle(fontSize: 12, color: color.shade700)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
