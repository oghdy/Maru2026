import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/vocabulary/word_card.dart';
import '../../../models/vocabulary/review_request.dart';
import '../../../providers/vocabulary_provider.dart';
import '../../../utils/tts_helper.dart';

class VocabularyCardItem extends ConsumerStatefulWidget {
  final WordCard word;
  final VoidCallback onRated;

  const VocabularyCardItem({
    super.key,
    required this.word,
    required this.onRated,
  });

  @override
  ConsumerState<VocabularyCardItem> createState() => _VocabularyCardItemState();
}

class _VocabularyCardItemState extends ConsumerState<VocabularyCardItem> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(_flipController);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: Stack(
        children: [
          // 1. 학습 카드 Area (Flip Animation)
          Center(
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value;
                final isFront = angle < pi / 2;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isFront
                      ? _buildFrontCard()
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi), // Flip content back
                          child: _buildBackCard(),
                        ),
                );
              },
            ),
          ),

          // 2. 하단 평가 버튼 (뒷면일 때만 강조해서 보여주거나, 항상 보여줌)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: _buildRatingBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.word.koreanWord,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          IconButton(
            onPressed: () => TtsHelper.speak(widget.word.koreanWord),
            icon: const Icon(Icons.volume_up, size: 32, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 40),
          const Text(
            'Tap to reveal meaning',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF6C63FF), width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.word.primaryMeaning,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
          ),
          if (widget.word.partOfSpeech != null) ...[
            const SizedBox(height: 8),
            Text(
              '[${widget.word.partOfSpeech}]',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
          const SizedBox(height: 32),
          if (widget.word.exampleSentence != null) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              widget.word.exampleSentence!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              widget.word.exampleTranslation ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ratingButton('Again', Colors.red, ReviewRating.again),
          _ratingButton('Hard', Colors.orange, ReviewRating.hard),
          _ratingButton('Good', Colors.green, ReviewRating.good),
          _ratingButton('Easy', Colors.blue, ReviewRating.easy),
        ],
      ),
    );
  }

  Widget _ratingButton(String label, Color color, ReviewRating rating) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            ref.read(vocabularySessionProvider.notifier).submitRating(rating);
            widget.onRated();
          },
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
