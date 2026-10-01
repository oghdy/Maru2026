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

  /// `--dart-define=GALLERY_SLOWMO=true` starts in slow motion, so the very first
  /// appearance after a cold start (image decode → fade-in) can be inspected.
  bool _slowMo = const bool.fromEnvironment('GALLERY_SLOWMO');

  @override
  void initState() {
    super.initState();
    if (_slowMo) timeDilation = 5;
  }

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
            const SizedBox(height: 4),
            const _AssetStatus(),
            const _Section('Stage'),
            const _Stage(kind: MaruCharacterKind.rabbit, title: 'Rabbit — performer'),
            const _Stage(kind: MaruCharacterKind.turtle, title: 'Turtle — coach'),
            const _Section('Grid — 12 at once'),
            const _MoodGrid(),
            const _Section('Sizes'),
            const _Sizes(),
            const _Section('Bubbles'),
            const _Bubbles(),
            const _Section('Scenario — lesson flow'),
            const _Scenario(),
            const _Section('Scenario — mission loading'),
            const _MissionLoading(),
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      );
}

/// 2 characters × 6 moods at 96dp — also the "12 on one screen" performance check.
class _MoodGrid extends StatefulWidget {
  const _MoodGrid();

  @override
  State<_MoodGrid> createState() => _MoodGridState();
}

class _MoodGridState extends State<_MoodGrid> {
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelMedium;
    return _Panel(
      child: Column(
        children: [
          for (final kind in MaruCharacterKind.values)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final m in MaruMood.values)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      MaruCharacter(kind: kind, mood: m, size: 96, reactionKey: _replay),
                      Text('${kind.name} · ${m.name}', style: label),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => setState(() => _replay++),
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Replay all'),
          ),
        ],
      ),
    );
  }
}

class _Sizes extends StatefulWidget {
  const _Sizes();

  @override
  State<_Sizes> createState() => _SizesState();
}

class _SizesState extends State<_Sizes> {
  int _pop = 0;

