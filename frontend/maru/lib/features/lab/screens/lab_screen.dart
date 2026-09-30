import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  // What the result view shows in its summary bar.
  String _requestedText = '';
  _ExploreCategory? _activeCategory; // explore
  List<String> _activeModifierLabels = []; // combine (English labels)
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(0.45);
  }

  List<AiLabExploreResponseModel> _exploreResults = [];
  AiLabCombineResponseModel? _combineResult;

  // Categories for explore and combine
  // Tap-to-fill examples for learners without a Korean keyboard (already cached → instant demo).
  static const List<String> _exampleSentences = ['저는 밥을 먹어요', '강아지가 뛰어요', '매일 아침 커피를 마셔요'];

  // Server rejects longer input with 400 (API_CONTRACT §3, LAB-1.2.3).
  static const int _maxInputLength = 200;

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
    _tts.stop();
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

    _activeCategory = category;
    _activeModifierLabels = [];
    _startLoading(text, 'Exploring ${category.label.toLowerCase()} variations');

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
          _retryAction = _isRetryable(e) ? () => _onExploreCategory(category) : null;
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

    _activeCategory = null;
    _activeModifierLabels = [
      _selectedTense,
      _selectedPoliteness,
      _selectedSentenceType,
      _selectedNegation,
    ].where((label) => label != '—').toList();
    _startLoading(
      text,
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
          _retryAction = _isRetryable(e) ? _onCombine : null;
          _isLoading = false;
        });
        _loadingTimer?.cancel();
      }
    }
  }

  void _startLoading(String text, String label) {
    FocusScope.of(context).unfocus();
    _loadingTimer?.cancel();
    setState(() {
      _requestedText = text;
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

  /// Result view = a request is running or finished (results or error). The input form is hidden
  /// so the results get the whole screen (feedback R2 #4).
  bool get _showingResults =>
      _isLoading || _errorMessage != null || _exploreResults.isNotEmpty || _combineResult != null;

  /// Back to the input form, keeping the typed sentence and selected modifiers.
  void _backToEditor() {
    if (_isLoading) return;
    _tts.stop();
    setState(() {
      _errorMessage = null;
      _retryAction = null;
      _exploreResults = [];
      _combineResult = null;
    });
  }

  /// Korean result sentence with "listen" and "copy" buttons.
  Widget _sentenceWithActions(String sentence, TextStyle style) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(sentence, style: style)),
        IconButton(
          tooltip: 'Listen',
          visualDensity: VisualDensity.compact,
          color: cs.primary,
          icon: const Icon(Icons.volume_up_outlined),
          onPressed: () {
            _tts.stop();
            _tts.speak(sentence);
          },
        ),
        IconButton(
          tooltip: 'Copy',
          visualDensity: VisualDensity.compact,
          color: cs.onSurfaceVariant,
          icon: const Icon(Icons.copy_outlined, size: 20),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: sentence));
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
          },
        ),
      ],
    );
  }

  bool _isRetryable(Object error) => error is! AiLabFailure || error.retryable;

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
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // In the result view, back returns to the input form instead of leaving the lab.
      canPop: !_showingResults,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToEditor();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('AI Grammar Lab'), elevation: 0),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showingResults
                ? KeyedSubtree(key: const ValueKey('results'), child: _buildResultView())
                : KeyedSubtree(key: const ValueKey('compose'), child: _buildComposeView()),
          ),
        ),
      ),
    );
  }

  Widget _buildComposeView() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Area
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter a Korean sentence:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _inputController,
                  maxLength: _maxInputLength,
                  decoration: InputDecoration(
                    hintText: 'e.g. 저는 밥을 먹어요',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => _inputController.clear()),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Try:',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    for (final example in _exampleSentences)
                      ActionChip(
                        label: Text(example),
                        visualDensity: VisualDensity.compact,
                        onPressed: _isLoading
                            ? null
                            : () {
                                _inputController.text = example;
                                _inputController.selection = TextSelection.collapsed(offset: example.length);
                              },
                      ),
                  ],
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

          _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary bar: the original sentence + what was applied, with Edit.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [
              BoxShadow(color: cs.shadow.withValues(alpha: 0.05), offset: const Offset(0, 4), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original', style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(_requestedText, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _backToEditor,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_activeCategory != null)
                // Switch rule in place without going back to the form.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final cat in _categories)
                      ChoiceChip(
                        label: Text(cat.label),
                        selected: cat == _activeCategory,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        labelStyle: Theme.of(context).textTheme.labelMedium,
                        // Selected chip stays enabled-looking; tapping it again does nothing.
                        onSelected: _isLoading
                            ? null
                            : (_) {
                                if (cat != _activeCategory) _onExploreCategory(cat);
                              },
                      ),
                  ],
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in _activeModifierLabels)
                      Chip(
                        label: Text(label),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.primaryContainer,
                        side: BorderSide.none,
                      ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(child: SingleChildScrollView(child: _buildResultsArea())),
      ],
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
              // No retry = the input was rejected → "fix your input" look, not a connection error.
              _retryAction != null
                  ? Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.error, size: 48)
                  : Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              if (_retryAction != null)
                FilledButton.icon(onPressed: _retryAction, icon: const Icon(Icons.refresh), label: const Text('Retry'))
              else
                FilledButton.tonalIcon(
                  onPressed: _backToEditor,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit sentence'),
                ),
            ],
          ),
        ),
      );
    }

    if (_combineResult != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Combined Result',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sentenceWithActions(_combineResult!.text, const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _combineResult!.englishTranslation,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider()),
                Text(
                  'Explanation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
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
      margin: const EdgeInsets.only(bottom: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                res.type,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _sentenceWithActions(res.text, const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                res.explanation,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
              ),
            ),
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
          Icon(Icons.science, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Type or pick a sentence, then choose a rule.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
