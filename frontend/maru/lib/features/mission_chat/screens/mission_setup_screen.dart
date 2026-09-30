import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: state.status == MissionChatStatus.settingUp
          ? _buildLoadingState()
          : _buildSetupForm(state),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            '🐰',
            style: TextStyle(fontSize: 64),
          ),
          SizedBox(height: 16),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Getting ready to transform...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
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
              backgroundColor: Colors.teal,
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
            child: const Text(
              'Start Mission 🐰',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection(String title, List<String> options, String selectedValue, Function(String) onSelect) {
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
              border: Border.all(color: Colors.grey.shade300),
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
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