  Widget _sized(MaruCharacterKind kind, double s, TextStyle? label) => Padding(
        padding: EdgeInsets.only(top: s >= 120 ? 30 : 16),
        child: Column(
          children: [
            MaruCharacter(key: ValueKey('$kind-$s-$_pop'), kind: kind, size: s, entrance: _pop > 0),
            // Label never wider than its character (min 56) so a row can't overflow.
            SizedBox(
              width: s < 56 ? 56 : s,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${kind == MaruCharacterKind.rabbit ? '🐰' : '🐢'} ${s.toInt()}${s <= MaruCharacter.compactSize ? ' compact' : ''}',
                  style: label,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelMedium;
    return _Panel(
      child: Column(
        children: [
          // Grouped by size so both characters at all 4 sizes fit one screenshot, no scrolling.
          for (final sizes in const [
            [40.0, 72.0],
            [120.0],
            [180.0],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final kind in MaruCharacterKind.values)
                  for (final s in sizes) _sized(kind, s, label),
              ],
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => setState(() => _pop++),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Pop in (entrance)'),
          ),
        ],
      ),
    );
  }
}

class _Bubbles extends StatefulWidget {
  const _Bubbles();

  @override
  State<_Bubbles> createState() => _BubblesState();
}

class _BubblesState extends State<_Bubbles> {
  int _run = 0;
  String _status = 'typing…';

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MaruCharacterBubble(
            key: ValueKey('coach-$_run'),
            kind: MaruCharacterKind.turtle,
            mood: MaruMood.happy,
            message: 'Nice try! 은/는 marks the topic of the sentence, while 이/가 points at the subject. '
                'Try saying 저는 학생이에요 slowly, one block at a time.',
            onTypingDone: () => setState(() => _status = 'done ✓'),
          ),
          const SizedBox(height: 16),
          MaruCharacterBubble(
            key: ValueKey('rabbit-$_run'),
            kind: MaruCharacterKind.rabbit,
            side: MaruBubbleSide.right,
            message: '안녕하세요! Want to order coffee together? ☕',
          ),
          const SizedBox(height: 16),
          const MaruCharacterBubble(
            kind: MaruCharacterKind.turtle,
            size: 40,
            typewriter: false,
            message: 'Compact 40dp, no typewriter.',
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text('Turtle: $_status', style: Theme.of(context).textTheme.labelMedium),
              FilledButton.tonalIcon(
                onPressed: () => setState(() {
                  _run++;
                  _status = 'typing…';
                }),
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Replay typing'),
              ),
            ],
          ),
          Text(
            'Tap a bubble while typing to show it all.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Mimics the lesson: correct → happy (settles back to idle), wrong → sad, complete → cheer.
class _Scenario extends StatefulWidget {
  const _Scenario();

  @override
  State<_Scenario> createState() => _ScenarioState();
}

class _ScenarioState extends State<_Scenario> {
  MaruMood _mood = MaruMood.idle;
  int _attempt = 0;
  String _coach = 'Pick an answer to see how we react.';
  MaruMood _coachMood = MaruMood.idle;

  void _react(MaruMood mood, String coach, MaruMood coachMood) => setState(() {
        _mood = mood;
        _attempt++;
        _coach = coach;
        _coachMood = coachMood;
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Center(
            child: MaruCharacter(
              kind: MaruCharacterKind.rabbit,
              mood: _mood,
              size: 120,
              reactionKey: _attempt,
              settleToIdleAfter: _mood == MaruMood.happy ? const Duration(milliseconds: 1600) : null,
            ),
          ),
          const SizedBox(height: 12),
          MaruCharacterBubble(kind: MaruCharacterKind.turtle, mood: _coachMood, message: _coach),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
                onPressed: () => _react(MaruMood.happy, 'Correct! 사과 means apple.', MaruMood.happy),
                child: const Text('Correct'),
              ),
              FilledButton.tonal(
                onPressed: () => _react(MaruMood.sad, 'Almost! Listen to the ending: 사과, not 사가.', MaruMood.thinking),
                child: const Text('Wrong'),
              ),
              OutlinedButton(
                onPressed: () => _react(MaruMood.cheer, 'Lesson complete! 잘했어요!', MaruMood.cheer),
                child: const Text('Complete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Which PNGs the app currently sees, plus a button to pick up new ones
/// (hot reload keeps the cached asset list; this re-reads it).
class _AssetStatus extends StatefulWidget {
  const _AssetStatus();

  @override
  State<_AssetStatus> createState() => _AssetStatusState();
}

class _AssetStatusState extends State<_AssetStatus> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    CharacterAssets.changes.addListener(_refresh);
    CharacterAssets.ensureLoaded().then((_) => _refresh());
  }

  @override
  void dispose() {
    CharacterAssets.changes.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    setState(() => _busy = true);
    await CharacterAssets.reload();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final found = (CharacterAssets.availableSync ?? const <String>{})
        .map((p) => p.replaceFirst(CharacterAssets.dir, '').replaceFirst('.png', ''))
        .toList()
      ..sort();
    return Row(
      children: [
        Expanded(
          child: Text(
            found.isEmpty ? 'PNGs: none (placeholders)' : '${found.length} PNGs: ${found.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        TextButton.icon(
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reload assets'),
        ),
      ],
    );
  }
}

/// Preview of the mission setup loading screen (MSN-1.7.7): the rabbit "transforms"
/// into the role while the server prepares the mission.
class _MissionLoading extends StatefulWidget {
  const _MissionLoading();

  @override
  State<_MissionLoading> createState() => _MissionLoadingState();
}

class _MissionLoadingState extends State<_MissionLoading> {
  int _run = 0;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Panel(
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: _loading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MaruCharacter(
                        key: ValueKey('magic-$_run'),
                        kind: MaruCharacterKind.rabbit,
                        mood: MaruMood.magic,
                        size: 120,
                        entrance: true,
                      ),
                      const SizedBox(height: 12),
                      Text('Tokki is transforming into a café barista…', style: text.titleMedium, textAlign: TextAlign.center),
                    ],
                  )
                : Center(child: Text('Tap “Mission loading” to preview.', style: text.bodyMedium)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => setState(() {
                  _loading = true;
                  _run++;
                }),
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('Mission loading'),
              ),
              OutlinedButton(
                onPressed: _loading ? () => setState(() => _loading = false) : null,
                child: const Text('Stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
