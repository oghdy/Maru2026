import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../../core/utils/tts_helper.dart';
import '../utils/lesson_sounds.dart';
import 'lesson_style.dart';

enum _OptionState { idle, selected, correct, wrong }

class PracticeStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onNext;

  /// Reports first-attempt results of graded questions (correct, total) when the step ends.
  final void Function(int correct, int total)? onScore;

  const PracticeStepWidget({
    super.key,
    required this.content,
    required this.onNext,
    this.onScore,
  });

  @override
  State<PracticeStepWidget> createState() => _PracticeStepWidgetState();
}

class _PracticeStepWidgetState extends State<PracticeStepWidget> {
  ColorScheme get cs => Theme.of(context).colorScheme;

  int currentExerciseIndex = 0;
  String? selectedOption;
  String userInputResult = '';
  bool isChecked = false;

  @override
  void initState() {
    super.initState();

    if (widget.content['quizType'] == 'listen_match') {
      final items = (widget.content['items'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      // Every item is asked exactly once, in random order.
      _quizOrder = List<String>.from(items)..shuffle();
      _speakCurrentTarget();
    }
  }

  @override
  void dispose() {
    TtsHelper.stop();
    super.dispose();
  }

  // Server voice (OpenAI TTS) with device-voice fallback — see TtsHelper
  void _speak(String text) => TtsHelper.speak(text);

  // First-attempt result per graded exercise index (fill_blank, listening, multiple_choice)
  final Map<int, bool> _firstTry = {};

  static const _gradedTypes = {'fill_blank', 'listening', 'multiple_choice'};

  /// `graded: false` = a check in a Learn lesson. The answers still get feedback but no score.
  bool get _countsTowardScore => widget.content['graded'] != false;

  /// `character` names who gives the feedback; without it 🐰 praises and 🐢 coaches.
  MaruCharacterKind? get _feedbackCharacter => switch (widget.content['character']) {
        'rabbit' => MaruCharacterKind.rabbit,
        'turtle' => MaruCharacterKind.turtle,
        _ => null,
      };

  /// Number of Check taps — the feedback character's reactionKey, so it reacts
  /// again on consecutive right (or wrong) answers.
  int _checks = 0;

  void _checkAnswer(Map<String, dynamic> exercise) {
    _answerCue(selectedOption == exercise['answer']);
    setState(() {
      _checks++;
      isChecked = true;
      if (_gradedTypes.contains(exercise['type'])) {
        _firstTry.putIfAbsent(currentExerciseIndex, () => selectedOption == exercise['answer']);
      }
    });
  }

  void _nextExercise(List<dynamic> exercises) {
    if (currentExerciseIndex < exercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
        selectedOption = null;
        userInputResult = '';
        isChecked = false;
      });
    } else {
      if (_firstTry.isNotEmpty && _countsTowardScore) {
        widget.onScore?.call(_firstTry.values.where((v) => v).length, _firstTry.length);
      }
      widget.onNext();
    }
  }

  // listen_match quiz state
  List<String> _quizOrder = [];
  int _quizCorrect = 0;

  String? get _quizTarget =>
      currentExerciseIndex < _quizOrder.length ? _quizOrder[currentExerciseIndex] : null;

  void _speakCurrentTarget() {
    Future.delayed(const Duration(milliseconds: 500), () {
      final target = _quizTarget;
      if (mounted && target != null) _speak(target);
    });
  }

  void _checkListenMatch() {
    _answerCue(selectedOption == _quizTarget);
    setState(() {
      _checks++;
      isChecked = true;
      if (selectedOption == _quizTarget) _quizCorrect++;
    });
  }

  void _nextListenMatch() {
    if (currentExerciseIndex < _quizOrder.length - 1) {
      setState(() {
        currentExerciseIndex++;
        selectedOption = null;
        isChecked = false;
      });
      _speakCurrentTarget();
    } else {
      if (_countsTowardScore) widget.onScore?.call(_quizCorrect, _quizOrder.length);
      widget.onNext();
    }
  }

