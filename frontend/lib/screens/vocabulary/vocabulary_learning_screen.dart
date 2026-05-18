import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vocabulary_provider.dart';
import 'widgets/vocabulary_card_item.dart';

class VocabularyLearningScreen extends ConsumerStatefulWidget {
  final String deckTitle;

  const VocabularyLearningScreen({super.key, required this.deckTitle});

  @override
  ConsumerState<VocabularyLearningScreen> createState() => _VocabularyLearningScreenState();
}

class _VocabularyLearningScreenState extends ConsumerState<VocabularyLearningScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vocabularySessionProvider);

    return Scaffold(
      backgroundColor: Colors.black, // 릴스/쇼츠 느낌을 위해 검은색 배경
      appBar: AppBar(
        title: Text(widget.deckTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
              'Congrats! Completed!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical, // 수직 스와이프
      itemCount: session.words.length,
      physics: const BouncingScrollPhysics(), // 쫀득한 스크롤 느낌
      onPageChanged: (index) {
        // 만약 수동 스와이프로 넘겼을 때의 처리 (평점 없이 넘기기 등)
        // 여기서는 그냥 인덱스만 동기화할 수도 있고, 
        // 평점 버튼으로만 넘어가게 고정할 수도 있습니다.
      },
      itemBuilder: (context, index) {
        final word = session.words[index];
        return VocabularyCardItem(
          word: word,
          onRated: () {
            // 버튼 클릭으로 평점 제출 후 다음 페이지로 애니메이션
            if (index < session.words.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        );
      },
    );
  }
}
