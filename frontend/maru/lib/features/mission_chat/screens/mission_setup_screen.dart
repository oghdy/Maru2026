import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../providers/mission_chat_provider.dart';
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
      appBar: AppBar(
        title: const Text('Mission Chat Setup'),
        elevation: 0,
      ),
      body: state.status == MissionChatStatus.settingUp
          ? _buildLoadingState()
          : _buildSetupForm(state),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top gap for the character's motion (CHARACTER_API 3.0 rule 4).
            const SizedBox(height: 30),
            const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.thinking, size: 120),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Creating your mission...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The AI is writing a scenario and a conversation partner for you. This takes a few seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm(MissionChatState state) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set your scenario',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildDropdownSection('Hierarchy (Relationship)', _hierarchyOptions, _selectedHierarchy, (val) {
            setState(() => _selectedHierarchy = val);
          }),
          _buildDropdownSection('Intimacy', _intimacyOptions, _selectedIntimacy, (val) {
            setState(() => _selectedIntimacy = val);
          }),
          // Role: free text input
          _buildTextInputSection(
            title: 'Role of AI',
            controller: _roleController,
            hint: 'e.g. Cafe Staff, Boss, Professor, anything...',
          ),
          // Personality: free text input
          _buildTextInputSection(
            title: 'Personality',
            controller: _personalityController,
            hint: 'e.g. strict, friendly, shy, cheerful...',
          ),
          if (state.failedAction == MissionChatAction.setup && state.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection(String title, List<String> options, String selectedValue, Function(String) onSelect) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedValue,
                items: options.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onSelect(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputSection({
    required String title,
    required TextEditingController controller,
    required String hint,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
