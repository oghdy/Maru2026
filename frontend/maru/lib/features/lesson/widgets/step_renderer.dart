import 'package:flutter/material.dart';
import '../models/step_model.dart';
import 'introduction_step_widget.dart';
import 'practice_step_widget.dart';
import 'completion_step_widget.dart';
import 'agglutinative_step_widget.dart';

class StepRenderer extends StatelessWidget {
  final StepModel stepModel;
  final VoidCallback onNext;

  const StepRenderer({
    super.key,
    required this.stepModel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    switch (stepModel.stepType) {
      case 'introduction':
      case 'intro':
        return IntroductionStepWidget(content: stepModel.contentObj, onNext: onNext);
      case 'practice':
      case 'quiz':
        return PracticeStepWidget(content: stepModel.contentObj, onNext: onNext);
      case 'completion':
        return CompletionStepWidget(content: stepModel.contentObj, onNext: onNext);
      case 'agglutinative_quiz':
        return AgglutinativeStepWidget(content: stepModel.contentObj, onNext: onNext);
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
