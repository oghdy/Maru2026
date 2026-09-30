import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocabulary_game_tile.dart';
import '../providers/vocabulary_game_provider.dart';
import '../models/word_category.dart';
import '../widgets/vocab_style.dart';
import '../widgets/vocabulary_error_view.dart';

/// Match Madness (VOC-1.5.2): 타일 순차 등장, 선택 scale/색 전환, 정답 pop+fade, 오답 감쇠 shake,
/// 라운드 전환 트랜지션, 완료 축하(컨페티). 모두 Flutter 기본 애니메이션.
class VocabularyGameScreen extends ConsumerWidget {
  final WordCategory category;
  final int lessonNumber;

  const VocabularyGameScreen({
    super.key,
    required this.category,
    required this.lessonNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final param = GameParam(deckId: category.id, lessonNumber: lessonNumber);
    final state = ref.watch(vocabularyGameProvider(param));
    final colorScheme = Theme.of(context).colorScheme;
    final accent = gameAccent(context);
    final finished = state.finishedAt != null;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Match Madness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '${category.title} · Lesson $lessonNumber',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (state.totalRounds > 0 && !finished)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Container(
                    key: ValueKey(state.round),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Round ${state.round + 1}/${state.totalRounds}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? VocabularyErrorView(
                  message: state.errorMessage!,
                  onRetry: () => ref.read(vocabularyGameProvider(param).notifier).startGame(),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  child: finished
                      ? _GameOverView(
                          key: const ValueKey('over'),
                          state: state,
                          lessonNumber: lessonNumber,
                          onPlayAgain: () => ref.read(vocabularyGameProvider(param).notifier).startGame(),
                        )
                      : _Board(key: const ValueKey('board'), state: state, param: param),
                ),
    );
  }
}

class _Board extends ConsumerWidget {
  final VocabularyGameState state;
  final GameParam param;

  const _Board({super.key, required this.state, required this.param});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = gameAccent(context);

    if (state.totalPairs == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'There are no words in this lesson yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ),
      );
    }

    // 판정 중인 두 타일이 같은 짝인지 (오답 빨강 표시용)
    bool? verdict;
    if (state.isProcessing && state.selectedLeftIndex != null && state.selectedRightIndex != null) {
      verdict = state.leftTiles[state.selectedLeftIndex!].pairId == state.rightTiles[state.selectedRightIndex!].pairId;
    }
    final notifier = ref.read(vocabularyGameProvider(param).notifier);

