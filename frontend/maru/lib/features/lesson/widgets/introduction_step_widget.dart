import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("ko-KR");
  }

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  Map<String, dynamic>? _selectedChunk;

  @override
  void dispose() {
    _pageController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _goToNextPage(int totalItems) {
    if (_currentPageIndex < totalItems - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Main Flashcard
                      Container(
                        height: 170, // Leaves room for the facts card below
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Small romanization badge (top left)
                            Positioned(
                              top: 24,
                              left: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(romanization, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            // TTS Button (top right)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.volume_up, color: cs.primary),
                                ),
                                onPressed: () => _speak(jamo),
                              ),
                            ),
                            // Big Character (center)
                            Center(
                              child: Text(
                                jamo,
                                style: const TextStyle(fontSize: 88, fontWeight: FontWeight.w900, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Facts about this character (derived from the character itself)
                      _buildLetterFacts(item),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Navigation Area
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 16.0),
          child: Column(
            children: [
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPageIndex == index ? cs.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: _currentPageIndex > 0 ? Colors.grey.shade700 : Colors.grey.shade300, size: 32),
                    onPressed: _currentPageIndex > 0 ? _goToPreviousPage : null,
                  ),
                  Text(
                    '${_currentPageIndex + 1} / ${items.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: _currentPageIndex < items.length - 1 ? cs.primary : Colors.grey.shade300, size: 32),
                    onPressed: () => _goToNextPage(items.length),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Final Step Action Buttons
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                         if (_currentPageIndex > 0) {
                           _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                         } 
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: cs.primary,
                      ),
                      child: const Text('Previous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentPageIndex == items.length - 1 ? widget.onNext : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_currentPageIndex == items.length - 1 ? 'Continue' : 'Next', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),
          ...facts.map((f) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(f, style: TextStyle(fontSize: 15, height: 1.4, color: colorScheme.onSurface)),
              )),
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('💡 $tip', style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  // Fallback for Unit 1 sentence lists (unchanged content, just extracted out)
  Widget _buildLegacyUnit1View(List<dynamic> sentences, Map<String, dynamic> explanation) {
     final patterns = explanation['patterns'] as List<dynamic>? ?? [];
     return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (explanation.containsKey('title'))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  explanation['title'] ?? 'Introduction',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          if (sentences.isNotEmpty)
            ...sentences.map((s) {
              final sentence = s as Map<String, dynamic>;
              final hasTts = sentence['tts'] == true;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sentence.containsKey('chunks'))
                              MorphologicalTextChunk(
                                chunks: sentence['chunks'] as List<dynamic>,
                                selectedChunkDisplay: _selectedChunk?['display'],
                                onChunkTap: (chunk) {
                                  setState(() {
                                    if (_selectedChunk?['display'] == chunk['display']) {
                                      _selectedChunk = null; // Toggle off
                                    } else {
                                      _selectedChunk = chunk;
                                    }
                                  });
                                },
                              )
                            else
                              Text(
                                sentence['korean'] ?? '',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              sentence['english'] ?? '',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (hasTts)
                        IconButton(
                          icon: Icon(Icons.volume_up, color: cs.primary),
                          onPressed: () => _speak(sentence['korean'] ?? ''),
                        ),
                    ],
                  ),
                ),
              );
            }),

          // Hint Panel for Morphology
          if (_selectedChunk != null) _buildHintPanel(),
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Patterns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...patterns.map((p) {
              final pattern = p as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(pattern['pattern'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${pattern['level']} - ${pattern['usage']}'),
              );
            }),
          ],
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.white,
              backgroundColor: cs.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHintPanel() {
    final tokens = _selectedChunk?['tokens'] as List<dynamic>? ?? [];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.12),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Grammar Analysis",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
                    ),
                    Text(
                      _selectedChunk?['display'] ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cs.primary),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, color: Colors.grey.shade400),
                onPressed: () => setState(() => _selectedChunk = null),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),
          ...tokens.map((t) {
            final token = t as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Text(
                    token['text'] ?? '',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: cs.primary,
                      fontFamily: 'NanumGothic', // Optional: emphasize Korean font
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      token['meaning'] ?? '',
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

