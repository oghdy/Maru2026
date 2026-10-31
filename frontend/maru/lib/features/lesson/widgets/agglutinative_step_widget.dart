import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../models/agglutinative_quiz_model.dart';
import 'lesson_style.dart';

/// A block on its way between the tray and a slot, drawn above the page.
class _BlockFlight {
  final AnimationController controller;
  final OverlayEntry entry;

  _BlockFlight(this.controller, this.entry);
}

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
    with TickerProviderStateMixin {
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

  // Touch feel (display only, no effect on grading)
  int _wrongAttempts = 0; // shakes the board
  bool _celebrating = false; // the moment between a right 🐰 answer and the 🐢 phase
  final Set<String> _inFlight = {}; // option ids whose block is still flying
  final Map<String, int> _bounce = {}; // slot → landings, replays the settle effect
  final Map<String, GlobalKey> _optionAnchors = {};
  final Map<String, GlobalKey> _slotAnchors = {};
  final List<_BlockFlight> _flights = [];

  GlobalKey _optionAnchor(String id) => _optionAnchors.putIfAbsent(id, GlobalKey.new);
  GlobalKey _slotAnchor(String key) => _slotAnchors.putIfAbsent(key, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    data = AgglutinativeQuizData.fromJson(widget.content);
    _phaseTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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
    _phaseTransitionController.duration = lessonMotion(context, 200);
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
    // Emptied first: disposing a controller cancels its flight, which must not clean up twice
    final flights = List.of(_flights);
    _flights.clear();
    for (final flight in flights) {
      if (flight.entry.mounted) flight.entry.remove();
      flight.entry.dispose();
      flight.controller.dispose();
    }
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
      HapticFeedback.lightImpact();
      if (!isTurtleMode) {
        if (lessonReduceMotion(context)) {
          _advanceToTurtle();
        } else {
          // Let the blocks show green for a moment before the board changes
          setState(() => _celebrating = true);
          Future.delayed(const Duration(milliseconds: 320), () {
            if (mounted) _advanceToTurtle();
          });
        }
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
      HapticFeedback.mediumImpact();
      final hint = isTurtleMode ? _turtleHint() : null;
      setState(() {
        _wrongAttempts++;
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

  /// Phase 1 complete → auto-advance to Turtle mode
  void _advanceToTurtle() {
    _phaseTransitionController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _celebrating = false;
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

  bool get _inputLocked => _finished || _celebrating;

  /// Tap-to-place: puts the option into the first empty slot (dragging still works).
  void _placeInFirstEmpty(AgglutinativeOption option) {
    final empty = _slotKeys.where((k) => droppedAnswers[k] == null);
    if (empty.isEmpty || _inputLocked) return;
    final slot = empty.first;
    final from = _rectOf(_optionAnchor(option.id));
    HapticFeedback.lightImpact();
    setState(() {
      droppedAnswers[slot] = option;
      _clearErrorFeedback();
    });
    _launch(option, from: from, to: _slotAnchor(slot), toSlot: slot);
  }

  /// Tapping a placed block sends it back to the tray.
  void _returnToTray(String slotKey) {
    final option = droppedAnswers[slotKey];
    if (option == null || _inputLocked) return;
    final from = _rectOf(_slotAnchor(slotKey));
    HapticFeedback.selectionClick();
    setState(() {
      droppedAnswers.remove(slotKey);
      _clearErrorFeedback();
    });
    _launch(option, from: from, to: _optionAnchor(option.id));
  }

  void _settle(String slotKey) => _bounce[slotKey] = (_bounce[slotKey] ?? 0) + 1;

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Flies a copy of the block from its old place to its new one. The real block stays
  /// invisible until it lands, so layout and grading never wait for the animation.
  void _launch(AgglutinativeOption option, {required Rect? from, required GlobalKey to, String? toSlot}) {
    if (from == null || lessonReduceMotion(context)) return;
    setState(() => _inFlight.add(option.id));

    void land() {
      if (!mounted) return;
      setState(() {
        _inFlight.remove(option.id);
        if (toSlot != null) _settle(toSlot);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _rectOf(to);
      final overlay = Overlay.maybeOf(context);
      final overlayBox = overlay?.context.findRenderObject() as RenderBox?;
      if (target == null || overlay == null || overlayBox == null) return land();

      final origin = overlayBox.globalToLocal(Offset.zero);
      final start = from.shift(origin);
      final end = target.shift(origin);
      final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
      final curve = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
      final colors = cs;
      final entry = OverlayEntry(
        builder: (_) => AnimatedBuilder(
          animation: curve,
          builder: (context, _) {
            // Going to a slot it turns into the placed look; going home, back into a block
            final t = toSlot != null ? curve.value : 1 - curve.value;
            return Positioned.fromRect(
              rect: Rect.lerp(start, end, curve.value)!,
              child: IgnorePointer(
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Color.lerp(colors.primary, colors.primaryContainer, t),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        option.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color.lerp(colors.onPrimary, colors.primary, t),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      final flight = _BlockFlight(controller, entry);
      _flights.add(flight);
      overlay.insert(entry);
      controller.forward().whenCompleteOrCancel(() {
        if (!_flights.remove(flight)) return; // the step was closed mid-flight
        entry.remove();
        entry.dispose();
        controller.dispose();
        land();
      });
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
    final reduceMotion = lessonReduceMotion(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Phase indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 6,
                    children: [
                      _buildPhaseChip(
                        label: '① Chunk',
                        kind: MaruCharacterKind.rabbit,
                        active: !isTurtleMode,
                        done: _rabbitPhaseComplete,
                      ),
                      AnimatedContainer(
                        duration: lessonMotion(context, 200),
                        width: 18,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _rabbitPhaseComplete ? lessonSuccess() : colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      _buildPhaseChip(
                        label: '② Morpheme',
                        kind: MaruCharacterKind.turtle,
                        active: isTurtleMode,
                        done: false,
                      ),
                    ],
                  ),
                ),

                // The board changes with a soft fade and a slight zoom between 🐰 and 🐢
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: reduceMotion ? 1 : 0.97, end: 1).animate(_fadeAnimation),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Instruction / target sentence card
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
                          decoration: missionCardDecoration(context),
                          child: Row(
                            children: [
                              MaruCharacter(
                                key: ValueKey(isTurtleMode ? 'turtle' : 'rabbit'),
                                kind: isTurtleMode ? MaruCharacterKind.turtle : MaruCharacterKind.rabbit,
                                mood: _celebrating ? MaruMood.happy : MaruMood.idle,
                                size: 52,
                                entrance: true,
                                interactive: false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTurtleMode
                                          ? (_hasWholeChunks ? 'Now split the part this lesson teaches' : 'Now split each block into morphemes!')
                                          : 'Build the sentence',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.translation,
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25, color: colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Sentence Board
                        LessonShake(
                          trigger: _wrongAttempts,
                          child: AnimatedContainer(
                            duration: lessonMotion(context, 180),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                            decoration: missionCardDecoration(
                              context,
                              borderColor: _feedback != null && _feedbackIsError
                                  ? colorScheme.error.withValues(alpha: 0.45)
                                  : Colors.transparent,
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: data.elements.map((el) => _buildElementBlock(el)).toList(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Options Tray
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(missionCardRadius),
                          ),
                          child: activeOptions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'All blocks placed',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                                  ),
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
              ],
            ),
          ),
        ),

        // Inline feedback + Check (always visible, never covered)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LessonReveal(
                child: _feedback == null
                    ? null
                    : ConstrainedBox(
                        key: ValueKey(_feedbackSeq),
                        // A long hint scrolls instead of pushing the button off a short screen
                        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.38),
                        child: SingleChildScrollView(
                          clipBehavior: Clip.none,
                          child: Padding(
                            // room above for the character's jump (size 64 → 0.25 × size)
                            padding: const EdgeInsets.only(top: 16, bottom: 10),
                            child: MaruCharacterBubble(
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
                        ),
                      ),
              ),
              LessonPrimaryButton(
                label: isTurtleMode ? 'Check & Finish' : 'Check',
                onPressed: _isAllSlotsFilled() && !_inputLocked ? _onCheckPressed : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseChip({
    required String label,
    required MaruCharacterKind kind,
    required bool active,
    required bool done,
  }) {
    final Color foreground = done ? lessonSuccess() : (active ? cs.primary : cs.onSurfaceVariant);
    return AnimatedContainer(
      duration: lessonMotion(context, 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(6, 3, 12, 3),
      decoration: BoxDecoration(
        color: done ? lessonSuccessSoft() : (active ? cs.primaryContainer : cs.surface),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MaruCharacter(kind: kind, mood: MaruMood.idle, size: 28, interactive: false),
          const SizedBox(width: 4),
          Text(
            done ? '$label ✓' : label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active || done ? FontWeight.w800 : FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fixedBlock(String text) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
      ),
    );
  }

  Widget _buildElementBlock(AgglutinativeElement element) {
    if (!element.isTarget) {
      return _fixedBlock(element.text ?? '');
    }

    if (!isTurtleMode) {
      return _buildDropZone(element.id, '...');
    } else if (_staysWhole(element)) {
      return _fixedBlock(element.correctTurtle.first);
    } else {
      // Slots for one chunk. No label: the chunk's Korean text would give the
      // answer away and the data has no English gloss, so a thin outline groups
      // the slots instead (user feedback R3 #1).
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.22), width: 1.5),
        ),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            element.correctTurtle.length,
            (index) => _buildDropZone('${element.id}_$index', '?'),
          ),
        ),
      );
    }
  }

  Widget _buildDropZone(String slotKey, String placeholder) {
    return DragTarget<AgglutinativeOption>(
      onWillAcceptWithDetails: (_) => !_inputLocked,
      onAcceptWithDetails: (details) {
        HapticFeedback.lightImpact();
        setState(() {
          droppedAnswers[slotKey] = details.data;
          _clearErrorFeedback();
          _settle(slotKey);
        });
      },
      builder: (context, candidateData, rejectedData) {
        final dropped = droppedAnswers[slotKey];
        final isHovering = candidateData.isNotEmpty;
        final arriving = dropped != null && _inFlight.contains(dropped.id);
        final placed = dropped != null && !arriving;
        final right = placed && (_finished || _celebrating);

        final Widget slot = AnimatedContainer(
          key: _slotAnchor(slotKey),
          duration: lessonMotion(context, 150),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minWidth: 68, minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: right
                ? lessonSuccessSoft()
                : placed
                    ? cs.primaryContainer
                    : (isHovering ? cs.primary.withValues(alpha: 0.14) : cs.primary.withValues(alpha: 0.04)),
            border: Border.all(
              color: right
                  ? lessonSuccess()
                  : placed || isHovering
                      ? cs.primary
                      : cs.primary.withValues(alpha: 0.22),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          // Centered in the slot, which still hugs its text
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              dropped?.text ?? placeholder,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: arriving
                    ? Colors.transparent
                    : right
                        ? lessonSuccess()
                        : placed
                            ? cs.primary
                            : cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        );

        return LessonPressable(
          pressedScale: 0.94,
          onTap: dropped != null && !_inputLocked ? () => _returnToTray(slotKey) : null,
          child: AnimatedScale(
            // The slot leans in while a block hovers over it
            scale: isHovering ? 1.06 : 1,
            duration: lessonMotion(context, 120),
            child: lessonReduceMotion(context)
                ? slot
                : TweenAnimationBuilder<double>(
                    // A new key replays the settle when a block lands
                    key: ValueKey('settle_${_bounce[slotKey] ?? 0}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, v, child) => Transform.scale(
                      scale: 1 + 0.07 * math.sin(math.pi * v),
                      child: child,
                    ),
                    child: slot,
                  ),
          ),
        );
      },
    );
  }

  Widget _blockFace(String text, {double lift = 1}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: missionHeroGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3 * lift),
            blurRadius: 10 * lift,
            offset: Offset(0, 4 * lift),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onPrimary),
      ),
    );
  }

  Widget _buildDraggableOption(AgglutinativeOption option) {
    final returning = _inFlight.contains(option.id);
    return Draggable<AgglutinativeOption>(
      data: option,
      maxSimultaneousDrags: returning || _inputLocked ? 0 : null,
      onDragStarted: HapticFeedback.selectionClick,
      // Picked up: a little larger, with a deeper shadow
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.08, child: _blockFace(option.text, lift: 1.8)),
      ),
      // The gap it left behind
      childWhenDragging: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          option.text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.transparent),
        ),
      ),
      child: KeyedSubtree(
        key: _optionAnchor(option.id),
        child: Opacity(
          opacity: returning ? 0 : 1,
          child: LessonPressable(
            pressedScale: 0.92,
            onTap: () => _placeInFirstEmpty(option),
            child: _blockFace(option.text),
          ),
        ),
      ),
    );
  }
}
