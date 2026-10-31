import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../../core/utils/tts_helper.dart';
import 'lesson_style.dart';

class _Part {
  final String text;
  final String meaning;
  final bool highlight;

  const _Part(this.text, this.meaning, this.highlight);

  factory _Part.fromJson(Map<String, dynamic> json) => _Part(
        json['text'] as String? ?? '',
        json['meaning'] as String? ?? '',
        json['highlight'] == true,
      );
}

class _Example {
  final String sentence;
  final String translation;
  final bool tts;

  /// Words in sentence order; each word is its parts in order.
  final List<List<_Part>> words;

  const _Example(this.sentence, this.translation, this.tts, this.words);

  static _Example? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final words = (json['words'] as List<dynamic>? ?? [])
        .map((w) => ((w as Map<String, dynamic>)['parts'] as List<dynamic>? ?? [])
            .map((p) => _Part.fromJson(p as Map<String, dynamic>))
            .toList())
        .where((parts) => parts.isNotEmpty)
        .toList();
    final sentence = json['sentence'] as String? ?? '';
    if (words.isEmpty && sentence.isEmpty) return null;
    return _Example(
      sentence,
      json['translation'] as String? ?? '',
      json['tts'] == true,
      words.isNotEmpty ? words : [[_Part(sentence, '', false)]],
    );
  }

  int get gapCount => words.fold(0, (sum, parts) => sum + parts.length - 1);
}

/// One idea on one screen: the character explains it, then the learner taps the example
/// sentence together. Continue opens once it is built, and a card with no example can
/// be continued at once.
class ConceptStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onNext;

  const ConceptStepWidget({super.key, required this.content, required this.onNext});

  @override
  State<ConceptStepWidget> createState() => _ConceptStepWidgetState();
}

class _ConceptStepWidgetState extends State<ConceptStepWidget> {
  late final _Example? _example = _Example.fromJson(widget.content['example']);

  /// Gaps joined so far, left to right. Any tap on the card joins the next one, so a
  /// learner can't get stuck.
  int _joined = 0;
  late bool _assembled = _example == null || widget.content['tap_to_assemble'] != true;
  late final bool _startedAssembled = _assembled;

  @override
  void dispose() {
    TtsHelper.stop();
    super.dispose();
  }

