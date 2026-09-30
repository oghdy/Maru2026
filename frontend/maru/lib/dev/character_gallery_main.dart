// Standalone character gallery (no login, no server):
//   flutter run -d <udid> -t lib/dev/character_gallery_main.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../shared/characters/maru_character.dart';
import '../shared/characters/src/character_assets.dart';

void main() => runApp(const CharacterGalleryApp());

class CharacterGalleryApp extends StatelessWidget {
  const CharacterGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6B4EFF);
    return MaterialApp(
      title: 'MARU Characters',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed).copyWith(primary: seed, onPrimary: Colors.white),
      ),
      home: const CharacterGalleryPage(),
    );
  }
}

class CharacterGalleryPage extends StatefulWidget {
  const CharacterGalleryPage({super.key});

  @override
  State<CharacterGalleryPage> createState() => _CharacterGalleryPageState();
}

class _CharacterGalleryPageState extends State<CharacterGalleryPage> {
  bool _reduceMotion = false;
  bool _slowMo = false;

  @override
  void dispose() {
    timeDilation = 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: _reduceMotion || media.disableAnimations),
      child: Scaffold(
        appBar: AppBar(title: const Text('MARU Characters'), backgroundColor: scheme.surfaceContainerLow),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('Reduce motion'),
                  selected: _reduceMotion,
                  onSelected: (v) => setState(() => _reduceMotion = v),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: CharacterAssets.forcePlaceholder,
                  builder: (context, forced, _) => FilterChip(
                    label: const Text('Force placeholder'),
                    selected: forced,
                    onSelected: (v) => CharacterAssets.forcePlaceholder.value = v,
                  ),
                ),
                FilterChip(
                  label: const Text('Slow motion ×5'),
                  selected: _slowMo,
                  onSelected: (v) => setState(() {
                    _slowMo = v;
                    timeDilation = v ? 5 : 1;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _Section('Stage'),
            const _Stage(kind: MaruCharacterKind.rabbit, title: 'Rabbit — performer'),
            const _Stage(kind: MaruCharacterKind.turtle, title: 'Turtle — coach'),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _Stage extends StatefulWidget {
  const _Stage({required this.kind, required this.title});

  final MaruCharacterKind kind;
  final String title;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  MaruMood _mood = MaruMood.idle;
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 40), // headroom for the cheer jump
            Center(
              child: MaruCharacter(
                kind: widget.kind,
                mood: _mood,
                size: 180,
                reactionKey: _replay,
                semanticLabel: widget.kind == MaruCharacterKind.rabbit ? 'Rabbit' : 'Turtle coach',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final m in MaruMood.values)
                  ChoiceChip(
                    label: Text(m.name),
                    selected: _mood == m,
                    onSelected: (_) => setState(() => _mood = m),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _replay++),
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Replay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
