import 'package:flutter/material.dart';
import '../../utils/tts_helper.dart';

/// Practice step widget
/// Displays items one by one with detailed explanation
class PracticeStepWidget extends StatefulWidget {
  final Map<String, dynamic> content;

  const PracticeStepWidget({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  State<PracticeStepWidget> createState() => _PracticeStepWidgetState();
}

class _PracticeStepWidgetState extends State<PracticeStepWidget> {
  final TtsHelper _ttsHelper = TtsHelper();
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < (widget.content['items'] as List).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = widget.content['items'] ?? [];
    final String instruction = widget.content['instruction'] ?? 'Follow along';
    final String? subtitle = widget.content['subtitle'];

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: [
              Text(
                instruction,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'NotoSansKR',
                        color: const Color(0xFF6B7280),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        // Main Content Area (PageView)
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildPracticeCard(context, item);
            },
          ),
        ),

        // Navigation Controls & Indicator
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              // Page Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE5E7EB),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              
              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button
                  IconButton(
                    onPressed: _currentIndex > 0 ? _previousPage : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: _currentIndex > 0
                          ? const Color(0xFF6366F1)
                          : Colors.grey[300],
                    ),
                    iconSize: 28,
                  ),
                  
                  // Progress Text
                  Text(
                    '${_currentIndex + 1} / ${items.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  // Next Button
                  IconButton(
                    onPressed: _currentIndex < items.length - 1 ? _nextPage : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: _currentIndex < items.length - 1
                          ? const Color(0xFF6366F1)
                          : Colors.grey[300],
                    ),
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeCard(BuildContext context, dynamic item) {
    // Handle both String and Map items
    String displayText;
    String? name;
    String? description;
    String? tip;

    if (item is Map) {
      displayText = item['character']?.toString() ?? '';
      name = item['name']?.toString();
      
      // Combine various description fields based on what's available
      List<String> details = [];
      if (item['shape'] != null) details.add('Shape: ${item['shape']}');
      if (item['mouth_tip'] != null) details.add('Mouth shape: ${item['mouth_tip']}');
      if (item['tip'] != null) details.add('💡 ${item['tip']}');
      if (item['comparison'] != null) details.add('Comparison: ${item['comparison']}');
      if (item['structure'] != null) details.add('Structure: ${item['structure']}');
      
      description = details.join('\n\n');
    } else {
      displayText = item.toString();
      description = 'Listen and repeat';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big Character Card
          GestureDetector(
            onTap: () async {
              await _ttsHelper.speak(displayText);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text('Playing pronunciation...'),
                    ],
                  ),
                  duration: const Duration(milliseconds: 800),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF6366F1),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 220, // Reduced from 280
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 100, // Reduced from 120
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        fontFamily: 'NotoSansKR',
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                  ),
                  if (name != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B5563),
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Description Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              description ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.5,
                fontFamily: 'NotoSansKR',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
