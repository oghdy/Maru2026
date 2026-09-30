import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_lab_model.dart';
import '../providers/ai_lab_provider.dart';
import '../repositories/ai_lab_repository.dart';

/// Explore category: [key] is sent to the server, [label] is the English UI label and
/// [korean] the Korean grammar term shown small next to it.
class _ExploreCategory {
  final String key;
  final String label;
  final String korean;

  const _ExploreCategory(this.key, this.label, this.korean);
}

class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({super.key});

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  final TextEditingController _inputController = TextEditingController();

  // States
  bool _isLoading = false;
  String? _errorMessage;
  // Re-runs the request that failed (Retry button).
  VoidCallback? _retryAction;
  // Loading progress: what is being requested and for how long (cache MISS can take ~10-30s).
  String _loadingLabel = '';
  int _loadingSeconds = 0;
  Timer? _loadingTimer;
  List<AiLabExploreResponseModel> _exploreResults = [];
  AiLabCombineResponseModel? _combineResult;

  // Categories for explore and combine
  static const List<_ExploreCategory> _categories = [
    _ExploreCategory('tense', 'Tense', '시제'),
    _ExploreCategory('politeness', 'Politeness', '존댓말'),
    _ExploreCategory('negation', 'Negation', '부정문'),
    _ExploreCategory('emotion', 'Emotion', '감정'),
  ];

  // Selected values for dropdowns
  String _selectedTense = '—';
  String _selectedPoliteness = '—';
  String _selectedSentenceType = '—';
  String _selectedNegation = '—';

  // Accordion state
  bool _isCombineExpanded = false;

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _onExploreCategory(_ExploreCategory category) async {
    if (_isLoading) return; // one request at a time
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a sentence first.')));
      return;
    }

    _startLoading('Exploring ${category.label.toLowerCase()} variations');

    try {
      final request = AiLabExploreRequestModel(inputText: text, category: category.key);

      final results = await ref.read(aiLabRepositoryProvider).explore(request);

      if (mounted) {
        setState(() {
          _exploreResults = results;
          _isLoading = false;
        });
        _loadingTimer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _userMessage(e);
          _retryAction = () => _onExploreCategory(category);
          _isLoading = false;
        });
        _loadingTimer?.cancel();
      }
    }
  }

  void _onCombine() async {
    if (_isLoading) return; // one request at a time
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a sentence first.')));
      return;
    }

    final List<String> backendModifiers = [];

    if (_selectedTense == 'Past') {
      backendModifiers.add('과거');
    } else if (_selectedTense == 'Future') {
      backendModifiers.add('미래');
    } else if (_selectedTense == 'Present') {
      backendModifiers.add('현재');
    }

    if (_selectedPoliteness == 'Casual') {
      backendModifiers.add('반말');
    } else if (_selectedPoliteness == 'Polite') {
      backendModifiers.add('존댓말');
    }

    if (_selectedSentenceType == 'Interrogative') {
      backendModifiers.add('의문문');
    } else if (_selectedSentenceType == 'Exclamatory') {
      backendModifiers.add('감탄문');
    } else if (_selectedSentenceType == 'Declarative') {
      backendModifiers.add('평서문');
    }

    if (_selectedNegation == 'Negative') {
      backendModifiers.add('부정문');
    } else if (_selectedNegation == 'Positive') {
      backendModifiers.add('긍정문');
    }

    if (backendModifiers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select at least one modifier to combine.')));
      return;
    }

    setState(() {
      _isCombineExpanded = false; // Collapse the accordion on search
    });
    _startLoading(
      backendModifiers.length == 1 ? 'Applying 1 modifier' : 'Combining ${backendModifiers.length} modifiers',
    );

    try {
      final request = AiLabCombineRequestModel(inputText: text, modifiers: backendModifiers);

      final result = await ref.read(aiLabRepositoryProvider).combine(request);

      if (mounted) {
        setState(() {
          _combineResult = result;
          _isLoading = false;
        });
        _loadingTimer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _userMessage(e);
          _retryAction = _onCombine;
          _isLoading = false;
        });
        _loadingTimer?.cancel();
      }
    }
  }

  void _startLoading(String label) {
    FocusScope.of(context).unfocus();
    _loadingTimer?.cancel();
    setState(() {
      _isLoading = true;
      _loadingLabel = label;
      _loadingSeconds = 0;
      _errorMessage = null;
      _retryAction = null;
      _exploreResults = [];
      _combineResult = null;
    });
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _loadingSeconds++);
    });
  }

  String _userMessage(Object error) => error is AiLabFailure ? error.message : AiLabFailure.generic.message;

  /// Label rule for grammar terms: English first, Korean term small and lighter.
  Widget _bilingualLabel(String english, String korean, {TextStyle? style}) {
    final base = style ?? Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 14);
    return Text.rich(
      TextSpan(
        text: english,
        style: base,
        children: [
          TextSpan(
            text: '  $korean',
            style: base.copyWith(
              fontSize: (base.fontSize ?? 14) * 0.85,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String korean,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bilingualLabel(
          label,
          korean,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Lab 🧪'), elevation: 0),
      body: SafeArea(
        // One scroll view for the whole page so the input area never overflows on small
        // screens (keyboard up + Combine panel open).
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input Area
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 4), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter a Korean sentence:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'e.g. 저는 밥을 먹어요',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _inputController.clear(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Explore Section
                    const Text('Explore Variations:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in _categories)
                          ActionChip(
                            label: _bilingualLabel(cat.label, cat.korean),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            onPressed: _isLoading ? null : () => _onExploreCategory(cat),
                          ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Combine Section
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isCombineExpanded = !_isCombineExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Combine Modifiers',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isCombineExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _onCombine,
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Combine'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isCombineExpanded) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Tense',
                              korean: '시제',
                              value: _selectedTense,
                              items: const ['—', 'Past', 'Present', 'Future'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedTense = val!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Politeness',
                              korean: '높임',
                              value: _selectedPoliteness,
                              items: const ['—', 'Polite', 'Casual'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedPoliteness = val!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Sentence Type',
                              korean: '문장 유형',
                              value: _selectedSentenceType,
                              items: const ['—', 'Declarative', 'Interrogative', 'Exclamatory'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSentenceType = val!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Negation',
                              korean: '부정',
                              value: _selectedNegation,
                              items: const ['—', 'Positive', 'Negative'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedNegation = val!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Results Area
              _buildResultsArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Cached sentences come back almost instantly; new ones are generated by the AI.
    final String hint;
    if (_loadingSeconds < 3) {
      hint = 'Asking the AI...';
    } else if (_loadingSeconds < 12) {
      hint = 'This sentence is new, so the AI is writing fresh examples.';
    } else {
      hint = 'Almost there. New sentences can take up to 30 seconds.';
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            '$_loadingLabel...',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (_loadingSeconds >= 3) ...[
            const SizedBox(height: 4),
            Text('${_loadingSeconds}s', style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              if (_retryAction != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: _retryAction, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }

    if (_combineResult != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.deepPurple.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.deepPurple.shade200, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Combined Result',
                      style: TextStyle(color: Colors.deepPurple.shade900, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_combineResult!.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _combineResult!.englishTranslation,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider()),
                Text(
                  'Explanation',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900),
                ),
                const SizedBox(height: 8),
                Text(_combineResult!.explanation, style: const TextStyle(height: 1.5, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
    }

    if (_exploreResults.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final res in _exploreResults) _buildExploreCard(res)],
        ),
      );
    }

    return _buildEmptyState();
  }

  Widget _buildExploreCard(AiLabExploreResponseModel res) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                res.type,
                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(res.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(res.explanation, style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.science, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Enter text and select a rule to explore!', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
