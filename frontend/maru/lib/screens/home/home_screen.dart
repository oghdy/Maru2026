import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/lesson/screens/unit_selection_screen.dart';
import '../../features/lab/screens/lab_menu_screen.dart';
import '../../features/stats/providers/user_stats_provider.dart';
import '../../features/vocabulary/screens/vocabulary_category_screen.dart';
import '../../features/vocabulary/providers/vocabulary_provider.dart';
import '../../features/mission_chat/screens/mission_clearance_list_screen.dart';
import '../../features/vocabulary/screens/daily_review_screen.dart';
import '../../features/mission_chat/screens/mission_setup_screen.dart'; // Mission Chat 임포트

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _navigateAndRefresh(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      // 화면에서 돌아왔을 때 홈 통계 갱신
      ref.invalidate(userStatsProvider);
      ref.invalidate(dailyReviewCountProvider);
    });
  }
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Maru', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined, color: Colors.teal), 
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionClearanceListScreen()));
            }
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            tooltip: 'Account',
            onPressed: () => _confirmLogout(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting with the two mascots (CHARACTER_API §3.5, PM-1.6.6).
            // Top padding leaves room for the characters' hops (0.25 × 72).
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Hello! 👋\nLet\'s learn Korean today?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                  MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.idle, size: 72, entrance: true),
                  MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 72, entrance: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats: streak + stars (loading and error are shown, not hidden)
            statsAsync.when(
              data: (stats) => _buildStatsCard(
                children: [
                  _buildStatMini(Icons.local_fire_department, '${stats.currentStreakDays}', Colors.orange),
                  _buildStatMini(Icons.star, '${stats.totalStarsEarned}', Colors.amber),
                ],
              ),
              loading: () => _buildStatsCard(
                children: const [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              error: (err, stack) => _buildInlineError(
                "Couldn't load your progress.",
                onRetry: () => ref.invalidate(userStatsProvider),
              ),
            ),

            // Daily Review Banner (nothing to review → no banner)
            ref.watch(dailyReviewCountProvider).when(
              // Always shown: words due → review banner, none → "All caught up!" card
              data: (count) => count > 0
                  ? _buildDailyReviewBanner(context, count)
                  : _buildAllCaughtUpCard(context),
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (err, stack) => _buildInlineError(
                "Couldn't check today's word reviews.",
                onRetry: () => ref.invalidate(dailyReviewCountProvider),
              ),
            ),
            
            const SizedBox(height: 16),

            // 4 feature cards: soft pastel per feature, one-line description (feedback R4).
            // Rows size to their content (no empty space under the icon).
            _buildCardRow(
              _buildGridCard(
                context: context,
                title: 'Korean Lessons',
                description: 'Build sentences block by block',
                icon: Icons.school_outlined,
                hue: _hueLessons,
                onTap: () => _navigateAndRefresh(context, const UnitSelectionScreen()),
              ),
              _buildGridCard(
                context: context,
                title: 'Language Lab',
                description: 'Ask AI about Korean grammar',
                icon: Icons.science_outlined,
                hue: _hueLab,
                onTap: () => _navigateAndRefresh(context, const LabMenuScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildCardRow(
              _buildGridCard(
                context: context,
                title: 'Mission Chat',
                description: 'Role-play real-life conversations',
                icon: Icons.chat_bubble_outline,
                hue: _hueMission,
                onTap: () => _navigateAndRefresh(context, const MissionSetupScreen()),
              ),
              _buildGridCard(
                context: context,
                title: 'Vocabulary Review',
                description: 'Learn new words, review daily',
                icon: Icons.auto_awesome_motion_outlined,
                hue: _hueVocab,
                onTap: () => _navigateAndRefresh(context, const VocabularyCategoryScreen()),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// The person icon used to log out immediately (easy to hit by accident).
  Future<void> _confirmLogout(BuildContext context) async {
    final nickname = ref.read(profileProvider).asData?.value?.nickname;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          nickname != null && nickname.isNotEmpty
              ? "You're signed in as $nickname."
              : 'You will need to sign in again to continue learning.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  /// Shown instead of the review banner when no words are due (user feedback R3 #6).
  Widget _buildAllCaughtUpCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () => _navigateAndRefresh(context, const DailyReviewScreen()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All caught up!',
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nothing due today — learn new words in Vocabulary',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReviewBanner(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () {
          // Task 27-5에서 구현할 화면으로 이동
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyReviewScreen()));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8A84FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_stories, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Word Review',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'word' : 'words'} ready to review',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: children,
      ),
    );
  }

  /// Small error row with a Retry button (English, no exception text).
  Widget _buildInlineError(String message, {required VoidCallback onRetry}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 20, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: colorScheme.onErrorContainer))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildStatMini(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Feature card hues; every card uses the same lightness/saturation so no colour
  // shouts louder than another. Lessons uses the brand purple (#6B4EFF, hue ~249).
  static const double _hueLessons = 249;
  static const double _hueLab = 335;
  static const double _hueMission = 168;
  static const double _hueVocab = 32;

  Widget _buildCardRow(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required double hue,
    required VoidCallback onTap,
  }) {
    final background = HSLColor.fromAHSL(1, hue, 0.70, 0.96).toColor();
    final border = HSLColor.fromAHSL(1, hue, 0.50, 0.90).toColor();
    final accent = HSLColor.fromAHSL(1, hue, 0.55, 0.48).toColor();
    final ink = HSLColor.fromAHSL(1, hue, 0.30, 0.18).toColor();
    final subtle = HSLColor.fromAHSL(1, hue, 0.15, 0.40).toColor();
    final radius = BorderRadius.circular(20);

    return Material(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: accent, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: subtle.withValues(alpha: 0.7), size: 20),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.25, color: ink),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12.5, height: 1.3, color: subtle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