    Widget column(List<VocabularyGameTile> tiles, int? selected, void Function(int) onTap, int offset) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < tiles.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _MatchTile(
                // 라운드가 바뀌면 새 위젯 → 등장 애니메이션 재생
                key: ValueKey('${state.round}_${tiles[i].id}'),
                text: tiles[i].text,
                isKorean: tiles[i].type == 'KOREAN',
                entranceIndex: i * 2 + offset,
                isSelected: selected == i,
                isMatched: tiles[i].isMatched,
                isWrong: selected == i && verdict == false,
                onTap: () => onTap(i),
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: state.totalMatches / state.totalPairs),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${state.totalMatches}/${state.totalPairs}',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap an English word, then its Korean match',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: column(state.leftTiles, state.selectedLeftIndex, notifier.selectLeft, 0)),
                  const SizedBox(width: 14),
                  Expanded(child: column(state.rightTiles, state.selectedRightIndex, notifier.selectRight, 1)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchTile extends StatefulWidget {
  final String text;
  final bool isKorean;
  final int entranceIndex;
  final bool isSelected;
  final bool isMatched;
  final bool isWrong;
  final VoidCallback onTap;

  const _MatchTile({
    super.key,
    required this.text,
    required this.isKorean,
    required this.entranceIndex,
    required this.isSelected,
    required this.isMatched,
    required this.isWrong,
    required this.onTap,
  });

  @override
  State<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<_MatchTile> with TickerProviderStateMixin {
  // 등장: 순차 pop-in
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  // 오답: 감쇠 흔들림
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  // 정답: 초록 pop → 줄어들며 사라짐
  late final AnimationController _match = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * widget.entranceIndex), () {
      if (mounted) _enter.forward();
    });
    if (widget.isMatched) _match.value = 1;
  }

  @override
  void didUpdateWidget(_MatchTile old) {
    super.didUpdateWidget(old);
    if (widget.isWrong && !old.isWrong) {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
    if (widget.isMatched && !old.isMatched) {
      HapticFeedback.lightImpact();
      _match.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _shake.dispose();
    _match.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = gameAccent(context);
    const success = Color(0xFF2E9E5B);

    final Color bg;
    final Color border;
    final Color fg;
    if (widget.isMatched) {
      bg = success;
      border = success;
      fg = Colors.white;
    } else if (widget.isWrong) {
      bg = colorScheme.errorContainer;
      border = colorScheme.error;
      fg = colorScheme.onErrorContainer;
    } else if (widget.isSelected) {
      bg = accent;
      border = accent;
      fg = Colors.white;
    } else {
      bg = colorScheme.surfaceContainerLowest;
      border = colorScheme.outlineVariant.withValues(alpha: 0.5);
      fg = colorScheme.onSurface;
    }
    final lifted = widget.isSelected || widget.isMatched;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 68,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: (lifted ? bg : Colors.black).withValues(alpha: lifted ? 0.35 : 0.05),
            blurRadius: widget.isSelected ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: widget.isKorean ? 19 : 15,
          height: 1.2,
        ),
      ),
    );

    return IgnorePointer(
      ignoring: widget.isMatched,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_enter, _shake, _match]),
          child: AnimatedScale(
            scale: widget.isSelected && !widget.isMatched ? 1.05 : 1,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            child: tile,
          ),
          builder: (context, child) {
            final enter = Curves.easeOutBack.transform(_enter.value);
            // 감쇠 사인: 처음에 크게, 점점 잦아듦
            final s = _shake.value;
            final dx = sin(s * pi * 5) * 10 * (1 - s);
            // 정답: 0~35% 구간 1 → 1.12 pop, 이후 0.6 까지 줄며 투명
            final m = _match.value;
            final double matchScale;
            final double matchOpacity;
            if (m < 0.35) {
              matchScale = 1 + 0.12 * Curves.easeOut.transform(m / 0.35);
              matchOpacity = 1;
            } else {
              final t = Curves.easeIn.transform((m - 0.35) / 0.65);
              matchScale = 1.12 - 0.52 * t;
              matchOpacity = 1 - t;
            }
            return Opacity(
              opacity: _enter.value.clamp(0.0, 1.0) * matchOpacity,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.scale(scale: (0.7 + 0.3 * enter) * matchScale, child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameOverView extends StatefulWidget {
  final VocabularyGameState state;
  final int lessonNumber;
  final VoidCallback onPlayAgain;

  const _GameOverView({super.key, required this.state, required this.lessonNumber, required this.onPlayAgain});

  @override
  State<_GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<_GameOverView> with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _particles = List.generate(60, (_) => _Particle.random(rnd));
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = gameAccent(context);
    final state = widget.state;
    final colors = [colorScheme.primary, accent, Colors.amber, const Color(0xFF2E9E5B), Colors.lightBlue];

    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.2, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withValues(alpha: 0.18)),
                    child: Icon(Icons.emoji_events_rounded, size: 68, color: Colors.amber.shade700),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  state.mistakes == 0 ? 'Perfect Match!' : 'Amazing Match!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'You matched all ${state.totalPairs} words in Lesson ${widget.lessonNumber}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _Stat(label: 'Time', value: _formatDuration(state.elapsed)),
                    const SizedBox(width: 10),
                    _Stat(label: 'Mistakes', value: '${state.mistakes}'),
                    const SizedBox(width: 10),
                    _Stat(label: 'Accuracy', value: '${(state.accuracy * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 240,
                  child: FilledButton.icon(
                    onPressed: widget.onPlayAgain,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Play Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Finish', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
        // 컨페티: 입력을 막지 않도록 IgnorePointer, 한 번 쏟아지고 끝
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ConfettiPainter(_confetti, _particles, colors),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x; // 시작 x (0~1)
  final double vx; // 좌우 흔들림 폭
  final double speed; // 낙하 속도 배율
  final double size;
  final double spin;
  final double delay; // 0~0.3
  final int colorIndex;

  _Particle(this.x, this.vx, this.speed, this.size, this.spin, this.delay, this.colorIndex);

  factory _Particle.random(Random r) => _Particle(
        r.nextDouble(),
        (r.nextDouble() - 0.5) * 0.25,
        0.7 + r.nextDouble() * 0.6,
        6 + r.nextDouble() * 6,
        (r.nextDouble() - 0.5) * 12,
        r.nextDouble() * 0.3,
        r.nextInt(5),
      );
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> progress;
  final List<_Particle> particles;
  final List<Color> colors;

  _ConfettiPainter(this.progress, this.particles, this.colors) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = ((progress.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final y = -20 + (size.height + 40) * t * t * p.speed; // 중력처럼 가속
      final x = size.width * (p.x + p.vx * sin(t * pi * 3));
      paint.color = colors[p.colorIndex].withValues(alpha: 1 - t * 0.6);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