  void _answerCue(bool correct) {
    // Same haptic pairing as the vocabulary match game. Only a right answer has a sound.
    if (correct) {
      HapticFeedback.lightImpact();
      LessonSounds.playCorrect();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// A typed answer has no single right form, but passing the checks is shown as a success.
  void _acceptUserInput() {
    _answerCue(true);
    setState(() => isChecked = true);
  }

  void _select(String option) {
    HapticFeedback.selectionClick();
    setState(() => selectedOption = option);
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.content['exercises'] as List<dynamic>? ?? [];
    final items = widget.content['items'] as List<dynamic>? ?? [];
    final quizType = widget.content['quizType'] as String?;

    if (exercises.isEmpty && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LessonPrimaryButton(label: 'Skip', onPressed: widget.onNext),
        ),
      );
    }

    // Special Route: Unit 0 listen_match Quiz
    if (quizType == 'listen_match') {
      return _buildListenMatchQuiz(items.map((e) => e.toString()).toList());
    }

    final totalCount = exercises.isNotEmpty ? exercises.length : items.length;
    final colorScheme = Theme.of(context).colorScheme;
    final currentExercise =
        exercises.isNotEmpty ? exercises[currentExerciseIndex] as Map<String, dynamic> : const <String, dynamic>{};
    final type = currentExercise['type'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: AnimatedSwitcher(
              duration: lessonMotion(context, 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              // Each exercise gets fresh state (text field included)
              child: Column(
                key: ValueKey(currentExerciseIndex),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A single question has nothing to count
                  if (totalCount > 1) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MissionPill(
                        label: 'Practice ${currentExerciseIndex + 1} of $totalCount',
                        background: colorScheme.primaryContainer,
                        foreground: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (exercises.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: LessonText(
                        currentExercise['instruction'] as String? ?? 'Solve the problem',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (type == 'fill_blank') _buildFillBlank(currentExercise),
                    if (type == 'user_input') _buildUserInput(currentExercise),
                    if (type == 'listen_repeat') _buildListenRepeat(currentExercise),
                    if (type == 'listening') _buildListening(currentExercise),
                    if (type == 'multiple_choice') _buildMultipleChoice(currentExercise),
                  ] else if (items.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Listen and repeat the sound',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildJamoFlashcard(items[currentExerciseIndex] as Map<String, dynamic>),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Feedback and action stay visible at the bottom, never scrolled away
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (exercises.isNotEmpty) LessonReveal(child: _exerciseFeedback(currentExercise)),
              if (exercises.isNotEmpty)
                _buildExerciseButton(exercises, currentExercise, totalCount)
              else
                LessonPrimaryButton(
                  label: currentExerciseIndex == totalCount - 1 ? 'Finish Practice' : 'Next',
                  onPressed: () => _nextExercise(items),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The checked answer's message with a character, or null when there is nothing to say yet.
  Widget? _exerciseFeedback(Map<String, dynamic> exercise) {
    if (!isChecked) return null;
    final type = exercise['type'];
    final feedback = exercise['feedback'] as Map<String, dynamic>? ?? {};
    if (type == 'user_input') {
      return LessonFeedbackCard(
        key: ValueKey('fb_$_checks'),
        message: feedback['correct'] as String? ?? 'Nice!',
        correct: true,
        reactionKey: _checks,
        character: _feedbackCharacter,
      );
    }
    if (!_gradedTypes.contains(type)) return null;
    final correct = selectedOption == exercise['answer'];
    return LessonFeedbackCard(
      key: ValueKey('fb_$_checks'),
      message: correct ? feedback['correct'] as String? ?? 'Good!' : feedback['incorrect'] as String? ?? 'Try again.',
      correct: correct,
      reactionKey: _checks,
      character: _feedbackCharacter,
    );
  }

  Widget _primaryButton({required String label, required VoidCallback? onPressed, Color? color}) {
    return LessonPrimaryButton(label: label, onPressed: onPressed, color: color);
  }

  Widget _buildExerciseButton(List<dynamic> exercises, Map<String, dynamic> exercise, int totalCount) {
    final isLast = currentExerciseIndex == totalCount - 1;
    // An ungraded check is a short stop in a lesson, not a practice to finish
    final nextLabel = !isLast ? 'Next' : (_countsTowardScore ? 'Finish Practice' : 'Continue');
    final type = exercise['type'];

    if (type == 'listen_repeat') {
      return _primaryButton(label: nextLabel, onPressed: () => _nextExercise(exercises));
    }
    if (type == 'user_input') {
      if (isChecked) return _primaryButton(label: nextLabel, onPressed: () => _nextExercise(exercises));
      return _primaryButton(
        label: 'Check',
        onPressed: _userInputError(exercise) == null ? _acceptUserInput : null,
      );
    }

    final isCorrect = selectedOption == exercise['answer'];
    if (isChecked && !isCorrect) {
      return _primaryButton(
        label: 'Try Again',
        color: Theme.of(context).colorScheme.error,
        onPressed: () => setState(() {
          isChecked = false;
          selectedOption = null;
        }),
      );
    }
    if (isChecked) return _primaryButton(label: nextLabel, onPressed: () => _nextExercise(exercises));
    return _primaryButton(
      label: 'Check Answer',
      onPressed: selectedOption != null ? () => _checkAnswer(exercise) : null,
    );
  }

  /// One answer choice: presses in, then eases between idle, selected, right and wrong.
  Widget _optionTile({
    required String label,
    required _OptionState state,
    required VoidCallback? onTap,
    double fontSize = 18,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color background, Color border, Color foreground, IconData icon) = switch (state) {
      _OptionState.idle => (colorScheme.surface, Colors.transparent, colorScheme.onSurface, Icons.circle_outlined),
      _OptionState.selected => (colorScheme.primaryContainer, colorScheme.primary, colorScheme.primary, Icons.radio_button_checked_rounded),
      _OptionState.correct => (lessonSuccessSoft(), lessonSuccess(), lessonSuccess(), Icons.check_circle_rounded),
      _OptionState.wrong => (colorScheme.errorContainer.withValues(alpha: 0.55), colorScheme.error, colorScheme.error, Icons.cancel_rounded),
    };
    final iconColor = state == _OptionState.idle ? colorScheme.outlineVariant : foreground;

    return LessonShake(
      trigger: state == _OptionState.wrong ? _checks : 0,
      child: AnimatedScale(
        // A small lift for the right answer
        scale: state == _OptionState.correct ? 1.015 : 1,
        duration: lessonMotion(context, 180),
        curve: Curves.easeOutBack,
        child: Semantics(
          selected: state == _OptionState.selected,
          child: LessonPressable(
            onTap: onTap,
            child: AnimatedContainer(
              duration: lessonMotion(context, 180),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: 2),
                boxShadow: [
                  if (state == _OptionState.idle)
                    BoxShadow(color: colorScheme.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: lessonMotion(context, 180),
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: foreground),
                      child: LessonText(label),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: lessonMotion(context, 160),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(icon, key: ValueKey(icon), color: iconColor, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListenMatchQuiz(List<String> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = _quizOrder.length;
    final target = _quizTarget;
    final isLast = currentExerciseIndex >= total - 1;
    final answeredCorrectly = isChecked && selectedOption == target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: real progress and score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentExerciseIndex + 1}/$total',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w800),
                  ),
                  MissionPill(
                    label: 'Score: $_quizCorrect/$total',
                    background: colorScheme.primaryContainer,
                    foreground: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Big Listen Button
              LessonPressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (target != null) _speak(target);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: missionHeroGradient(context),
                    borderRadius: BorderRadius.circular(missionCardRadius),
                    boxShadow: [
                      BoxShadow(color: colorScheme.primary.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volume_up_rounded, color: colorScheme.onPrimary, size: 28),
                      const SizedBox(width: 10),
                      Text('Listen', style: TextStyle(color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap Listen, then choose what you hear.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),

        // Options List
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 64,
            ),
            itemBuilder: (context, index) {
              final jamo = items[index];
              final isSelected = selectedOption == jamo;
              final isCorrect = isChecked && jamo == target;
              final isWrong = isChecked && isSelected && jamo != target;

              return _optionTile(
                label: jamo,
                fontSize: 22,
                state: isCorrect
                    ? _OptionState.correct
                    : isWrong
                        ? _OptionState.wrong
                        : isSelected
                            ? _OptionState.selected
                            : _OptionState.idle,
                onTap: isChecked ? null : () => _select(jamo),
              );
            },
          ),
        ),

        // Feedback + Action Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LessonReveal(
                child: (isChecked && target != null)
                    ? LessonFeedbackCard(
                        key: ValueKey('fb_$_checks'),
                        message: answeredCorrectly ? 'Correct! That was $target.' : 'Not quite — you heard $target.',
                        correct: answeredCorrectly,
                        reactionKey: _checks,
                        character: _feedbackCharacter,
                      )
                    : null,
              ),
              if (isChecked)
                LessonPrimaryButton(
                  label: isLast ? 'Finish Quiz ($_quizCorrect/$total)' : 'Next',
                  onPressed: _nextListenMatch,
                )
              else
                LessonPrimaryButton(
                  label: 'Check',
                  onPressed: selectedOption != null ? _checkListenMatch : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJamoFlashcard(Map<String, dynamic> item) {
    final jamo = item['jamo'] as String? ?? '';
    final romanization = item['romanization'] as String? ?? '';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LessonPressable(
            onTap: () => _speak(jamo),
            child: Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: missionCardDecoration(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        jamo,
                        style: TextStyle(fontSize: 80, fontWeight: FontWeight.w800, color: cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "[$romanization]",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          LessonSpeakerButton(size: 64, onPressed: () => _speak(jamo)),
          const SizedBox(height: 8),
          Text('Tap to listen', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        ],
      ),
    );
  }

  /// White card holding the sentence being worked on.
  Widget _sentenceCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: missionCardDecoration(context),
      child: child,
    );
  }

  Widget _buildFillBlank(Map<String, dynamic> exercise) {
    final sentence = exercise['sentence'] as String? ?? '';
    final options = exercise['options'] as List<dynamic>? ?? [];
    final answer = exercise['answer'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sentenceCard(
          child: LessonText(
            // The blank stays in one piece at a line end
            sentence.replaceAll('[ ? ]', '[\u00A0?\u00A0]'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ..._buildOptionsList(options, answer),
      ],
    );
  }

  /// Fixed parts of a user_input template, e.g. "저는 {input}입니다." → ["저는", "입니다"].
  List<String> _templateParts(String template) => template
      .split('{input}')
      .map((p) => p.replaceAll(RegExp(r'[\s.,!?]'), ''))
      .where((p) => p.isNotEmpty)
      .toList();

  /// Null when the typed answer is acceptable; otherwise a short English hint.
  /// There is no single right answer (it's the learner's own name), so this only
  /// catches empty input, re-typing the given words, and overly long input.
  String? _userInputError(Map<String, dynamic> exercise) {
    final input = userInputResult.trim();
    if (input.isEmpty) return '';
    final parts = _templateParts(exercise['template'] as String? ?? '');
    final typedGiven = parts.where((p) => input.contains(p)).toList();
    if (typedGiven.isNotEmpty) {
      return "Type only the missing part — '${typedGiven.join("', '")}' is already in the sentence.";
    }
    if (input.characters.length > 20) return 'Keep it short — just the missing word.';
    return null;
  }

  Widget _buildUserInput(Map<String, dynamic> exercise) {
    final colorScheme = Theme.of(context).colorScheme;
    final template = exercise['template'] as String? ?? '';
    final input = userInputResult.trim();
    final error = _userInputError(exercise);
    final sentence = template.replaceAll('{input}', input.isEmpty ? '____' : input);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The sentence being completed, visible from the start
        _sentenceCard(
          child: Row(
            children: [
              Expanded(
                child: LessonText(
                  sentence,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isChecked) ...[
                const SizedBox(width: 8),
                LessonSpeakerButton(size: 44, onPressed: () => _speak(sentence)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          enabled: !isChecked,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Type the missing word',
            filled: true,
            fillColor: colorScheme.surface,
            border: border(Colors.transparent, 0),
            enabledBorder: border(colorScheme.primary.withValues(alpha: 0.18), 1.5),
            disabledBorder: border(Colors.transparent, 0),
            focusedBorder: border(colorScheme.primary, 2),
            errorBorder: border(colorScheme.error, 1.5),
            focusedErrorBorder: border(colorScheme.error, 2),
            errorText: (error != null && error.isNotEmpty) ? lessonKeepAll(error) : null,
            errorMaxLines: 2,
          ),
          onChanged: (val) => setState(() => userInputResult = val),
          onSubmitted: (_) {
            if (_userInputError(exercise) == null) _acceptUserInput();
          },
        ),
      ],
    );
  }

  Widget _buildListenRepeat(Map<String, dynamic> exercise) {
    final sentence = exercise['sentence'] as String? ?? '';
    return _sentenceCard(
      child: Column(
        children: [
          LessonSpeakerButton(size: 72, onPressed: () => _speak(sentence)),
          const SizedBox(height: 16),
          LessonText(
            sentence,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListening(Map<String, dynamic> exercise) {
    final options = exercise['options'] as List<dynamic>? ?? [];
    final answer = exercise['answer'] as String? ?? '';
    final audioText = exercise['audio_text'] as String? ?? '';
    final sentence = exercise['sentence'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sentenceCard(
          child: Column(
            children: [
              LessonSpeakerButton(size: 72, icon: Icons.headphones_rounded, onPressed: () => _speak(audioText)),
              if (sentence != null && sentence.isNotEmpty) ...[
                const SizedBox(height: 16),
                LessonText(
                  sentence,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._buildOptionsList(options, answer),
      ],
    );
  }

  Widget _buildMultipleChoice(Map<String, dynamic> exercise) {
    final options = exercise['options'] as List<dynamic>? ?? [];
    final answer = exercise['answer'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._buildOptionsList(options, answer),
      ],
    );
  }

  List<Widget> _buildOptionsList(List<dynamic> options, String answer) {
    return options.map((opt) {
      final isSelected = selectedOption == opt;
      final isCorrect = isChecked && opt == answer;
      final isWrong = isChecked && isSelected && opt != answer;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: _optionTile(
          label: opt as String,
          state: isCorrect
              ? _OptionState.correct
              : isWrong
                  ? _OptionState.wrong
                  : isSelected
                      ? _OptionState.selected
                      : _OptionState.idle,
          onTap: isChecked ? null : () => _select(opt),
        ),
      );
    }).toList();
  }
}
