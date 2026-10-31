import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../../core/utils/tts_helper.dart';
import 'lesson_style.dart';
import 'morphological_text_chunk.dart';
import '../utils/hangul.dart';

class IntroductionStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onNext;

  const IntroductionStepWidget({
    super.key,
    required this.content,
    required this.onNext,
  });

  @override
  State<IntroductionStepWidget> createState() => _IntroductionStepWidgetState();
}

class _IntroductionStepWidgetState extends State<IntroductionStepWidget> {
  ColorScheme get cs => Theme.of(context).colorScheme;

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  Map<String, dynamic>? _selectedChunk;
  // Which chunk is selected, by position — the same word can appear in several sentences
  int? _selectedSentence;
  int? _selectedChunkIndex;

  /// The open analysis panel, to scroll it into view when it opens low on the screen.
  /// A new key per selection: the previous panel is still fading out when the next one opens.
  GlobalKey _panelKey = GlobalKey();

  @override
  void dispose() {
    _pageController.dispose();
    TtsHelper.stop();
    super.dispose();
  }

  // Server voice (OpenAI TTS) with device-voice fallback — see TtsHelper
  void _speak(String text) => TtsHelper.speak(text);

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    }
  }

  void _goToNextPage(int totalItems) {
    if (_currentPageIndex < totalItems - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentences = widget.content['sentences'] as List<dynamic>? ?? [];
    final explanation = widget.content['explanation'] as Map<String, dynamic>? ?? {};
    final items = widget.content['items'] as List<dynamic>? ?? [];
    final hasItems = items.isNotEmpty;

    // Fallback for Legacy Unit 1 (If no items array exists, just show the old list view)
    if (!hasItems) {
      return _buildLegacyUnit1View(sentences, explanation);
    }

    return Column(
      children: [
        // PageView for Flashcards
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
              // Auto play sound on page change
              final item = items[index] as Map<String, dynamic>;
              _speak(item['jamo'] as String? ?? '');
            },
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              final jamo = item['jamo'] as String? ?? '';
              final romanization = item['romanization'] as String? ?? '';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    // Main Flashcard
                    Container(
                      height: 190, // Leaves room for the facts card below
                      width: double.infinity,
                      decoration: missionCardDecoration(context),
                      child: Stack(
                        children: [
                          // Big Character (center). Whole words scale down to fit the card.
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 34, 20, 14),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  jamo,
                                  style: TextStyle(fontSize: 88, fontWeight: FontWeight.w800, color: cs.onSurface),
                                ),
                              ),
                            ),
                          ),
                          // Small romanization badge (top left)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: MissionPill(
                              label: romanization,
                              background: cs.primaryContainer,
                              foreground: cs.onPrimaryContainer,
                            ),
                          ),
                          // TTS Button (top right)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: LessonSpeakerButton(onPressed: () => _speak(jamo)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Facts about this character (derived from the character itself)
                    _buildLetterFacts(item),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Navigation Area
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Position indicator (display only — navigate with the buttons below or swipe)
              Row(
                children: [
                  Expanded(
                    child: LessonProgressBar(value: (_currentPageIndex + 1) / items.length, height: 6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentPageIndex + 1} / ${items.length}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Final Step Action Buttons
              Row(
                children: [
                  Expanded(
                    child: LessonSecondaryButton(
                      label: 'Previous',
                      onPressed: _currentPageIndex > 0 ? _goToPreviousPage : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LessonPrimaryButton(
                      // Next moves to the next card; on the last card it continues the lesson
                      label: _currentPageIndex == items.length - 1 ? 'Continue' : 'Next',
                      onPressed: _currentPageIndex == items.length - 1 ? widget.onNext : () => _goToNextPage(items.length),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Card under the big letter. Uses `description`/`tip` from the data when present,
  /// otherwise states facts computed from the character (type, parts, how it's written).
  Widget _buildLetterFacts(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final jamo = item['jamo'] as String? ?? '';
    final romanization = item['romanization'] as String? ?? '';
    final description = (item['description'] as String? ?? '').trim();
    final tip = (item['tip'] as String? ?? '').trim();

    final kind = hangulKind(jamo);
    final label = switch (kind) {
      HangulKind.vowel => 'Vowel',
      HangulKind.consonant => 'Consonant',
      HangulKind.syllable => 'Syllable block',
      HangulKind.word => 'Word',
      HangulKind.other => '',
    };

    final facts = <String>[];
    if (romanization.isNotEmpty) facts.add('Sounds like: [$romanization]');
    switch (kind) {
      case HangulKind.vowel:
        final parts = combinedFrom(jamo);
        if (parts != null) facts.add('Written by combining ${parts.join(' + ')}');
        final alone = withSilentO(jamo);
        if (alone != null) facts.add('On its own it is written with a silent ㅇ: $alone');
      case HangulKind.consonant:
        final parts = combinedFrom(jamo);
        if (parts != null) facts.add('Written by doubling/combining ${parts.join(' + ')}');
        final ga = withVowelA(jamo);
        if (ga != null) facts.add('Needs a vowel to make a sound: $jamo + ㅏ = $ga');
      case HangulKind.syllable:
        final p = decomposeSyllable(jamo);
        if (p != null) {
          facts.add('Built from: ${p.letters.join(' + ')}');
          if (p.finalConsonant.isNotEmpty) facts.add('Bottom consonant (batchim): ${p.finalConsonant}');
        }
      case HangulKind.word:
        for (final ch in jamo.split('')) {
          final p = decomposeSyllable(ch);
          if (p != null) facts.add('$ch = ${p.letters.join(' + ')}');
        }
      case HangulKind.other:
        break;
    }
    if (description.isNotEmpty) facts.insert(0, description);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: missionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            MissionPill(label: label, background: colorScheme.primaryContainer, foreground: colorScheme.primary),
          ...facts.map((f) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(f, style: TextStyle(fontSize: 15, height: 1.4, color: colorScheme.onSurface)),
              )),
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, size: 18, color: lessonStar()),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(tip, style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _onChunkTap(int sentenceIndex, int chunkIndex, Map<String, dynamic> chunk) {
    HapticFeedback.selectionClick();
    final opening = !(_selectedSentence == sentenceIndex && _selectedChunkIndex == chunkIndex);
    setState(() {
      if (opening) {
        _panelKey = GlobalKey();
        _selectedSentence = sentenceIndex;
        _selectedChunkIndex = chunkIndex;
        _selectedChunk = chunk;
      } else {
        _clearSelection(); // Toggle off
      }
    });
    if (!opening) return;
    // Once the panel has opened, make sure it isn't hidden below the fold
    Future.delayed(lessonMotion(context, 230), () {
      final panel = _panelKey.currentContext;
      if (mounted && panel != null && panel.mounted) {
        Scrollable.ensureVisible(
          panel,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  // Fallback for Unit 1 sentence lists (unchanged content, just extracted out)
  Widget _buildLegacyUnit1View(List<dynamic> sentences, Map<String, dynamic> explanation) {
    final patterns = explanation['patterns'] as List<dynamic>? ?? [];
    final canAnalyze = sentences.any((s) {
      final chunks = (s as Map<String, dynamic>)['chunks'] as List<dynamic>? ?? [];
      return chunks.any((c) => ((c as Map<String, dynamic>)['tokens'] as List<dynamic>? ?? []).isNotEmpty);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (explanation.containsKey('title'))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      explanation['title'] ?? 'Introduction',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                if (canAnalyze)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_rounded, size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tap a word to see its parts',
                            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (sentences.isNotEmpty)
                  ...sentences.asMap().entries.map((entry) {
                    final sentenceIndex = entry.key;
                    final sentence = entry.value as Map<String, dynamic>;
                    final hasTts = sentence['tts'] == true;
                    final showPanel = _selectedChunk != null && _selectedSentence == sentenceIndex;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: missionCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sentence.containsKey('chunks'))
                                      MorphologicalTextChunk(
                                        chunks: sentence['chunks'] as List<dynamic>,
                                        selectedIndex: _selectedSentence == sentenceIndex ? _selectedChunkIndex : null,
                                        onChunkTap: (chunkIndex, chunk) => _onChunkTap(sentenceIndex, chunkIndex, chunk),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          sentence['korean'] ?? '',
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        sentence['english'] ?? '',
                                        style: TextStyle(fontSize: 15, height: 1.35, color: cs.onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasTts) ...[
                                const SizedBox(width: 8),
                                LessonSpeakerButton(size: 44, onPressed: () => _speak(sentence['korean'] ?? '')),
                              ],
                            ],
                          ),
                          // Analysis panel right under the sentence that was tapped
                          LessonReveal(
                            alignment: Alignment.topCenter,
                            child: showPanel ? _buildHintPanel() : null,
                          ),
                        ],
                      ),
                    );
                  }),
                if (patterns.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: missionCardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Patterns', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        ...patterns.map((p) {
                          final pattern = p as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pattern['pattern'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  '${pattern['level']} - ${pattern['usage']}',
                                  style: TextStyle(fontSize: 13, height: 1.35, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: LessonPrimaryButton(label: 'Continue', onPressed: widget.onNext),
        ),
      ],
    );
  }

  void _clearSelection() {
    _selectedChunk = null;
    _selectedSentence = null;
    _selectedChunkIndex = null;
  }

  Widget _buildHintPanel() {
    final tokens = _selectedChunk?['tokens'] as List<dynamic>? ?? [];
    return Container(
      // A new word cross-fades instead of jumping
      key: ValueKey('panel_${_selectedSentence}_$_selectedChunkIndex'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        key: _panelKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 44, interactive: false),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LessonOverline('Grammar Analysis'),
                    Text(
                      _selectedChunk?['display'] ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: () => setState(_clearSelection),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tokens.map((t) {
            final token = t as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 64),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        token['text'] ?? '',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        token['meaning'] ?? '',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
