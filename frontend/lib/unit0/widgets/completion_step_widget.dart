import 'package:flutter/material.dart';

/// Completion step widget
/// Displays lesson completion message
class CompletionStepWidget extends StatelessWidget {
  final Map<String, dynamic> content;

  const CompletionStepWidget({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            // Title
            Text(
              content['title']?.toString() ?? 'Lesson Complete!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              content['message']?.toString() ?? 'Great job!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'NotoSansKR',
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),

            // Additional content (optional)
            if (content['achievement'] != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      content['achievement']?.toString() ?? '',
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

