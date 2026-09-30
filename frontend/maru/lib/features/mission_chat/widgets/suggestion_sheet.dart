import 'package:flutter/material.dart';
import '../models/suggestion_response.dart';

/// Bottom sheet for the turtle's hints. Owns its loading / error / result states, so
/// dismissing it early never pops anything else.
class SuggestionSheet extends StatefulWidget {
  final Future<List<SuggestionDto>?> Function() load;
  final ValueChanged<SuggestionDto> onPick;

  const SuggestionSheet({super.key, required this.load, required this.onPick});

  @override
  State<SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<SuggestionSheet> {
  late Future<List<SuggestionDto>?> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "🐢 Turtle's Suggestions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<SuggestionDto>?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text('The turtle is thinking of something you could say...',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }
                  final suggestions = snapshot.data;
                  if (suggestions == null || suggestions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Text("Couldn't get suggestions right now.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => setState(() {
                              _future = widget.load();
                            }),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: suggestions.map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => widget.onPick(suggestion),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.korean,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    suggestion.english,
                                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
