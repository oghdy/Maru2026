import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lesson/widgets/lesson_style.dart';
import '../models/mission_difficulty.dart';
import '../models/mission_scenario.dart';
import '../providers/mission_chat_provider.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../widgets/clearance_style.dart';
import '../widgets/setup_transform_loading.dart';
import 'mission_chat_screen.dart';

class MissionSetupScreen extends ConsumerStatefulWidget {
  const MissionSetupScreen({super.key});

  @override
  ConsumerState<MissionSetupScreen> createState() => _MissionSetupScreenState();
}

class _MissionSetupScreenState extends ConsumerState<MissionSetupScreen> {
  String _selectedHierarchy = '👥 We\'re about the same age or rank (use neutral Korean)';
  String _selectedIntimacy = 'Acquaintance';
  // R4 feedback: missions felt too hard, so new missions start on Easy.
  MissionDifficulty _selectedDifficulty = MissionDifficulty.easy;
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _personalityController = TextEditingController();

  final List<String> _hierarchyOptions = [
    '🎓 They\'re older or higher status (use respectful Korean)',
    '👥 We\'re about the same age or rank (use neutral Korean)',
    '🧒 They\'re younger or lower status (use casual Korean)'
  ];
  // Short form of each option above, for the closed relationship row.
  static const _hierarchyShort = ['Older or higher status', 'About the same age', 'Younger or lower status'];
  final List<String> _intimacyOptions = ['Stranger', 'Acquaintance', 'Close'];
  static const _roleIdeas = ['Cafe staff', 'Boss', 'Professor', 'Taxi driver'];
  static const _personalityIdeas = ['Friendly', 'Strict', 'Shy', 'Cheerful', 'Grumpy'];
  bool _relationshipOpen = false;
  // Set while a scenario card starts (no AI, almost instant), so the form stays up instead of the
  // transform animation flashing by. A failed start shows its error under that card.
  String? _startedScenarioId;

  @override
  void dispose() {
    _roleController.dispose();
    _personalityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionChatProvider);

