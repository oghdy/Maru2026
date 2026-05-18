import 'package:flutter/material.dart';
import '../model/question_model.dart';
import '../../utils/tts_helper.dart';

/// Quiz step widget
/// Displays questions and handles answer validation
class QuizStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback? onCompleted;

  const QuizStepWidget({
    Key? key,
    required this.content,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<QuizStepWidget> createState() => _QuizStepWidgetState();
}

class _QuizStepWidgetState extends State<QuizStepWidget> {
  final TtsHelper _ttsHelper = TtsHelper();
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _showResult = false;

  List<Question> get questions {
    final List<dynamic> questionsJson = widget.content['questions'] ?? [];
    return questionsJson
        .map((json) => Question.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  void _checkAnswer() {
    if (_selectedAnswer == null) return;

    final question = questions[_currentQuestionIndex];
    final correctAnswer = question.answer['correct']?.toString();

    setState(() {
      _showResult = true;
      if (_selectedAnswer == correctAnswer) {
        _score++;
      }
    });

    // Show feedback
    final isCorrect = _selectedAnswer == correctAnswer;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child:                 Text(
                isCorrect
                    ? 'Correct! 👏'
                    : 'Incorrect. The correct answer is $correctAnswer.',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showResult = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(
        child: Text('No questions available.'),
      );
    }

    final question = questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;

    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Question counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/${questions.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: $_score/${questions.length}',
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Question text
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              question.content['question']?.toString() ?? '',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Answer choices
          _buildQuestionWidget(question),

          const SizedBox(height: 24),

          // Explanation (if available) - inside scrollable area
          if (_showResult && question.answer['explanation'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.answer['explanation']?.toString() ?? '',
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),

        // Fixed button area at bottom
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: _showResult
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLastQuestion
                        ? () {
                            // Show completion message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.celebration, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Quiz complete! Score: $_score/${questions.length}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            // Call onCompleted callback after a short delay
                            Future.delayed(const Duration(milliseconds: 500), () {
                              widget.onCompleted?.call();
                            });
                          }
                        : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isLastQuestion ? 'Next Step' : 'Next Question',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAnswer != null ? _checkAnswer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Check',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildQuestionWidget(Question question) {
    switch (question.questionType) {
      case QuestionType.multipleChoice:
      case QuestionType.audioChoice:
        // Handle both multiple_choice and audio_choice the same way
        final List<dynamic> choices = question.content['choices'] ?? [];
        final String? audioText = question.content['audio_text']?.toString();
        
        return Column(
          children: [
            // Show audio button for audio_choice questions
            if (question.questionType == QuestionType.audioChoice && audioText != null) ...[
              GestureDetector(
                onTap: () async {
                  await _ttsHelper.speak(audioText);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.volume_up, color: Colors.white),
                          const SizedBox(width: 12),
                          const Text('Playing sound...'),
                        ],
                      ),
                      duration: const Duration(milliseconds: 800),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.volume_up, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Listen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoSansKR',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Choices
            ...choices.map((choice) {
              final choiceText = choice.toString();
              final isSelected = _selectedAnswer == choiceText;
              final isCorrect = _showResult &&
                  choiceText == question.answer['correct']?.toString();
              final isWrong = _showResult &&
                  isSelected &&
                  choiceText != question.answer['correct']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _showResult
                      ? null
                      : () {
                          setState(() {
                            _selectedAnswer = choiceText;
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.1)
                          : isWrong
                              ? Colors.red.withOpacity(0.1)
                              : isSelected
                                  ? const Color(0xFF6366F1).withOpacity(0.1)
                                  : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green
                            : isWrong
                                ? Colors.red
                                : isSelected
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFE5E7EB),
                        width: isSelected || isCorrect || isWrong ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : isWrong
                                  ? Icons.cancel
                                  : isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                          color: isCorrect
                              ? Colors.green
                              : isWrong
                                  ? Colors.red
                                  : const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            choiceText,
                            style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontSize: 20,
                              fontWeight: isSelected || isCorrect || isWrong
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );

      default:
        return Text('Unknown question type: ${question.questionType}');
    }
  }
}

