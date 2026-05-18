import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/lesson_model.dart';
import '../model/step_model.dart' show LessonStep, StepType;
import '../widgets/intro_step_widget.dart';
import '../widgets/practice_step_widget.dart';
import '../widgets/quiz_step_widget.dart';
import '../widgets/completion_step_widget.dart';

/// Common lesson screen that renders any lesson based on JSON data
/// This is the "Lego block" approach - one screen handles all lessons
class LessonScreen extends StatefulWidget {
  final String jsonPath;

  const LessonScreen({
    Key? key,
    required this.jsonPath,
  }) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<Lesson> _lessonFuture;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _lessonFuture = _loadLesson();
  }

  Future<Lesson> _loadLesson() async {
    try {
      // Load JSON from assets folder
      String assetPath = widget.jsonPath;
      
      // If path doesn't start with 'assets/', add it
      if (!assetPath.startsWith('assets/')) {
        assetPath = 'assets/$assetPath';
      }
      
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return Lesson.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to load lesson from: $assetPath. Error: $e');
    }
  }

  Widget _buildStepWidget(LessonStep step, Lesson lesson) {
    // Render appropriate widget based on step type
    switch (step.stepType) {
      case StepType.introduction:
        return IntroStepWidget(content: step.content);
      case StepType.practice:
        return PracticeStepWidget(content: step.content);
      case StepType.quiz:
        return QuizStepWidget(
          content: step.content,
          onCompleted: () => _nextStep(lesson),
        );
      case StepType.completion:
        return CompletionStepWidget(content: step.content);
      default:
        return Center(
          child: Text('Unknown step type: ${step.stepType}'),
        );
    }
  }

  void _nextStep(Lesson lesson) {
    if (_currentStepIndex < lesson.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      // Lesson completed
      Navigator.pop(context);
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: FutureBuilder<Lesson>(
          future: _lessonFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!.title,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return const Text(
              'Loading...',
              style: TextStyle(fontFamily: 'NotoSansKR'),
            );
          },
        ),
      ),
      body: FutureBuilder<Lesson>(
        future: _lessonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final lesson = snapshot.data!;
          final currentStep = lesson.steps[_currentStepIndex];
          final progress = (_currentStepIndex + 1) / lesson.steps.length;

          return Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentStepIndex + 1}/${lesson.steps.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Current step widget
              Expanded(
                child: _buildStepWidget(currentStep, lesson),
              ),

              // Navigation buttons (hidden during quiz step)
              if (currentStep.stepType != StepType.quiz)
                Container(
                  padding: const EdgeInsets.all(16.0),
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
                  child: Row(
                    children: [
                      if (_currentStepIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF6366F1)),
                            ),
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStepIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _nextStep(lesson),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _currentStepIndex < lesson.steps.length - 1
                                ? 'Next'
                                : 'Complete',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

