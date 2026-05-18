import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/jamo_card_widget.dart';
import '../viewmodels/hangeul_view_model.dart';
import 'lesson_screen.dart';

/// Main screen for Unit 0: Hangeul Master
/// New UI Flow: Consonant + Vowel + Combine Button → Result
class HangeulMasterScreen extends ConsumerStatefulWidget {
  const HangeulMasterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HangeulMasterScreen> createState() => _HangeulMasterScreenState();
}

class _HangeulMasterScreenState extends ConsumerState<HangeulMasterScreen>
    with TickerProviderStateMixin {

  late AnimationController _combineAnimationController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // Animation controller for combination effect
    _combineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _combineAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hangeulViewModelProvider);
    final viewModel = ref.read(hangeulViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            _buildHeader(),

            const SizedBox(height: 30),

            // Fixed combination area at top (not scrollable)
            _buildCombinationArea(state, viewModel),

            const SizedBox(height: 20),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Result display area
                    _buildResultArea(state, viewModel),

                    const SizedBox(height: 40),

                    // Consonants section
                    _buildJamoSection(
                      title: 'Consonants',
                      jamoList: state.consonants,
                      viewModel: viewModel,
                      isConsonant: true,
                    ),

                    const SizedBox(height: 30),

                    // Vowels section
                    _buildJamoSection(
                      title: 'Vowels',
                      jamoList: state.vowels,
                      viewModel: viewModel,
                      isConsonant: false,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header with title and subtitle
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Hangeul Lab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Experiment Freely',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Combine consonants and vowels to create characters',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows lesson menu dialog
  void _showLessonMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'Select Lesson',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Vowels (Lessons 1-4)',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              _buildLessonItem(context, '1. Basic Vowels', 'assets/unit0/data/lessons/unit0_lesson1.json', Icons.circle_outlined),
              _buildLessonItem(context, '2. Derived Vowels', 'assets/unit0/data/lessons/unit0_lesson2.json', Icons.circle_outlined),
              _buildLessonItem(context, '3. Remaining Vowels', 'assets/unit0/data/lessons/unit0_lesson3.json', Icons.circle_outlined),
              _buildLessonItem(context, '4. Compound Vowels', 'assets/unit0/data/lessons/unit0_lesson4.json', Icons.circle_outlined),
              
              const Divider(height: 1, indent: 16, endIndent: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Consonants (Lessons 5-8)',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              _buildLessonItem(context, '5. Basic Consonants', 'assets/unit0/data/lessons/unit0_lesson5.json', Icons.abc),
              _buildLessonItem(context, '6. Aspirated Sounds', 'assets/unit0/data/lessons/unit0_lesson6.json', Icons.abc),
              _buildLessonItem(context, '7. Tense Sounds + Special', 'assets/unit0/data/lessons/unit0_lesson7.json', Icons.abc),
              _buildLessonItem(context, '8. Complete Review', 'assets/unit0/data/lessons/unit0_lesson8.json', Icons.refresh),
              
              const Divider(height: 1, indent: 16, endIndent: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Final Consonants (Lessons 9-12)',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              _buildLessonItem(context, '9. Final Consonant Basics', 'assets/unit0/data/lessons/unit0_lesson9.json', Icons.book),
              _buildLessonItem(context, '10. Final Consonant Advanced', 'assets/unit0/data/lessons/unit0_lesson10.json', Icons.book),
              _buildLessonItem(context, '11. Complex Final Consonants', 'assets/unit0/data/lessons/unit0_lesson11.json', Icons.book),
              _buildLessonItem(context, '12. Complete Review', 'assets/unit0/data/lessons/unit0_lesson12.json', Icons.emoji_events),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds individual lesson item
  Widget _buildLessonItem(
    BuildContext context,
    String title,
    String jsonPath,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'NotoSansKR',
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF9CA3AF),
      ),
      onTap: () {
        Navigator.pop(context); // 메뉴 닫기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LessonScreen(jsonPath: jsonPath),
          ),
        );
      },
    );
  }

  /// Builds the progress indicator
  Widget _buildProgressIndicator(HangeulState state) {
    final progress = state.learnedSyllables.length / 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learning Progress',
                style: TextStyle(
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the combination area (Step 1 + Step 2 + Step 3 + Step 4)
  Widget _buildCombinationArea(HangeulState state, HangeulViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // First row: Consonant + Vowel
          Row(
            children: [
              // Step 1: Consonant
              Expanded(
                flex: 2,
                child: _buildDropZone(
                  label: 'Consonant',
                  stepNumber: '1',
                  selectedJamo: state.selectedConsonant,
                  isConsonant: true,
                  onAccept: (jamo) {
                    viewModel.selectConsonant(jamo);
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.add, size: 24, color: Color(0xFF9CA3AF)),
              ),

              // Step 2: Vowel
              Expanded(
                flex: 2,
                child: _buildDropZone(
                  label: 'Vowel',
                  stepNumber: '2',
                  selectedJamo: state.selectedVowel,
                  isConsonant: false,
                  onAccept: (jamo) {
                    viewModel.selectVowel(jamo);
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.add, size: 24, color: Color(0xFF9CA3AF)),
              ),

              // Step 3: Final Consonant (받침)
              Expanded(
                flex: 2,
                child: _buildDropZone(
                  label: 'Final',
                  stepNumber: '3',
                  selectedJamo: state.selectedFinalConsonant,
                  isConsonant: true,
                  isFinalConsonant: true,
                  onAccept: (jamo) {
                    viewModel.selectFinalConsonant(jamo);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Second row: Combine Button
          _buildCombineButton(state, viewModel),
        ],
      ),
    );
  }

  /// Builds individual drop zone
  Widget _buildDropZone({
    required String label,
    required String stepNumber,
    required JamoData? selectedJamo,
    required bool isConsonant,
    bool isFinalConsonant = false,
    required Function(JamoData) onAccept,
  }) {
    return DragTarget<JamoData>(
      onWillAccept: (data) {
        if (isFinalConsonant) {
          return data?.type == 'consonant';
        }
        if (isConsonant) {
          return data?.type == 'consonant';
        } else {
          return data?.type == 'vowel';
        }
      },
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            color: selectedJamo != null
                ? (isConsonant ? const Color(0xFF3B82F6) : const Color(0xFFEC4899)).withOpacity(0.1)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF6366F1)
                  : (selectedJamo != null
                  ? (isConsonant ? const Color(0xFF3B82F6) : const Color(0xFFEC4899))
                  : const Color(0xFFE5E7EB)),
              width: isHovering ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (selectedJamo != null)
                Text(
                  selectedJamo.character,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isConsonant ? const Color(0xFF3B82F6) : const Color(0xFFEC4899),
                  ),
                )
              else
                Icon(
                  Icons.add_circle_outline,
                  size: 28,
                  color: const Color(0xFF9CA3AF),
                ),

              const SizedBox(height: 4),

              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the combine button (Step 4)
  Widget _buildCombineButton(HangeulState state, HangeulViewModel viewModel) {
    final canCombine = state.selectedConsonant != null && state.selectedVowel != null;

    return GestureDetector(
      onTap: canCombine && !_isAnimating
          ? () async {
        setState(() {
          _isAnimating = true;
        });

        // Combine syllables FIRST
        viewModel.combineSyllables();

        // Force UI rebuild to clear boxes
        setState(() {});

        // Wait a frame for UI to update
        await Future.delayed(const Duration(milliseconds: 50));

        // Get the newly created syllable
        final newState = ref.read(hangeulViewModelProvider);

        // Start animation
        _combineAnimationController.forward();

        // Wait for animation
        await Future.delayed(const Duration(milliseconds: 400));

        // Show success popup
        if (newState.combinedSyllables.isNotEmpty) {
          _showCombinedSyllablePopup(newState);
        }

        // Complete animation
        await _combineAnimationController.reverse();

        setState(() {
          _isAnimating = false;
        });
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          gradient: canCombine
              ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: canCombine ? null : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canCombine
              ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: canCombine ? Colors.white : const Color(0xFF9CA3AF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '4',
                style: TextStyle(
                  color: canCombine ? const Color(0xFF6366F1) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Icon(
              _isAnimating ? Icons.hourglass_bottom : Icons.touch_app,
              size: 28,
              color: canCombine ? Colors.white : const Color(0xFF9CA3AF),
            ),

            const SizedBox(width: 8),

            Text(
              _isAnimating ? 'Combining...' : 'Combine!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: canCombine ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the result display area
  Widget _buildResultArea(HangeulState state, HangeulViewModel viewModel) {
    if (state.combinedSyllables.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
        child: Column(
          children: const [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'Combined characters will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'Learned Characters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: state.combinedSyllables.map((syllable) {
              return _buildSyllableBlock(syllable, viewModel);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds individual syllable block
  Widget _buildSyllableBlock(CombinedSyllable syllable, HangeulViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        viewModel.playSyllableSound(syllable);
        _showPronunciationHint(syllable);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: Column(
          children: [
            Text(
              syllable.character,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '[${syllable.pronunciation}]',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section for consonants or vowels
  Widget _buildJamoSection({
    required String title,
    required List<JamoData> jamoList,
    required HangeulViewModel viewModel,
    required bool isConsonant,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: jamoList.map((jamo) {
              return JamoCardWidget(
                jamo: jamo,
                onDragEnd: (details) {
                  // No action needed on drag end
                },
                onDragUpdate: (details) {
                  // No action needed during drag
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Shows pronunciation hint
  void _showPronunciationHint(CombinedSyllable syllable) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pronunciation: [${syllable.pronunciation}]',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFF6366F1),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  /// Shows popup when syllable is successfully combined
  void _showCombinedSyllablePopup(HangeulState state) {
    if (state.combinedSyllables.isEmpty) return;

    final lastSyllable = state.combinedSyllables.last;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Combination Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      lastSyllable.character,
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '[${lastSyllable.pronunciation}]',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
}



