import 'package:flutter/material.dart';
import '../viewmodels/hangeul_view_model.dart';

/// Special widget to visualize linking sound (연음) animation
/// This is the "magic moment" where final consonant moves to next syllable
class LinkingSoundAnimationWidget extends StatefulWidget {
  final CombinedSyllable firstSyllable;
  final CombinedSyllable secondSyllable;
  final VoidCallback? onAnimationComplete;

  const LinkingSoundAnimationWidget({
    Key? key,
    required this.firstSyllable,
    required this.secondSyllable,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<LinkingSoundAnimationWidget> createState() => _LinkingSoundAnimationWidgetState();
}

class _LinkingSoundAnimationWidgetState extends State<LinkingSoundAnimationWidget>
    with TickerProviderStateMixin {

  late AnimationController _moveController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _showPronunciation = false;

  @override
  void initState() {
    super.initState();

    // Animation for moving final consonant
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation for fading text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Slide from first syllable to second
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    ));

    // Fade in pronunciation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animation sequence
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // Wait a moment before starting
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 1: Move the final consonant
    await _moveController.forward();

    // Step 2: Show pronunciation
    setState(() {
      _showPronunciation = true;
    });
    await _fadeController.forward();

    // Wait to let user see the result
    await Future.delayed(const Duration(milliseconds: 1000));

    // Notify completion
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFinalConsonant = widget.firstSyllable.finalConsonant != null;

    if (!hasFinalConsonant) {
      return _buildNormalCombination();
    }

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Text(
            '연음 (Linking Sound)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
            ),
          ),

          const SizedBox(height: 30),

          // Animation area
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // First syllable (base)
                Positioned(
                  left: 40,
                  child: _buildSyllableWithHighlight(
                    widget.firstSyllable.character,
                    highlightFinalConsonant: true,
                  ),
                ),

                // Moving final consonant
                if (hasFinalConsonant)
                  Positioned(
                    left: 40,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildMovingConsonant(
                        widget.firstSyllable.finalConsonant!.character,
                      ),
                    ),
                  ),

                // Second syllable
                Positioned(
                  right: 40,
                  child: _buildSyllableBlock(
                    widget.secondSyllable.character,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Arrow indicator
          const Icon(
            Icons.arrow_downward,
            color: Color(0xFF6366F1),
            size: 32,
          ),

          const SizedBox(height: 20),

          // Pronunciation result
          if (_showPronunciation)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      '실제 발음',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '[${_getLinkedPronunciation()}]',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Explanation
          _buildExplanation(),
        ],
      ),
    );
  }

  /// Build syllable with highlighted final consonant
  Widget _buildSyllableWithHighlight(String syllable, {bool highlightFinalConsonant = false}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightFinalConsonant
              ? const Color(0xFF6366F1)
              : Colors.transparent,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          syllable,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  /// Build syllable block (simple version)
  Widget _buildSyllableBlock(String syllable) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          syllable,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  /// Build moving consonant with glow effect
  Widget _buildMovingConsonant(String consonant) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          consonant,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Build explanation text
  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF6366F1),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '받침이 다음 모음으로 이어져서 발음됩니다',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build normal combination without linking sound
  Widget _buildNormalCombination() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSyllableBlock(widget.firstSyllable.character),
              const SizedBox(width: 20),
              const Icon(Icons.add, size: 32, color: Color(0xFF6B7280)),
              const SizedBox(width: 20),
              _buildSyllableBlock(widget.secondSyllable.character),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.firstSyllable.character}${widget.secondSyllable.character}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get linked pronunciation
  String _getLinkedPronunciation() {
    // Example: 먹어 → 머거
    final firstPart = widget.firstSyllable.consonant.sound +
        widget.firstSyllable.vowel.sound;
    final secondPart = widget.firstSyllable.finalConsonant!.sound +
        widget.secondSyllable.vowel.sound;

    return firstPart + secondPart;
  }
}