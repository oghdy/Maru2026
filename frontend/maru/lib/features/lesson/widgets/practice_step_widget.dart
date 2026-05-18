import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PracticeStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onNext;

  const PracticeStepWidget({
    super.key,
    required this.content,
    required this.onNext,
  });

  @override
  State<PracticeStepWidget> createState() => _PracticeStepWidgetState();
}

class _PracticeStepWidgetState extends State<PracticeStepWidget> {
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
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _checkAnswer(Map<String, dynamic> exercise) {
    setState(() {
      isChecked = true;
    });
  }

  void _nextExercise(List<dynamic> exercises, {bool isListenMatch = false}) {
    if (isListenMatch) {
      if (currentExerciseIndex < exercises.length - 1) {
        setState(() {
          currentExerciseIndex++;
          selectedOption = null;
          isChecked = false;
          _targetListenMatchItem = null;
        });
      } else {
        widget.onNext();
      }
      return;
    }

    if (currentExerciseIndex < exercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
        selectedOption = null;
        userInputResult = '';
        isChecked = false;
      });
    } else {
      widget.onNext();
    }
  }

  // Variables specifically for listen_match quiz
  String? _targetListenMatchItem;
  
  void _setupListenMatchTarget(List<dynamic> items) {
    if (_targetListenMatchItem == null && items.isNotEmpty) {
      // Pick a random target from the items that hasn't been tested (simplified: just random for now)
      final shuffled = List.from(items)..shuffle();
      _targetListenMatchItem = shuffled.first as String;
      // Play it immediately when setup
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _speak(_targetListenMatchItem!);
      });
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
      _setupListenMatchTarget(items);
      return _buildListenMatchQuiz(items);
    }

    final totalCount = exercises.isNotEmpty ? exercises.length : items.length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Practice ${currentExerciseIndex + 1} of $totalCount',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          
          if (exercises.isNotEmpty) ...[
            Text(
              (exercises[currentExerciseIndex] as Map<String, dynamic>)['instruction'] ?? 'Solve the problem',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if ((exercises[currentExerciseIndex] as Map<String, dynamic>)['type'] == 'fill_blank') _buildFillBlank(exercises[currentExerciseIndex] as Map<String, dynamic>),
            if ((exercises[currentExerciseIndex] as Map<String, dynamic>)['type'] == 'user_input') _buildUserInput(exercises[currentExerciseIndex] as Map<String, dynamic>),
            if ((exercises[currentExerciseIndex] as Map<String, dynamic>)['type'] == 'listen_repeat') _buildListenRepeat(exercises[currentExerciseIndex] as Map<String, dynamic>),
            if ((exercises[currentExerciseIndex] as Map<String, dynamic>)['type'] == 'listening') _buildListening(exercises[currentExerciseIndex] as Map<String, dynamic>),
            if ((exercises[currentExerciseIndex] as Map<String, dynamic>)['type'] == 'multiple_choice') _buildMultipleChoice(exercises[currentExerciseIndex] as Map<String, dynamic>),
          ] else if (items.isNotEmpty) ...[
            const Text(
              'Listen and repeat the sound',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            _buildJamoFlashcard(items[currentExerciseIndex] as Map<String, dynamic>),
          ],

          const Spacer(),
          if (exercises.isNotEmpty)
            Builder(builder: (context) {
              final currentExercise = exercises[currentExerciseIndex] as Map<String, dynamic>;
              final isCorrect = selectedOption == currentExercise['answer'];
              final isFreeType = currentExercise['type'] == 'user_input' || currentExercise['type'] == 'listen_repeat';
              
              if (isChecked && !isCorrect && !isFreeType) {
                return ElevatedButton(
                  onPressed: () => setState(() { isChecked = false; selectedOption = null; }),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                );
              } else if (isChecked || isFreeType) {
                return ElevatedButton(
                  onPressed: () => _nextExercise(exercises),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF6B4EFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(currentExerciseIndex == totalCount - 1 ? 'Finish Practice' : 'Next', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                );
              } else {
                return ElevatedButton(
                  onPressed: selectedOption != null ? () => _checkAnswer(currentExercise) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: selectedOption != null ? const Color(0xFF6B4EFF) : Colors.grey.shade300,
                    foregroundColor: selectedOption != null ? Colors.white : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Check Answer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                );
              }
            })
          else 
            ElevatedButton(
              onPressed: () => _nextExercise(items),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(currentExerciseIndex == totalCount - 1 ? 'Finish Practice' : 'Next', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildListenMatchQuiz(List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentExerciseIndex + 1}/5',
                style: const TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Score: 0/6',
                  style: const TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Instruction Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'Listen to the sound and find\nthe correct vowel',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),

          // Big Listen Button
          InkWell(
            onTap: () {
              if (_targetListenMatchItem != null) _speak(_targetListenMatchItem!);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6B4EFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ]
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text('Listen', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Options List
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final jamo = items[index] as String;
                final isSelected = selectedOption == jamo;
                final isCorrect = isChecked && jamo == _targetListenMatchItem;
                final isWrong = isChecked && isSelected && jamo != _targetListenMatchItem;
                
                Color borderColor = Colors.grey.shade300;
                Color bgColor = Colors.white;
                IconData radioIcon = Icons.radio_button_unchecked;
                Color iconColor = Colors.grey.shade400;

                if (isSelected) {
                  borderColor = const Color(0xFF6B4EFF);
                  bgColor = const Color(0xFF6B4EFF).withValues(alpha: 0.05);
                  radioIcon = Icons.radio_button_checked;
                  iconColor = const Color(0xFF6B4EFF);
                }
                
                if (isCorrect) {
                  borderColor = Colors.green;
                  bgColor = Colors.green.withValues(alpha: 0.1);
                  radioIcon = Icons.check_circle;
                  iconColor = Colors.green;
                } else if (isWrong) {
                  borderColor = Colors.red;
                  bgColor = Colors.red.withValues(alpha: 0.1);
                  radioIcon = Icons.cancel;
                  iconColor = Colors.red;
                }

                return InkWell(
                  onTap: isChecked ? null : () => setState(() => selectedOption = jamo),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: isSelected || isChecked ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(radioIcon, color: iconColor, size: 24),
                        const SizedBox(width: 16),
                        Text(
                          jamo,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Action Button
          const SizedBox(height: 16),
          if (isChecked)
            ElevatedButton(
              onPressed: () => _nextExercise(List.filled(5, 0), isListenMatch: true),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(currentExerciseIndex == 4 ? 'Finish Quiz' : 'Next', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton(
              onPressed: selectedOption != null ? () => setState(() => isChecked = true) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: selectedOption != null ? const Color(0xFF6B4EFF) : Colors.grey.shade300,
                foregroundColor: selectedOption != null ? Colors.white : Colors.grey.shade600,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Check', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
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
                      style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.blue),
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
            icon: const Icon(Icons.volume_up, size: 48, color: Colors.blue),
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

  Widget _buildUserInput(Map<String, dynamic> exercise) {
    final template = exercise['template'] as String? ?? '';
    
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Type your answer here',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            setState(() {
              userInputResult = template.replaceAll('{input}', val);
            });
          },
        ),
        const SizedBox(height: 24),
        if (userInputResult.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              userInputResult,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildListenRepeat(Map<String, dynamic> exercise) {
    final sentence = exercise['sentence'] as String? ?? '';
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.volume_up, size: 64, color: Colors.blue),
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
            icon: const Icon(Icons.headphones, size: 64, color: Colors.purple),
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
                color: isSelected ? Colors.blue : Colors.grey.shade300,
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

