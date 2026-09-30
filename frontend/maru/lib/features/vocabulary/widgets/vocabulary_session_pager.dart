import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_request.dart';
import '../models/word_card.dart';
import '../providers/vocabulary_provider.dart';
import 'vocabulary_card_item.dart';

/// Word Study / Daily Review 공용 카드 페이저.
/// 평가는 "그 카드의 단어"로 제출하고, 페이지 이동·완료 판정은 PageView 인덱스 기준으로 한다.
class VocabularySessionPager extends ConsumerStatefulWidget {
  final List<WordCard> words;

  const VocabularySessionPager({super.key, required this.words});

  @override
  ConsumerState<VocabularySessionPager> createState() => _VocabularySessionPagerState();
}

class _VocabularySessionPagerState extends ConsumerState<VocabularySessionPager> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _rate(int index, ReviewRating rating) {
    final messenger = ScaffoldMessenger.of(context);
    ref
        .read(vocabularySessionProvider.notifier)
        .submitRating(widget.words[index], rating)
        .then((saved) {
      if (!saved) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't save your rating. Please check your connection.")),
        );
      }
    });
    _advance(index);
  }

  void _advance(int index) {
    if (index >= widget.words.length - 1) {
      ref.read(vocabularySessionProvider.notifier).completeSession();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.words.length,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) => ref.read(vocabularySessionProvider.notifier).setCurrentIndex(index),
      itemBuilder: (context, index) {
        return VocabularyCardItem(
          key: ValueKey(widget.words[index].id),
          word: widget.words[index],
          isLast: index == widget.words.length - 1,
          onRate: (rating) => _rate(index, rating),
          onNext: () => _advance(index),
        );
      },
    );
  }
}
