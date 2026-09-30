import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/vocabulary_session_pager.dart';

class VocabularyLearningScreen extends ConsumerStatefulWidget {
  final String deckTitle;

  const VocabularyLearningScreen({super.key, required this.deckTitle});

  @override
  ConsumerState<VocabularyLearningScreen> createState() => _VocabularyLearningScreenState();
}

class _VocabularyLearningScreenState extends ConsumerState<VocabularyLearningScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vocabularySessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.deckTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (!session.isLoading && !session.isCompleted && session.words.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${session.currentIndex + 1} / ${session.words.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(session),
    );
  }

  Widget _buildBody(VocabularySessionState session) {
    if (session.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (session.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Error: ${session.errorMessage}',
              style: const TextStyle(color: Colors.white),
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

    if (session.isCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Lesson Completed!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Return to Deck List'),
            ),
          ],
        ),
      );
    }

    return VocabularySessionPager(words: session.words);
  }
}