  void _join() {
    if (_assembled) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_joined < _example!.gapCount) _joined++;
      if (_joined >= _example.gapCount) _assembled = true;
    });
  }

  bool _gapJoined(int gap) => _startedAssembled || gap < _joined;

  MaruCharacterKind get _kind =>
      widget.content['character'] == 'rabbit' ? MaruCharacterKind.rabbit : MaruCharacterKind.turtle;

  /// A card with something to build saves the happy face for the moment it is built.
  MaruMood get _mood {
    final name = widget.content['mood'] as String? ?? '';
    final mood = MaruMood.values.where((m) => m.name == name).firstOrNull ?? MaruMood.idle;
    if (_startedAssembled) return mood;
    if (_assembled) return MaruMood.happy;
    return mood == MaruMood.happy ? MaruMood.idle : mood;
  }

  @override
  Widget build(BuildContext context) {
    final example = _example;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            // Room above for the character's jump (0.25 × size)
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MaruCharacterBubble(
                  kind: _kind,
                  mood: _mood,
                  message: widget.content['explanation'] as String? ?? '',
                  size: 72,
                ),
                if (example != null) ...[
                  const SizedBox(height: 16),
                  _exampleCard(example),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: LessonPrimaryButton(label: 'Continue', onPressed: _assembled ? widget.onNext : null),
        ),
      ],
    );
  }

  Widget _exampleCard(_Example example) {
    final waiting = !_assembled;
    final words = <Widget>[];
    var firstGap = 0;
    for (final parts in example.words) {
      words.add(_word(parts, firstGap));
      firstGap += parts.length - 1;
    }

    return Semantics(
      button: waiting,
      label: waiting ? 'Tap to join the blocks of ${example.sentence}' : null,
      child: MouseRegion(
        cursor: waiting ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: waiting ? _join : null,
          child: LessonPressEffect(
            enabled: waiting,
            pressedScale: 0.98,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
              decoration: missionCardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 10,
                    children: words,
                  ),
                  LessonReveal(
                    alignment: Alignment.topCenter,
                    child: waiting ? _hint() : _result(example),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _word(List<_Part> parts, int firstGap) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];
    var joinedHere = 0;
    for (var i = 0; i < parts.length; i++) {
      final joinedLeft = i > 0 && _gapJoined(firstGap + i - 1);
      final joinedRight = i < parts.length - 1 && _gapJoined(firstGap + i);
      if (joinedRight) joinedHere++;
      children.add(_block(parts[i], joinedLeft: joinedLeft, joinedRight: joinedRight));
      if (i < parts.length - 1) {
        children.add(_Collapse(
          open: !joinedRight,
          vertical: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 11, 4, 0),
            child: Text(
              '+',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.primary.withValues(alpha: 0.55)),
            ),
          ),
        ));
      }
    }
    return _Settle(
      trigger: joinedHere,
      // A long word shrinks to fit a narrow card rather than overflowing it
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _block(_Part part, {required bool joinedLeft, required bool joinedRight}) {
    final colors = Theme.of(context).colorScheme;
    const radius = Radius.circular(14);
    final edge = part.highlight ? 3.0 : 1.0; // A joined highlight still keeps a little air
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: lessonMotion(context, 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(joinedLeft ? edge : 12, 8, joinedRight ? edge : 12, 8),
          decoration: BoxDecoration(
            color: part.highlight ? colors.primary : colors.primaryContainer,
            borderRadius: BorderRadius.horizontal(
              left: joinedLeft ? Radius.zero : radius,
              right: joinedRight ? Radius.zero : radius,
            ),
          ),
          child: Text(
            part.text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: part.highlight ? colors.onPrimary : colors.primary,
            ),
          ),
        ),
        // Each loose block says what it means. Joined, it reads as a word again.
        if (part.meaning.isNotEmpty)
          _Collapse(
            open: !_assembled && !joinedLeft && !joinedRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                part.meaning,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: part.highlight ? FontWeight.w800 : FontWeight.w600,
                  color: part.highlight ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hint() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey('concept_hint'),
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Tap to join the blocks',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _result(_Example example) {
    final colors = Theme.of(context).colorScheme;
    final highlights = [
      for (final parts in example.words)
        for (final part in parts)
          if (part.highlight && part.meaning.isNotEmpty) part,
    ];
    return Padding(
      key: const ValueKey('concept_result'),
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  example.translation,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w700, color: colors.onSurface),
                ),
              ),
              if (example.tts) ...[
                const SizedBox(width: 10),
                // TTS gets the sentence as written, with no display marks
                LessonSpeakerButton(size: 44, onPressed: () => TtsHelper.speak(example.sentence)),
              ],
            ],
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final part in highlights)
                  MissionPill(
                    label: '${part.text} = ${part.meaning}',
                    background: colors.primaryContainer,
                    foreground: colors.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Smoothly closes its child to nothing. Works with a zero duration too, unlike AnimatedSize.
class _Collapse extends StatelessWidget {
  final bool open;
  final bool vertical;
  final Widget child;

  const _Collapse({required this.open, required this.child, this.vertical = true});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: open ? 1 : 0),
      duration: lessonMotion(context, 220),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          widthFactor: v,
          heightFactor: vertical ? v : 1,
          child: Opacity(opacity: v, child: child),
        ),
      ),
      child: child,
    );
  }
}

/// A small pop each time [trigger] goes up: two blocks have just clicked together.
class _Settle extends StatefulWidget {
  final int trigger;
  final Widget child;

  const _Settle({required this.trigger, required this.child});

  @override
  State<_Settle> createState() => _SettleState();
}

class _SettleState extends State<_Settle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  @override
  void didUpdateWidget(_Settle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger && !lessonReduceMotion(context)) {
      _controller.forward(from: 0);
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
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.06 * math.sin(math.pi * _controller.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}
