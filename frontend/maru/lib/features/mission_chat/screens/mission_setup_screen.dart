import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _personalityController = TextEditingController();

  final List<String> _hierarchyOptions = [
    '🎓 They\'re older or higher status (use respectful Korean)',
    '👥 We\'re about the same age or rank (use neutral Korean)',
    '🧒 They\'re younger or lower status (use casual Korean)'
  ];
  final List<String> _intimacyOptions = ['Stranger', 'Acquaintance', 'Close'];
  static const _roleIdeas = ['Cafe staff', 'Boss', 'Professor', 'Taxi driver', 'New friend'];
  static const _personalityIdeas = ['Friendly', 'Strict', 'Shy', 'Cheerful', 'Grumpy'];

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

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Mission Chat', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: state.status == MissionChatStatus.settingUp
          ? SetupTransformLoading(role: _roleController.text)
          : _buildSetupForm(state),
    );
  }

  Widget _buildSetupForm(MissionChatState state) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.groups_rounded,
            title: 'Who are they to you?',
            subtitle: 'This decides how polite your Korean should be.',
            child: Column(
              children: [
                for (final option in _hierarchyOptions) _buildHierarchyTile(option),
              ],
            ),
          ),
          _buildSection(
            icon: Icons.favorite_rounded,
            title: 'How close are you?',
            child: Wrap(
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
                      color: _selectedIntimacy == option ? colors.onPrimary : colors.onSurface,
                    ),
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceContainerLow,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    onSelected: (_) => setState(() => _selectedIntimacy = option),
                  ),
              ],
            ),
          ),
          // Role: free text input
          _buildSection(
            icon: Icons.theater_comedy_rounded,
            title: 'Who should Tokki become?',
            subtitle: 'Type any role — the rabbit will play it.',
            child: _buildTextInput(
              controller: _roleController,
              hint: 'e.g. Cafe Staff, Boss, Professor, anything...',
              ideas: _roleIdeas,
            ),
          ),
          // Personality: free text input
          _buildSection(
            icon: Icons.mood_rounded,
            title: 'Personality',
            child: _buildTextInput(
              controller: _personalityController,
              hint: 'e.g. strict, friendly, shy, cheerful...',
              ideas: _personalityIdeas,
            ),
          ),
          if (state.failedAction == MissionChatAction.setup && state.errorMessage != null)
            Container(
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
                  TextButton(
                    onPressed: () => ref.read(missionChatProvider.notifier).retrySetup(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              ref.read(missionChatProvider.notifier).setupMission({
                'hierarchy': _selectedHierarchy,
                'intimacy': _selectedIntimacy,
                'role': _roleController.text.trim().isEmpty 
                    ? 'any role' 
                    : _roleController.text.trim(),
                'personality': _personalityController.text.trim().isEmpty 
                    ? 'natural' 
                    : _personalityController.text.trim(),
              });
            },
            child: Text(
              'Start Mission 🐰',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: missionHeroGradient(context),
        borderRadius: BorderRadius.circular(missionCardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your scenario',
                  style: TextStyle(color: colors.onPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tokki the rabbit will transform into anyone you like. Chat in Korean to clear the mission!',
                  style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.9), fontSize: 14, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Compact size (<= 56) keeps the motion inside the hero card.
          const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.happy, size: 56),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, String? subtitle, required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
          child,
        ],
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
            fillColor: colors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final idea in ideas)
              ActionChip(
                label: Text(idea),
                labelStyle: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600),
                backgroundColor: colors.primaryContainer.withValues(alpha: 0.5),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  controller.text = idea;
                  controller.selection = TextSelection.collapsed(offset: idea.length);
                }),
              ),
          ],
        ),
      ],
    );
  }
}