    // Navigate to Chat Screen when setup is complete
    ref.listen<MissionChatState>(missionChatProvider, (previous, next) {
      if (next.status == MissionChatStatus.chatting &&
          previous?.status != MissionChatStatus.chatting) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MissionChatScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: missionPageBackground(context),
      appBar: AppBar(
        backgroundColor: missionPageBackground(context),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Mission Chat', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: state.status == MissionChatStatus.settingUp && _startedScenarioId == null
          ? SetupTransformLoading(role: _roleController.text)
          : _buildSetupForm(state),
    );
  }

  void _startFreeInput() {
    FocusScope.of(context).unfocus();
    setState(() => _startedScenarioId = null);
    ref.read(missionChatProvider.notifier).setupMission({
      'hierarchy': _selectedHierarchy,
      'intimacy': _selectedIntimacy,
      'difficulty': _selectedDifficulty.apiValue,
      'role': _roleController.text.trim().isEmpty 
          ? 'any role' 
          : _roleController.text.trim(),
      'personality': _personalityController.text.trim().isEmpty 
          ? 'natural' 
          : _personalityController.text.trim(),
    });
  }

  void _startScenario(MissionScenario scenario) {
    FocusScope.of(context).unfocus();
    setState(() => _startedScenarioId = scenario.id);
    ref.read(missionChatProvider.notifier).setupMission({
      'scenarioId': scenario.id,
      'difficulty': _selectedDifficulty.apiValue,
    });
  }

  Widget _buildSetupForm(MissionChatState state) {
    final busy = state.status == MissionChatStatus.settingUp;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(),
          const SizedBox(height: 12),
          _buildRelationship(),
          const SizedBox(height: 12),
          _buildDifficulty(),
          if (_startedScenarioId == null) _buildSetupError(state),
          LessonPrimaryButton(label: 'Start Mission 🐰', onPressed: busy ? null : _startFreeInput),
          const SizedBox(height: 28),
          _buildQuickStart(state),
        ],
      ),
    );
  }

  Widget _buildSetupError(MissionChatState state) {
    if (state.failedAction != MissionChatAction.setup || state.errorMessage == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Couldn't create your mission. ${state.errorMessage}",
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          if (state.limitReached)
            TextButton(
              onPressed: () {
                ref.read(missionChatProvider.notifier).reset();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Leave'),
            )
          else
            TextButton(
              onPressed: () => ref.read(missionChatProvider.notifier).retrySetup(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  // The main thing on this screen: the learner makes up the situation.
  Widget _buildHero() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: missionHeroGradient(context),
        borderRadius: BorderRadius.circular(missionCardRadius),
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
                    Text(
                      'Make your own situation',
                      style: TextStyle(color: colors.onPrimary, fontSize: 22, height: 1.2, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tokki the rabbit becomes anyone you like. Then chat in Korean!',
                      style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.9), fontSize: 13.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compact size (<= 56) keeps the motion inside the hero card.
              const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.happy, size: 56),
            ],
          ),
          const SizedBox(height: 14),
          _buildHeroLabel('Who should Tokki become?'),
          _buildTextInput(
            controller: _roleController,
            hint: 'A barista, a pirate, your boss...',
            ideas: _roleIdeas,
          ),
          const SizedBox(height: 14),
          _buildHeroLabel('Personality'),
          _buildTextInput(
            controller: _personalityController,
            hint: 'e.g. strict, friendly, shy, cheerful...',
            ideas: _personalityIdeas,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  // Closed by default: it has a sensible default and the role is what matters first.
  Widget _buildRelationship() {
    final colors = Theme.of(context).colorScheme;
    final summary = '${_hierarchyShort[_hierarchyOptions.indexOf(_selectedHierarchy)]} · $_selectedIntimacy';
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _relationshipOpen = !_relationshipOpen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  MissionIconTile(icon: Icons.groups_rounded, color: colors.primary, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your relationship', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(summary, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _relationshipOpen ? 0.5 : 0,
                    duration: lessonMotion(context, 200),
                    child: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_relationshipOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This decides how polite your Korean should be.',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                for (final option in _hierarchyOptions) _buildHierarchyTile(option),
                const SizedBox(height: 6),
                const Text('How close are you?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _intimacyOptions)
                      ChoiceChip(
                        label: Text(option),
                        selected: _selectedIntimacy == option,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _selectedIntimacy == option ? colors.onPrimary : colors.onPrimaryContainer,
                        ),
                        selectedColor: colors.primary,
                        backgroundColor: colors.primaryContainer,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        onSelected: (_) => setState(() => _selectedIntimacy = option),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
    return Container(
      decoration: missionCardDecoration(context),
      clipBehavior: Clip.antiAlias,
      // AnimatedSize can't run with a zero duration.
      child: lessonReduceMotion(context)
          ? body
          : AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: body,
            ),
    );
  }

  Widget _buildDifficulty() {
    final colors = Theme.of(context).colorScheme;
    return _buildSection(
      icon: Icons.signal_cellular_alt_rounded,
      title: 'How hard should it be?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final d in MissionDifficulty.values) ...[
                if (d != MissionDifficulty.values.first) const SizedBox(width: 8),
                Expanded(child: _buildDifficultyTile(d)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(_selectedDifficulty.description, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  // Ready-made situations: a shortcut below free input, which keeps working if these fail to load.
  Widget _buildQuickStart(MissionChatState state) {
    final colors = Theme.of(context).colorScheme;
    final scenarios = ref.watch(missionScenariosProvider);
    final list = scenarios.value;
    if (list != null && list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Or jump right in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          'Ready-made situations. Tap one to start on ${_selectedDifficulty.label}.',
          style: TextStyle(fontSize: 13.5, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (list != null)
          for (final scenario in list) ...[
            _buildScenarioCard(scenario, state),
            if (_startedScenarioId == scenario.id) _buildSetupError(state),
          ]
        else if (scenarios.hasError)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: missionCardDecoration(context),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Couldn't load these. You can still make your own above.",
                    style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(missionScenariosProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
      ],
    );
  }

  static const _scenarioIcons = {
    'cafe': Icons.local_cafe_rounded,
    'restaurant': Icons.restaurant_rounded,
    'store': Icons.storefront_rounded,
    'taxi': Icons.local_taxi_rounded,
    'directions': Icons.signpost_rounded,
    'hospital': Icons.local_hospital_rounded,
    'friends': Icons.people_rounded,
    'roommate': Icons.bed_rounded,
    'work': Icons.work_rounded,
    'school': Icons.school_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'hotel': Icons.hotel_rounded,
  };

  Widget _buildScenarioCard(MissionScenario scenario, MissionChatState state) {
    final colors = Theme.of(context).colorScheme;
    final busy = state.status == MissionChatStatus.settingUp;
    final meta = TextStyle(fontSize: 12.5, height: 1.3, color: colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LessonPressable(
        onTap: busy ? null : () => _startScenario(scenario),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: missionCardDecoration(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MissionIconTile(
                icon: _scenarioIcons[scenario.icon] ?? Icons.chat_bubble_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.25)),
                    const SizedBox(height: 3),
                    Text(scenario.description, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                    const SizedBox(height: 6),
                    Text('${scenario.roleEn} · ${scenario.personalityEn}', style: meta),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (busy && _startedScenarioId == scenario.id)
                const Padding(
                  padding: EdgeInsets.all(3),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, String? subtitle, required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: missionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MissionIconTile(icon: icon, color: colors.primary, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildDifficultyTile(MissionDifficulty d) {
    final colors = Theme.of(context).colorScheme;
    final selected = _selectedDifficulty == d;
    return Semantics(
      selected: selected,
      child: LessonPressable(
        onTap: () => setState(() => _selectedDifficulty = d),
        child: AnimatedContainer(
          duration: lessonMotion(context, 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? colors.primary : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Text(d.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                d.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: selected ? colors.primary : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Option strings stay exactly as before (they are sent to the server); only the display is split:
  // "🎓 They're older or higher status (use respectful Korean)" → emoji · title · hint.
  Widget _buildHierarchyTile(String option) {
    final colors = Theme.of(context).colorScheme;
    final selected = _selectedHierarchy == option;
    final space = option.indexOf(' ');
    final emoji = option.substring(0, space);
    final rest = option.substring(space + 1);
    final paren = rest.indexOf(' (');
    final title = paren < 0 ? rest : rest.substring(0, paren);
    final hint = paren < 0 ? null : rest.substring(paren + 2, rest.length - 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _selectedHierarchy = option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? colors.primary : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (hint != null)
                        Text(
                          hint[0].toUpperCase() + hint.substring(1),
                          style: TextStyle(fontSize: 13, color: selected ? colors.primary : colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? colors.primary : colors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    required List<String> ideas,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primaryContainer, width: 2),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final idea in ideas)
              LessonPressable(
                onTap: () => setState(() {
                  controller.text = idea;
                  controller.selection = TextSelection.collapsed(offset: idea.length);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    idea,
                    style: TextStyle(fontSize: 12.5, color: colors.onPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
