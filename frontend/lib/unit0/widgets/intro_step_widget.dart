import 'package:flutter/material.dart';

/// Introduction step widget
/// Displays concept introduction with title, description, and optional image
class IntroStepWidget extends StatelessWidget {
  final Map<String, dynamic> content;

  const IntroStepWidget({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image (optional)
          if (content['image'] != null)
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Image.asset(
                content['image'] as String,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Color(0xFF9CA3AF),
                    ),
                  );
                },
              ),
            ),

          // Title
          if (content['title'] != null)
            Text(
              content['title'] as String,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 24),

          // Description
          if (content['description'] != null)
            Text(
              content['description'] as String,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'NotoSansKR',
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),

          // Additional content (optional)
          if (content['additional_info'] != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      content['additional_info'] as String,
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

