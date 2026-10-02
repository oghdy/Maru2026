import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../widgets/lab_glassware.dart';
import 'lab_screen.dart'; // Sentence Lab (UI name) == AI Grammar Lab (legacy code name)
import 'hangeul_lab_screen.dart'; // Hangeul Lab

/// Language Lab menu: a lab notebook page with two experiment benches,
/// each run by its lab partner (Hangeul Lab = rabbit, Sentence Lab = turtle).
class LabMenuScreen extends StatefulWidget {
  const LabMenuScreen({super.key});

  @override
  State<LabMenuScreen> createState() => _LabMenuScreenState();
}

class _LabMenuScreenState extends State<LabMenuScreen> with SingleTickerProviderStateMixin {
  // One slow loop drives every bubble on the page.
  late final AnimationController _bubbles = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion (and widget tests): still glassware.
    if (MediaQuery.of(context).disableAnimations) {
      _bubbles.stop();
    } else if (!_bubbles.isAnimating) {
      _bubbles.repeat();
    }
  }

  @override
  void dispose() {
    _bubbles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pageBackground = Color.alphaBlend(cs.primary.withValues(alpha: 0.06), cs.surface);
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Language Lab', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: LabGraphPaper()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(44, 8, 16, 24), // 44 = right of the notebook margin
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: notebook title + bubbling glassware on the shelf.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LAB NOTEBOOK',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pick an\nexperiment bench',
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Two benches, two lab partners.',
                              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _shelf(cs),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _LabBenchCard(
                    character: MaruCharacterKind.rabbit,
                    accent: cs.tertiary,
                    glass: LabGlass.tube,
                    bubbles: _bubbles,
                    partner: 'Rabbit · playful',
                    title: 'Hangeul Lab',
                    subtitle: 'Rabbit mixes consonants and vowels into syllables.',
                    footnote: 'ㄱ + ㅏ = 가',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HangeulLabScreen())),
                  ),
                  const SizedBox(height: 16),
                  _LabBenchCard(
                    character: MaruCharacterKind.turtle,
                    accent: cs.primary,
                    glass: LabGlass.flask,
                    bubbles: _bubbles,
                    partner: 'Turtle · careful',
                    title: 'Sentence Lab',
                    subtitle: 'Turtle experiments with your sentence — tense, politeness, negation.',
                    footnote: 'AI-powered',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Beaker + flask standing on a little shelf line.
  Widget _shelf(ColorScheme cs) {
    return SizedBox(
      width: 112,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LabGlassware(kind: LabGlass.beaker, liquid: cs.tertiary, width: 46, height: 66, bubbles: _bubbles),
              const SizedBox(width: 4),
              LabGlassware(kind: LabGlass.flask, liquid: cs.primary, width: 54, height: 84, bubbles: _bubbles),
            ],
          ),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabBenchCard extends StatelessWidget {
  final MaruCharacterKind character;
  final Color accent;
  final LabGlass glass;
  final Animation<double> bubbles;
  final String partner;
  final String title;
  final String subtitle;
  final String footnote;
  final VoidCallback onTap;

  const _LabBenchCard({
    required this.character,
    required this.accent,
    required this.glass,
    required this.bubbles,
    required this.partner,
    required this.title,
    required this.subtitle,
    required this.footnote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        shadowColor: cs.primary.withValues(alpha: 0.25),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Glassware in the corner, bubbling quietly.
              Positioned(
                right: 12,
                top: 8,
                child: LabGlassware(kind: glass, liquid: accent, width: 34, height: 50, bubbles: bubbles),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // The lab partner standing at its bench. 18 top = 0.25×72 jump room.
                    Container(
                      width: 92,
                      padding: const EdgeInsets.only(top: 18, bottom: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(child: MaruCharacter(kind: character, size: 72)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 36), // clear of the glassware
                            child: Text(
                              partner.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: ShapeDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    footnote,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(color: accent),
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: accent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
