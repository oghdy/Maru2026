import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/core/utils/tts_helper.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../models/ai_lab_model.dart';
import '../providers/ai_lab_provider.dart';
import '../repositories/ai_lab_repository.dart';
import '../utils/korean_word_wrap.dart';
import '../widgets/lab_experiment_loading.dart';

/// Explore category: [key] is sent to the server, [label] is the English UI label and
/// [korean] the Korean grammar term shown small next to it.
class _ExploreCategory {
  final String key;
  final String label;
  final String korean;

  const _ExploreCategory(this.key, this.label, this.korean);
}

/// Combine option: [label] is the English UI label, [korean] the value sent to the server (API_CONTRACT §1-2).
class _Modifier {
  final String label;
  final String korean;

  const _Modifier(this.label, this.korean);
}

class _ModifierGroup {
  final String label;
  final String korean;
  final List<_Modifier> options;

  const _ModifierGroup(this.label, this.korean, this.options);
}

/// The two Grammar Lab features (feedback R4 #1: must be told apart at a glance).
enum _LabMode { explore, combine }

// Sentence Lab (UI name) == AI Grammar Lab (legacy code name). Code identifiers stay (D-24).
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

  /// One-line hint of what each explore rule changes (shown on its tile).
  static const Map<String, String> _categoryHints = {
    'tense': 'past · present · future',
    'politeness': 'formal ↔ casual',
    'negation': '안 · 못 · -지 않다',
    'emotion': 'add feeling & tone',
  };

  static const List<_ModifierGroup> _modifierGroups = [
    _ModifierGroup('Tense', '시제', [_Modifier('Past', '과거'), _Modifier('Present', '현재'), _Modifier('Future', '미래')]),
    _ModifierGroup('Politeness', '높임', [_Modifier('Polite', '존댓말'), _Modifier('Casual', '반말')]),
    _ModifierGroup('Sentence type', '문장 유형', [
      _Modifier('Statement', '평서문'),
      _Modifier('Question', '의문문'),
      _Modifier('Exclamation', '감탄문'),
    ]),
    _ModifierGroup('Negation', '부정', [_Modifier('Positive', '긍정문'), _Modifier('Negative', '부정문')]),
  ];

  _LabMode _mode = _LabMode.explore;
  _ExploreCategory? _selectedCategory; // explore: one rule
  // combine: at most one modifier per group (index = group), null = not used.
  final List<_Modifier?> _combineSelection = List.filled(_modifierGroups.length, null);

  @override
  void initState() {
    super.initState();
    // Run button label / enabled state follows the typed sentence.
    _inputController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _loadingTimer?.cancel();
    TtsHelper.stop();
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
    _selectedCategory = category; // switching rule in the result view carries back to the form
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

    final selected = _combineSelection.whereType<_Modifier>().toList();
    final List<String> backendModifiers = [for (final m in selected) m.korean];

    if (backendModifiers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select at least one modifier to combine.')));
      return;
    }

    _activeCategory = null;
    _activeModifierLabels = [for (final m in selected) m.label];
    _startLoading(
      text,
      backendModifiers.length == 1 ? 'Applying 1 rule' : 'Combining ${backendModifiers.length} rules',
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
    TtsHelper.stop();
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
        // Wrap between words (어절), not syllables. Copy / TTS below use the original [sentence].
        Expanded(child: Text(koreanKeepAll(sentence), style: style)),
        IconButton(
          tooltip: 'Listen',
          visualDensity: VisualDensity.compact,
          color: cs.primary,
          icon: const Icon(Icons.volume_up_outlined),
          // Server voice (natural, cached) with device-voice fallback; stops any previous clip.
          onPressed: () => TtsHelper.speak(sentence),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // In the result view, back returns to the input form instead of leaving the lab.
      canPop: !_showingResults,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToEditor();
      },
      child: Scaffold(
        backgroundColor: _pageBackground(context),
        appBar: AppBar(
          title: const Text('Sentence Lab'),
          elevation: 0,
          backgroundColor: _pageBackground(context),
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          // The form's run bar paints into the home-indicator area itself.
          bottom: _showingResults,
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

  // Design tokens shared with the Vocabulary / Mission redesigns (mission LOG_fe HANDOFF).
  static Color _pageBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Color.alphaBlend(cs.primary.withValues(alpha: 0.06), cs.surface);
  }

  BoxDecoration _cardDecoration() {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 5))],
    );
  }

  Widget _sectionTitle(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8, color: cs.onSurfaceVariant),
    );
  }

  Widget _buildComposeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSentenceCard(),
                const SizedBox(height: 22),
                _sectionTitle('Choose an experiment'),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _modeCard(
                          _LabMode.explore,
                          icon: Icons.call_split_rounded,
                          title: 'Explore',
                          subtitle: 'One rule, 3 variations',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _modeCard(
                          _LabMode.combine,
                          icon: Icons.layers_rounded,
                          title: 'Combine',
                          subtitle: 'Mix rules into 1 sentence',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _mode == _LabMode.explore
                      ? KeyedSubtree(key: const ValueKey('explore'), child: _buildExploreOptions())
                      : KeyedSubtree(key: const ValueKey('combine'), child: _buildCombineOptions()),
                ),
              ],
            ),
          ),
        ),
        _buildRunBar(),
      ],
    );
  }

  /// Common input card on top of both modes, with the turtle waiting for a sentence.
  Widget _buildSentenceCard() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // C4 (CHARACTER_API §3.4): idle turtle waits for a sentence. 14 top = 0.25×56 jump room.
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: MaruCharacter(kind: MaruCharacterKind.turtle, outfit: MaruOutfit.lab, size: 56),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your sentence', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'Type a Korean sentence for the turtle to experiment with.',
                        style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _inputController,
            maxLength: _maxInputLength,
            // Counter only when getting close to the server limit.
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                currentLength > 150 ? Text('$currentLength/$maxLength') : null,
            style: textTheme.titleMedium,
            decoration: InputDecoration(
              hintText: 'e.g. 저는 밥을 먹어요',
              filled: true,
              fillColor: _pageBackground(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              suffixIcon: _inputController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => _inputController.clear(),
                    ),
            ),
          ),
          // Tap-to-fill examples, light and in one swipeable row.
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Try', style: textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                for (final example in _exampleSentences)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(example),
                      labelStyle: textTheme.labelLarge?.copyWith(color: cs.onPrimaryContainer),
                      backgroundColor: cs.primaryContainer.withValues(alpha: 0.6),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                      onPressed: _isLoading
                          ? null
                          : () {
                              _inputController.text = example;
                              _inputController.selection = TextSelection.collapsed(offset: example.length);
                            },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeCard(_LabMode mode, {required IconData icon, required String title, required String subtitle}) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = _mode == mode;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: _cardDecoration().copyWith(
            color: selected ? cs.primary : cs.surface,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: selected ? 0.28 : 0.08),
                blurRadius: selected ? 18 : 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? cs.onPrimary.withValues(alpha: 0.18) : cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: selected ? cs.onPrimary : cs.primary),
                  ),
                  const Spacer(),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 20,
                    color: selected ? cs.onPrimary : cs.outlineVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: selected ? cs.onPrimary.withValues(alpha: 0.85) : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Explore: pick exactly one rule (2×2 tiles).
  Widget _buildExploreOptions() {
    Widget tile(_ExploreCategory cat) {
      final cs = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      final selected = _selectedCategory == cat;
      return Expanded(
        child: Material(
          color: selected ? cs.primaryContainer : _pageBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? cs.primary : Colors.transparent, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _selectedCategory = selected ? null : cat),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bilingualLabel(
                    cat.label,
                    cat.korean,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.onPrimaryContainer : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _categoryHints[cat.key] ?? '',
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Pick one rule'),
          const SizedBox(height: 12),
          Row(children: [tile(_categories[0]), const SizedBox(width: 10), tile(_categories[1])]),
          const SizedBox(height: 10),
          Row(children: [tile(_categories[2]), const SizedBox(width: 10), tile(_categories[3])]),
        ],
      ),
    );
  }

  /// Combine: up to one option per group; tapping a selected option clears that group.
  Widget _buildCombineOptions() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Pick rules to mix · one per row'),
          for (var g = 0; g < _modifierGroups.length; g++) ...[
            const SizedBox(height: 12),
            _bilingualLabel(
              _modifierGroups[g].label,
              _modifierGroups[g].korean,
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final option in _modifierGroups[g].options)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: _combineSelection[g] == option,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      color: _combineSelection[g] == option ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                    backgroundColor: cs.surface,
                    selectedColor: cs.primaryContainer,
                    labelStyle: textTheme.labelLarge?.copyWith(
                      color: _combineSelection[g] == option ? cs.onPrimaryContainer : cs.onSurface,
                    ),
                    onSelected: (_) =>
                        setState(() => _combineSelection[g] = _combineSelection[g] == option ? null : option),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The single run button at the bottom; its label says what will happen (or what is missing).
  Widget _buildRunBar() {
    final cs = Theme.of(context).colorScheme;
    final hasText = _inputController.text.trim().isNotEmpty;
    final ruleCount = _combineSelection.whereType<_Modifier>().length;

    final String label;
    final bool ready;
    if (_mode == _LabMode.explore) {
      ready = _selectedCategory != null;
      label = ready ? 'Explore ${_selectedCategory!.label}' : 'Pick a rule to explore';
    } else {
      ready = ruleCount > 0;
      label = !ready ? 'Pick rules to combine' : (ruleCount == 1 ? 'Apply 1 rule' : 'Combine $ruleCount rules');
    }
    final enabled = ready && hasText && !_isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ready && !hasText)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Type or pick a sentence first.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          FilledButton.icon(
            key: const ValueKey('lab-run'),
            onPressed: enabled
                ? () => _mode == _LabMode.explore ? _onExploreCategory(_selectedCategory!) : _onCombine()
                : null,
            icon: const Icon(Icons.science_rounded),
            label: Text(label),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
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

  Widget _buildLoading() => LabExperimentLoading(task: _loadingLabel, seconds: _loadingSeconds);

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
              // C4 (CHARACTER_API §3.4): sad turtle replaces the error icon (24 padding above = 0.25×96 jump room).
              // Message + Retry / Edit sentence stay below.
              MaruCharacter(
                kind: MaruCharacterKind.turtle,
                outfit: MaruOutfit.lab,
                mood: MaruMood.sad,
                size: 96,
                reactionKey: _errorMessage,
              ),
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
                    // C3 (CHARACTER_API §3.4): turtle "explains" the result, then settles to idle.
                    MaruCharacter(
                      kind: MaruCharacterKind.turtle,
                      outfit: MaruOutfit.lab,
                      mood: MaruMood.talking,
                      size: 64,
                      settleToIdleAfter: const Duration(milliseconds: 2000),
                      reactionKey: _combineResult,
                    ),
                    const SizedBox(width: 12),
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
          // C4 (CHARACTER_API §3.4): idle turtle waits for a sentence.
          const MaruCharacter(kind: MaruCharacterKind.turtle, outfit: MaruOutfit.lab, size: 96),
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
