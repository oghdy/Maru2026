import 'package:flutter/material.dart';
import '../models/step_model.dart';
import 'introduction_step_widget.dart';
import 'practice_step_widget.dart';
import 'completion_step_widget.dart';
import 'agglutinative_step_widget.dart';

class StepRenderer extends StatelessWidget {
  final StepModel stepModel;
  final VoidCallback onNext;
  final void Function(int correct, int total)? onScore;
  final int? scorePercent;

  const StepRenderer({
    super.key,
    required this.stepModel,
    required this.onNext,
    this.onScore,
    this.scorePercent,
  });

  @override
  Widget build(BuildContext context) {
    switch (stepModel.stepType) {
      case 'introduction':
      case 'intro':
        return IntroductionStepWidget(content: stepModel.contentObj, onNext: onNext);
      case 'practice':
      case 'quiz':
        return PracticeStepWidget(content: stepModel.contentObj, onNext: onNext, onScore: onScore);
      case 'completion':
        return CompletionStepWidget(
          content: stepModel.contentObj,
          title: stepModel.title,
          instruction: stepModel.instruction,
          scorePercent: scorePercent,
          onNext: onNext,
        );
      case 'agglutinative_quiz':
        return AgglutinativeStepWidget(content: stepModel.contentObj, onNext: onNext, onScore: onScore);
      default:
        // Fallback for unknown step types
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Unknown Step Type: ${stepModel.stepType}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onNext,
                child: const Text('Continue'),
              ),
            ],
          ),
        );
    }
  }
}
