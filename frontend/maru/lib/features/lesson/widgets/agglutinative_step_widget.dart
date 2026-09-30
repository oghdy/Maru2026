import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../models/agglutinative_quiz_model.dart';

class AgglutinativeStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onNext;

  /// Reports first-attempt results (correct, total) — one point per phase (🐰, 🐢).
  final void Function(int correct, int total)? onScore;

  const AgglutinativeStepWidget({
    super.key,
    required this.content,
    required this.onNext,
    this.onScore,
  });

  @override
  State<AgglutinativeStepWidget> createState() => _AgglutinativeStepWidgetState();
}

class _AgglutinativeStepWidgetState extends State<AgglutinativeStepWidget>
    with SingleTickerProviderStateMixin {
  ColorScheme get cs => Theme.of(context).colorScheme;

  late AgglutinativeQuizData data;

  // Phase 1 = Rabbit (chunk), Phase 2 = Turtle (morpheme)
  bool isTurtleMode = false;
  bool _rabbitPhaseComplete = false;

  Map<String, AgglutinativeOption?> droppedAnswers = {};

  // Inline feedback shown above the Check button (snackbars used to cover it)
  String? _feedback;
  bool _feedbackIsError = false;

  // Who says the feedback (display only): 🐰 praises the chunk phase, 🐢 coaches
  // the morpheme phase and every wrong answer. The sequence number re-keys the
  // bubble so the same message types out again on a repeated attempt.
  MaruCharacterKind _speaker = MaruCharacterKind.rabbit;
  int _feedbackSeq = 0;
  String? _turtleIntro; // 🐢 line shown after 🐰's praise finishes typing
  Timer? _handOverTimer;

  void _say(String message, {required MaruCharacterKind speaker, bool isError = false}) {
    _feedback = message;
    _feedbackIsError = isError;
    _speaker = speaker;
    _feedbackSeq++;
  }

  late AnimationController _phaseTransitionController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    data = AgglutinativeQuizData.fromJson(widget.content);
    _phaseTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _phaseTransitionController,
      curve: Curves.easeInOut,
    );
    _phaseTransitionController.forward();
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Load both characters' faces up front so 🐰 isn't blank on its first line
      MaruCharacter.precache(context, MaruCharacterKind.rabbit);
      MaruCharacter.precache(context, MaruCharacterKind.turtle);
    }
  }

  @override
  void dispose() {
    _handOverTimer?.cancel();
    _phaseTransitionController.dispose();
    super.dispose();
  }

  bool _isAnswerCorrect() {
    for (var element in data.elements) {
      if (element.isTarget) {
        if (!isTurtleMode) {
          final dropped = droppedAnswers[element.id];
          if (dropped == null || !element.correctRabbit.contains(dropped.text)) {
            return false;
          }
        } else {
          for (int i = 0; i < element.correctTurtle.length; i++) {
            final dropped = droppedAnswers['${element.id}_$i'];
            if (dropped == null || element.correctTurtle[i] != dropped.text) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  bool _isAllSlotsFilled() {
    for (var element in data.elements) {
      if (element.isTarget) {
        if (!isTurtleMode) {
          if (!droppedAnswers.containsKey(element.id) || droppedAnswers[element.id] == null) {
            return false;
          }
        } else {
          for (int i = 0; i < element.correctTurtle.length; i++) {
            if (!droppedAnswers.containsKey('${element.id}_$i') ||
                droppedAnswers['${element.id}_$i'] == null) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  /// A chunk that the lesson does not split (its 🐢 answer is the chunk itself,
  /// e.g. '저는' in a 이에요/예요 lesson). Shown as a fixed block in the 🐢 phase so
  /// only the lesson's target part has to be taken apart.
  bool _staysWhole(AgglutinativeElement el) =>
      el.correctTurtle.length == 1 && el.correctRabbit.contains(el.correctTurtle.first);

  /// Pre-places whole chunks for the 🐢 phase. Options are tracked by `id`, so
  /// two options with the same text (a morpheme needed twice) stay independent.
  void _prefillWholeChunks() {
    for (final el in data.elements.where((e) => e.isTarget && _staysWhole(e))) {
      final used = droppedAnswers.values.map((o) => o?.id).toSet();
      final match = data.options.where(
        (o) => o.mode == 'turtle' && o.text == el.correctTurtle.first && !used.contains(o.id),
      );
      droppedAnswers['${el.id}_0'] = match.isNotEmpty
          ? match.first
          : AgglutinativeOption(id: 'whole_${el.id}', text: el.correctTurtle.first, mode: 'turtle');
    }
  }

  bool get _hasWholeChunks => data.elements.any((e) => e.isTarget && _staysWhole(e));

  // First Check result per phase: false = rabbit, true = turtle
  final Map<bool, bool> _firstTry = {};

  void _onCheckPressed() {
    _firstTry.putIfAbsent(isTurtleMode, () => _isAnswerCorrect());
    if (_isAnswerCorrect()) {
      if (!isTurtleMode) {
        // Phase 1 complete → auto-advance to Turtle mode
        _phaseTransitionController.reverse().then((_) {
          if (!mounted) return;
          setState(() {
            _rabbitPhaseComplete = true;
            isTurtleMode = true;
            droppedAnswers.clear();
            _prefillWholeChunks();
            // 🐰 praises the chunks, then hands over to 🐢 for the split (see onTypingDone)
            _say('Great! You built the sentence.', speaker: MaruCharacterKind.rabbit);
            _turtleIntro = _hasWholeChunks
                ? 'Now split the part this lesson teaches — grey blocks stay whole.'
                : 'Now split each block into its smallest parts.';
          });
          _phaseTransitionController.forward();
        });
      } else {
        // Phase 2 complete → show the finished sentence briefly, then next step
        setState(() {
          _finished = true;
          _turtleIntro = null;
          _say('Correct! ${data.sentence}', speaker: MaruCharacterKind.turtle);
        });
        widget.onScore?.call(_firstTry.values.where((v) => v).length, 2);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) widget.onNext();
        });
      }
    } else {
      final hint = isTurtleMode ? _turtleHint() : null;
      setState(() {
        _turtleIntro = null;
        _say(
          'Not quite. Tap a placed block to remove it and try again.'
          '${hint != null ? '\nHint: $hint' : ''}',
          speaker: MaruCharacterKind.turtle,
          isError: true,
        );
      });
    }
  }

  bool _finished = false;

  /// `turtle_explanation` of the first chunk whose parts are wrong, if the data has one.
  String? _turtleHint() {
    for (final el in data.elements.where((e) => e.isTarget && !_staysWhole(e))) {
      final wrong = List.generate(el.correctTurtle.length, (i) => droppedAnswers['${el.id}_$i']?.text)
          .asMap()
          .entries
          .any((e) => e.value != el.correctTurtle[e.key]);
      final explanation = (el.turtleExplanation ?? '').trim();
      if (wrong && explanation.isNotEmpty) return explanation;
    }
    return null;
  }

  /// Slots of the current phase, in sentence order.
  List<String> get _slotKeys => [
        for (final el in data.elements.where((e) => e.isTarget))
          if (!isTurtleMode)
            el.id
          else if (!_staysWhole(el))
            for (var i = 0; i < el.correctTurtle.length; i++) '${el.id}_$i',
      ];

  /// Tap-to-place: puts the option into the first empty slot (dragging still works).
  void _placeInFirstEmpty(AgglutinativeOption option) {
    final empty = _slotKeys.where((k) => droppedAnswers[k] == null);
    if (empty.isEmpty || _finished) return;
    setState(() {
      droppedAnswers[empty.first] = option;
      _clearErrorFeedback();
    });
  }

  /// After 🐰's "Great!" finishes typing, 🐢 takes over with the split instruction.
  void _handOverToTurtle() {
    final intro = _turtleIntro;
    if (!mounted || intro == null || _speaker != MaruCharacterKind.rabbit || _feedbackIsError) return;
    _handOverTimer?.cancel();
    _handOverTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _turtleIntro != intro || _speaker != MaruCharacterKind.rabbit) return;
      setState(() => _say(intro, speaker: MaruCharacterKind.turtle));
    });
  }

  void _clearErrorFeedback() {
    if (_feedbackIsError) _feedback = null;
  }

  @override
  Widget build(BuildContext context) {
    final activeOptions = data.options.where((opt) {
      bool modeMatches = opt.mode == (isTurtleMode ? 'turtle' : 'rabbit');
      bool isDropped = droppedAnswers.values.any((dropped) => dropped?.id == opt.id);
      return modeMatches && !isDropped;
    }).toList();

    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Phase indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 6,
                      children: [
                        _buildPhaseChip(
                          label: '① Chunk',
                          icon: '🐰',
                          active: !isTurtleMode,
                          done: _rabbitPhaseComplete,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        ),
                        _buildPhaseChip(
                          label: '② Morpheme',
                          icon: '🐢',
                          active: isTurtleMode,
                          done: false,
                        ),
                      ],
                    ),
                  ),

                  // Instruction / target sentence card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          isTurtleMode
                              ? (_hasWholeChunks ? 'Now split the part this lesson teaches' : 'Now split each block into morphemes!')
                              : 'Build the sentence',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.translation,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sentence Board
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: data.elements.map((el) => _buildElementBlock(el)).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Options Tray
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: activeOptions.isEmpty
                        ? Text(
                            'All blocks placed',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: activeOptions.map((opt) => _buildDraggableOption(opt)).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Inline feedback + Check (always visible, never covered)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_feedback != null)
                  Padding(
                    // room above for the character's jump (size 64 → 0.25 × size)
                    padding: const EdgeInsets.only(top: 16, bottom: 10),
                    child: MaruCharacterBubble(
                      key: ValueKey(_feedbackSeq),
                      kind: _speaker,
                      mood: _feedbackIsError
                          ? MaruMood.thinking
                          : (_speaker == MaruCharacterKind.turtle && _turtleIntro != null && !_finished
                              ? MaruMood.idle
                              : MaruMood.happy),
                      message: _feedback!,
                      size: 64,
                      typewriter: true,
                      onTypingDone: _handOverToTurtle,
                    ),
                  ),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isAllSlotsFilled() && !_finished ? _onCheckPressed : null,
                    child: Text(
                      isTurtleMode ? 'Check & Finish' : 'Check',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChip({
    required String label,
    required String icon,
    required bool active,
    required bool done,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.shade50
            : (active ? cs.primary.withValues(alpha: 0.1) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? Colors.green
              : (active ? cs.primary : Colors.grey.shade300),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            done ? '$label ✓' : label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active || done ? FontWeight.bold : FontWeight.normal,
              color: done
                  ? Colors.green.shade700
                  : (active ? cs.primary : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementBlock(AgglutinativeElement element) {
    if (!element.isTarget) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          element.text ?? '',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!isTurtleMode) {
      return _buildDropZone(element.id, '...');
    } else if (_staysWhole(element)) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 2),
        ),
        child: Text(
          element.correctTurtle.first,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
        ),
      );
    } else {
      // Slots for one chunk, labelled with the chunk they come from
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            element.correctRabbit.isNotEmpty ? element.correctRabbit.first : '',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(
              element.correctTurtle.length,
              (index) => _buildDropZone('${element.id}_$index', '?'),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDropZone(String slotKey, String placeholder) {
    return DragTarget<AgglutinativeOption>(
      onAcceptWithDetails: (details) {
        setState(() {
          droppedAnswers[slotKey] = details.data;
          _clearErrorFeedback();
        });
      },
      builder: (context, candidateData, rejectedData) {
        final dropped = droppedAnswers[slotKey];
        final isHovering = candidateData.isNotEmpty;

        return InkWell(
          onTap: dropped != null
              ? () {
                  setState(() {
                    droppedAnswers.remove(slotKey);
                    _clearErrorFeedback();
                  });
                }
              : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 70),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: dropped != null
                  ? cs.primary.withValues(alpha: 0.1)
                  : (isHovering ? cs.primary.withValues(alpha: 0.05) : Colors.grey.shade50),
              border: Border.all(
                color: dropped != null
                    ? cs.primary
                    : (isHovering ? cs.primary : Colors.grey.shade300),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              dropped?.text ?? placeholder,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dropped != null ? cs.primary : Colors.grey.shade400,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableOption(AgglutinativeOption option) {
    final block = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        option.text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    return Draggable<AgglutinativeOption>(
      data: option,
      feedback: Material(
        color: Colors.transparent,
        child: block,
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: block,
      ),
      child: GestureDetector(
        onTap: () => _placeInFirstEmpty(option),
        child: block,
      ),
    );
  }
}
