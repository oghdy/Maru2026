import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_lab_model.dart';
import '../providers/ai_lab_provider.dart';

class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({super.key});

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  final TextEditingController _inputController = TextEditingController();
  
  // States
  bool _isLoading = false;
  String? _errorMessage;
  List<AiLabExploreResponseModel> _exploreResults = [];
  AiLabCombineResponseModel? _combineResult;

  // Categories for explore and combine
  final List<String> _categories = [
    'Tense (시제)',
    'Politeness (존댓말)',
    'Negation (부정문)',
    'Emotion (감정)',
  ];

  // Selected values for dropdowns
  String _selectedTense = '—';
  String _selectedPoliteness = '—';
  String _selectedSentenceType = '—';
  String _selectedNegation = '—';

  // Accordion state
  bool _isCombineExpanded = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onExploreCategory(String category) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a sentence first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _exploreResults = [];
      _combineResult = null;
    });

    try {
      final backendCategory = category.split(' ')[0].toLowerCase();
      final request = AiLabExploreRequestModel(
        inputText: text,
        category: backendCategory,
      );

      final results = await ref.read(aiLabRepositoryProvider).explore(request);
      
      if (mounted) {
        setState(() {
          _exploreResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onCombine() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a sentence first.')),
      );
      return;
    }

    final List<String> backendModifiers = [];
    
    if (_selectedTense == 'Past') {
      backendModifiers.add('과거');
    } else if (_selectedTense == 'Future') {
      backendModifiers.add('미래');
    } else if (_selectedTense == 'Present') {
      backendModifiers.add('현재');
    }

    if (_selectedPoliteness == 'Casual') {
      backendModifiers.add('반말');
    } else if (_selectedPoliteness == 'Polite') {
      backendModifiers.add('존댓말');
    }

    if (_selectedSentenceType == 'Interrogative') {
      backendModifiers.add('의문문');
    } else if (_selectedSentenceType == 'Exclamatory') {
      backendModifiers.add('감탄문');
    } else if (_selectedSentenceType == 'Declarative') {
      backendModifiers.add('평서문');
    }

    if (_selectedNegation == 'Negative') {
      backendModifiers.add('부정문');
    } else if (_selectedNegation == 'Positive') {
      backendModifiers.add('긍정문');
    }

    if (backendModifiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one modifier to combine.')),
      );
      return;
    }

    setState(() {
      _isCombineExpanded = false; // Collapse the accordion on search
      _isLoading = true;
      _errorMessage = null;
      _exploreResults = [];
      _combineResult = null;
    });

    try {
      final request = AiLabCombineRequestModel(
        inputText: text,
        modifiers: backendModifiers,
      );

      final result = await ref.read(aiLabRepositoryProvider).combine(request);
      
      if (mounted) {
        setState(() {
          _combineResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Lab 🧪'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Input Area
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter a Korean sentence:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 저는 밥을 먹어요',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _inputController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Explore Section
                  const Text('Explore Variations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(cat),
                            backgroundColor: Colors.blue.shade50,
                            onPressed: () => _onExploreCategory(cat),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const Divider(height: 32),
                  
                  // Combine Section
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCombineExpanded = !_isCombineExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Combine Modifiers', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(
                                _isCombineExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _onCombine,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Combine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isCombineExpanded) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Tense',
                            value: _selectedTense,
                            items: const ['—', 'Past', 'Present', 'Future'],
                            onChanged: (val) {
                              setState(() {
                                _selectedTense = val!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Politeness',
                            value: _selectedPoliteness,
                            items: const ['—', 'Polite', 'Casual'],
                            onChanged: (val) {
                              setState(() {
                                _selectedPoliteness = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Sentence Type',
                            value: _selectedSentenceType,
                            items: const ['—', 'Declarative', 'Interrogative', 'Exclamatory'],
                            onChanged: (val) {
                              setState(() {
                                _selectedSentenceType = val!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Negation',
                            value: _selectedNegation,
                            items: const ['—', 'Positive', 'Negative'],
                            onChanged: (val) {
                              setState(() {
                                _selectedNegation = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Results Area
            Expanded(
              child: _buildResultsArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gemini is thinking... ✨', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    if (_combineResult != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.deepPurple.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.deepPurple.shade200, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 8),
                    Text('Combined Result', style: TextStyle(color: Colors.deepPurple.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_combineResult!.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_combineResult!.englishTranslation, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),
                Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900)),
                const SizedBox(height: 8),
                Text(_combineResult!.explanation, style: const TextStyle(height: 1.5, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
    }

    if (_exploreResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _exploreResults.length,
        itemBuilder: (context, index) {
          final res = _exploreResults[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(res.type, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  Text(res.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(res.explanation, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          );
        },
      );
    }

    // Empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Enter text and select a rule to explore!', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
