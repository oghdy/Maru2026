import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("ko-KR");
    flutterTts.setSpeechRate(0.45); // Slightly slower for language learners
    flutterTts.setPitch(1.0);

    if (widget.content['quizType'] == 'listen_match') {
      final items = (widget.content['items'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      // Every item is asked exactly once, in random order.
      _quizOrder = List<String>.from(items)..shuffle();
      _speakCurrentTarget();
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  // First-attempt result per graded exercise index (fill_blank, listening, multiple_choice)
  final Map<int, bool> _firstTry = {};

  static const _gradedTypes = {'fill_blank', 'listening', 'multiple_choice'};

  void _checkAnswer(Map<String, dynamic> exercise) {
    setState(() {
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
      if (_firstTry.isNotEmpty) {
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
    setState(() {
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
      widget.onScore?.call(_quizCorrect, _quizOrder.length);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.content['exercises'] as List<dynamic>? ?? [];
    final items = widget.content['items'] as List<dynamic>? ?? [];
    final quizType = widget.content['quizType'] as String?;

    if (exercises.isEmpty && items.isEmpty) {
      return Center(
        child: ElevatedButton(onPressed: widget.onNext, child: const Text('Skip')),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Practice ${currentExerciseIndex + 1} of $totalCount',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (exercises.isNotEmpty) ...[
                    Text(
                      currentExercise['instruction'] ?? 'Solve the problem',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    if (type == 'fill_blank') _buildFillBlank(currentExercise),
                    if (type == 'user_input') _buildUserInput(currentExercise),
                    if (type == 'listen_repeat') _buildListenRepeat(currentExercise),
                    if (type == 'listening') _buildListening(currentExercise),
                    if (type == 'multiple_choice') _buildMultipleChoice(currentExercise),
                  ] else if (items.isNotEmpty) ...[
                    const Text(
                      'Listen and repeat the sound',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    _buildJamoFlashcard(items[currentExerciseIndex] as Map<String, dynamic>),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (exercises.isNotEmpty)
            _buildExerciseButton(exercises, currentExercise, totalCount)
          else
            _primaryButton(
              label: currentExerciseIndex == totalCount - 1 ? 'Finish Practice' : 'Next',
              onPressed: () => _nextExercise(items),
            ),
        ],
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback? onPressed, Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color ?? colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildExerciseButton(List<dynamic> exercises, Map<String, dynamic> exercise, int totalCount) {
    final nextLabel = currentExerciseIndex == totalCount - 1 ? 'Finish Practice' : 'Next';
    final type = exercise['type'];

    if (type == 'listen_repeat') {
      return _primaryButton(label: nextLabel, onPressed: () => _nextExercise(exercises));
    }
    if (type == 'user_input') {
      if (isChecked) return _primaryButton(label: nextLabel, onPressed: () => _nextExercise(exercises));
      return _primaryButton(
        label: 'Check',
        onPressed: _userInputError(exercise) == null ? () => setState(() => isChecked = true) : null,
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

  Widget _buildListenMatchQuiz(List<String> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = _quizOrder.length;
    final target = _quizTarget;
    final isLast = currentExerciseIndex >= total - 1;
    final answeredCorrectly = isChecked && selectedOption == target;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: real progress and score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentExerciseIndex + 1}/$total',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Score: $_quizCorrect/$total',
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Listen Button
          InkWell(
            onTap: () {
              if (target != null) _speak(target);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, color: colorScheme.onPrimary, size: 28),
                  const SizedBox(width: 12),
                  Text('Listen', style: TextStyle(color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),

          // Options List
          Expanded(
            child: GridView.builder(
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

                Color borderColor = colorScheme.outlineVariant;
                Color bgColor = colorScheme.surface;
                IconData radioIcon = Icons.radio_button_unchecked;
                Color iconColor = colorScheme.outline;

                if (isSelected) {
                  borderColor = colorScheme.primary;
                  bgColor = colorScheme.primary.withValues(alpha: 0.05);
                  radioIcon = Icons.radio_button_checked;
                  iconColor = colorScheme.primary;
                }
                if (isCorrect) {
                  borderColor = Colors.green;
                  bgColor = Colors.green.withValues(alpha: 0.1);
                  radioIcon = Icons.check_circle;
                  iconColor = Colors.green;
                } else if (isWrong) {
                  borderColor = colorScheme.error;
                  bgColor = colorScheme.error.withValues(alpha: 0.1);
                  radioIcon = Icons.cancel;
                  iconColor = colorScheme.error;
                }

                return InkWell(
                  onTap: isChecked ? null : () => setState(() => selectedOption = jamo),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: isSelected || isCorrect ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(radioIcon, color: iconColor, size: 22),
                        const SizedBox(width: 12),
                        Text(jamo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Feedback
          if (isChecked && target != null) ...[
            const SizedBox(height: 12),
            Text(
              answeredCorrectly ? 'Correct! That was $target.' : 'Not quite — you heard $target.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: answeredCorrectly ? Colors.green.shade700 : colorScheme.error,
              ),
            ),
          ],

          // Action Button
          const SizedBox(height: 12),
          if (isChecked)
            ElevatedButton(
              onPressed: _nextListenMatch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isLast ? 'Finish Quiz ($_quizCorrect/$total)' : 'Next',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton(
              onPressed: selectedOption != null ? _checkListenMatch : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                disabledForegroundColor: colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Check', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildJamoFlashcard(Map<String, dynamic> item) {
    final jamo = item['jamo'] as String? ?? '';
    final romanization = item['romanization'] as String? ?? '';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _speak(jamo),
                borderRadius: BorderRadius.circular(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      jamo,
                      style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: cs.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "[$romanization]",
                      style: const TextStyle(fontSize: 32, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          IconButton(
            onPressed: () => _speak(jamo),
            icon: Icon(Icons.volume_up, size: 48, color: cs.primary),
          ),
          const SizedBox(height: 8),
          const Text('Tap to listen', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }


  Widget _buildFillBlank(Map<String, dynamic> exercise) {
    final sentence = exercise['sentence'] as String? ?? '';
    final options = exercise['options'] as List<dynamic>? ?? [];
    final answer = exercise['answer'] as String? ?? '';
    final feedback = exercise['feedback'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sentence,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ..._buildOptionsList(options, answer),
        if (isChecked) ...[
          const SizedBox(height: 16),
          Text(
            selectedOption == answer ? feedback['correct'] ?? 'Good!' : 'Try again.',
            style: TextStyle(
              color: selectedOption == answer ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ]
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
    final feedback = exercise['feedback'] as Map<String, dynamic>? ?? {};
    final input = userInputResult.trim();
    final error = _userInputError(exercise);
    final sentence = template.replaceAll('{input}', input.isEmpty ? '____' : input);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The sentence being completed, visible from the start
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sentence,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isChecked)
                IconButton(
                  icon: Icon(Icons.volume_up, color: colorScheme.primary),
                  onPressed: () => _speak(sentence),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          enabled: !isChecked,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Type the missing word',
            border: const OutlineInputBorder(),
            errorText: (error != null && error.isNotEmpty) ? error : null,
            errorMaxLines: 2,
          ),
          onChanged: (val) => setState(() => userInputResult = val),
          onSubmitted: (_) {
            if (_userInputError(exercise) == null) setState(() => isChecked = true);
          },
        ),
        if (isChecked) ...[
          const SizedBox(height: 16),
          Text(
            feedback['correct'] as String? ?? 'Nice!',
            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildListenRepeat(Map<String, dynamic> exercise) {
    final sentence = exercise['sentence'] as String? ?? '';
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.volume_up, size: 64, color: cs.primary),
          iconSize: 64,
          onPressed: () => _speak(sentence),
        ),
        const SizedBox(height: 24),
        Text(
          sentence,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
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
        Center(
          child: IconButton(
            icon: Icon(Icons.headphones, size: 64, color: cs.primary),
            iconSize: 64,
            onPressed: () => _speak(audioText),
          ),
        ),
        if (sentence != null && sentence.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            sentence,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
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
      
      Color bgColor = Colors.transparent;
      if (isCorrect) bgColor = Colors.green.withValues(alpha: 0.2);
      if (isWrong) bgColor = Colors.red.withValues(alpha: 0.2);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
          onTap: isChecked ? null : () => setState(() => selectedOption = opt as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? cs.primary : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: bgColor,
            ),
            child: Center(
              child: Text(
                opt as String,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

