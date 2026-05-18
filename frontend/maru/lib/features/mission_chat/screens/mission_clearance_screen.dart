import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mission_chat_provider.dart';

class MissionClearanceScreen extends ConsumerStatefulWidget {
  const MissionClearanceScreen({super.key});

  @override
  ConsumerState<MissionClearanceScreen> createState() => _MissionClearanceScreenState();
}

class _MissionClearanceScreenState extends ConsumerState<MissionClearanceScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionChatProvider);
    final clearance = state.clearance;

    if (clearance == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Certificate')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Mission Cleared! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(missionChatProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildPage1Summary(clearance),
                _buildPage2GoodExpressions(clearance),
                _buildPage3AreasForImprovement(clearance),
                _buildPage4TutorsNote(clearance, context),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.teal : Colors.grey.shade300,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          border: Border.all(color: Colors.yellow.shade700, width: 2),
        ),
        child: child,
      ),
    );
  }

  Widget _buildPage1Summary(clearance) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'CERTIFICATE OF COMPLETION',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('Mission:', clearance.missionTitle),
          _buildInfoRow('Persona:', clearance.persona),
          _buildInfoRow('Total Turns:', '${clearance.totalTurns} turns'),
          _buildInfoRow('Status:', 'Cleared 🎉'),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Swipe left to see feedback →',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2GoodExpressions(clearance) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('✨ Great Expressions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 24),
          if (clearance.goodExpressions.isEmpty)
            const Text('No expressions to highlight this time.', style: TextStyle(color: Colors.grey))
          else
            ...clearance.goodExpressions.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${e.expression}"', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(e.reason, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPage3AreasForImprovement(clearance) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('📝 Areas for Improvement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 24),
          if (clearance.incorrectExpressions.isEmpty)
            const Text('Perfect! No major corrections needed.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
          else
            ...clearance.incorrectExpressions.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('❌ ${e.wrong}', style: TextStyle(color: Colors.red.shade400, decoration: TextDecoration.lineThrough, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('✅ ${e.correct}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(e.explanation, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPage4TutorsNote(clearance, BuildContext context) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🐢', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tutor\'s Note', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(clearance.turtleComment, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 Next Goal:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 4),
                Text(clearance.nextPractice, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref.read(missionChatProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Return to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
