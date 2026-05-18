import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'morphological_text_chunk.dart';

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
        // Title / Instruction area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Text(
                "Let's learn the basic vowels one by one",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Tap each vowel to hear the pronunciation and see the mouth shape",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

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
                        height: 220, // Slightly reduced to help small screens
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
                                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.volume_up, color: Color(0xFF6B4EFF)),
                                ),
                                onPressed: () => _speak(jamo),
                              ),
                            ),
                            // Big Character (center)
                            Center(
                              child: Text(
                                jamo,
                                style: const TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Explanation Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text('Shape: | + • (right) [Example]', style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 12),
                            Text('Mouth shape: Open your mouth wide', style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 '),
                                Expanded(
                                  child: Text(
                                    'This is the most basic vowel!',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                      color: _currentPageIndex == index ? const Color(0xFF6B4EFF) : Colors.grey.shade300,
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
                    icon: Icon(Icons.chevron_right, color: _currentPageIndex < items.length - 1 ? const Color(0xFF6B4EFF) : Colors.grey.shade300, size: 32),
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
                        side: BorderSide(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: const Color(0xFF6B4EFF),
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
                        backgroundColor: const Color(0xFF6B4EFF),
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
                          icon: const Icon(Icons.volume_up, color: Color(0xFF6B4EFF)),
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
              backgroundColor: const Color(0xFF6B4EFF),
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
            color: const Color(0xFF6B4EFF).withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF6B4EFF)),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF6B4EFF)),
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
                color: const Color(0xFF6B4EFF).withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Text(
                    token['text'] ?? '',
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF6B4EFF),
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

