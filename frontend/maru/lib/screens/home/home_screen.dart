import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
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
            onPressed: () {
              ref.read(authProvider.notifier).logout(); 
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hello! 👋\nLet\'s learn Korean today?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 24),
            
            // Existing Stats Widget Integration
            statsAsync.when(
              data: (stats) => Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatMini(Icons.local_fire_department, '${stats.currentStreakDays}', Colors.orange),
                    _buildStatMini(Icons.star, '${stats.totalStarsEarned}', Colors.amber),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            // Daily Review Banner
            ref.watch(dailyReviewCountProvider).when(
              data: (count) => count > 0 
                  ? _buildDailyReviewBanner(context, count) 
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 16),

            // 4 Grid layout
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildGridCard(
                  context: context,
                  title: 'Korean\nLessons',
                  icon: Icons.school_outlined,
                  iconColor: Colors.deepPurple,
                  bgColor: Colors.deepPurple.shade50,
                  onTap: () {
                    _navigateAndRefresh(context, const UnitSelectionScreen());
                  },
                ),
                _buildGridCard(
                  context: context,
                  title: 'Language\nLab',
                  icon: Icons.science_outlined,
                  iconColor: Colors.pink,
                  bgColor: Colors.pink.shade50,
                  onTap: () {
                    _navigateAndRefresh(context, const LabMenuScreen());
                  },
                ),
                _buildGridCard(
                  context: context,
                  title: 'Mission\nChat',
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.teal,
                  bgColor: Colors.teal.shade50,
                  onTap: () {
                    _navigateAndRefresh(context, const MissionSetupScreen());
                  },
                ),
                _buildGridCard(
                  context: context,
                  title: 'Vocabulary\nReview',
                  icon: Icons.auto_awesome_motion_outlined,
                  iconColor: Colors.orange,
                  bgColor: Colors.orange.shade50,
                  onTap: () {
                    _navigateAndRefresh(context, const VocabularyCategoryScreen());
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
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
                      '$count words ready to review',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
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

  Widget _buildStatMini(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
              ],
            )
          ],
        ),
      ),
    );
  }
}

