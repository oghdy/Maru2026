// CHR-1.7.3: MaruMood.magic (CHARACTER_API v1.2 §2.3).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/shared/characters/maru_character.dart';
import 'package:maru/shared/characters/src/character_assets.dart';
import 'package:maru/shared/characters/src/particles.dart';
import 'package:maru/shared/characters/src/placeholder_painter.dart';

Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion, size: const Size(400, 800)),
        child: Scaffold(body: Center(child: child)),
      ),
    );

String png(String name) => '${CharacterAssets.dir}$name.png';

Matrix4 bodyMatrix(WidgetTester tester) => tester
    .widget<Transform>(find.descendant(of: find.byType(MaruCharacter), matching: find.byType(Transform)).first)
    .transform;

/// Total body rotation (feet tilt + centre spin), −π…π.
double angleOf(WidgetTester tester) {
  final m = bodyMatrix(tester).storage;
  return math.atan2(m[1], m[0]);
}

int burstCount(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<ParticlePainter>()
    .single
    .bursts()
    .length;

List<MaruMood> placeholderFaces(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<CharacterPlaceholderPainter>()
    .map((p) => p.face)
    .toList();

List<String> imageAssets(WidgetTester tester) => tester.widgetList<Image>(find.byType(Image)).map((img) {
      var provider = img.image;
      if (provider is ResizeImage) provider = provider.imageProvider;
      return (provider as AssetImage).assetName;
    }).toList();

/// Max |angle| and max particle-burst count seen while pumping [ms].
Future<({double maxAngle, int maxBursts})> watch(WidgetTester tester, int ms) async {
  var maxAngle = 0.0;
  var maxBursts = 0;
  for (var t = 0; t < ms; t += 20) {
    await tester.pump(const Duration(milliseconds: 20));
    maxAngle = math.max(maxAngle, angleOf(tester).abs());
    maxBursts = math.max(maxBursts, burstCount(tester));
  }
  return (maxAngle: maxAngle, maxBursts: maxBursts);
}

Future<void> enterMagic(WidgetTester tester, {double size = 120, MaruCharacterKind kind = MaruCharacterKind.rabbit}) async {
  await tester.pumpWidget(app(MaruCharacter(kind: kind, size: size)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpWidget(app(MaruCharacter(kind: kind, size: size, mood: MaruMood.magic)));
}

void main() {
  tearDown(() => CharacterAssets.debugSetAvailable(null));

  test('magic is appended — existing enum order unchanged', () {
    expect(MaruMood.values.map((m) => m.name), ['idle', 'happy', 'sad', 'thinking', 'talking', 'cheer', 'magic']);
  });

  group('motion (placeholder)', () {
    setUp(() => CharacterAssets.debugSetAvailable(<String>{}));

    testWidgets('entry: hop with a full turn, then smoke + sparkles; magic face', (tester) async {
      await enterMagic(tester);
      final r = await watch(tester, 1300);
      expect(r.maxAngle, greaterThan(2.5), reason: 'turned past ~145° during the 360° spin');
      expect(r.maxBursts, greaterThanOrEqualTo(2), reason: 'smoke + sparkle bursts on landing');
      expect(placeholderFaces(tester), [MaruMood.magic]);
      // Spin finished → back upright (only the gentle sway remains).
      expect(angleOf(tester).abs(), lessThan(0.15));
    });

    testWidgets('🐢 spins slower than 🐰', (tester) async {
      Future<int> spinEndMs(MaruCharacterKind kind) async {
        await enterMagic(tester, kind: kind);
        var lastBig = 0;
        for (var t = 20; t <= 1600; t += 20) {
          await tester.pump(const Duration(milliseconds: 20));
          if (angleOf(tester).abs() > 0.5) lastBig = t;
        }
        return lastBig;
      }

      final rabbit = await spinEndMs(MaruCharacterKind.rabbit);
      await tester.pumpWidget(const SizedBox());
      final turtle = await spinEndMs(MaruCharacterKind.turtle);
      expect(turtle, greaterThan(rabbit + 150));
    });

    testWidgets('loop: sways, wand twinkles and a mini-transform spin every few seconds', (tester) async {
      await enterMagic(tester);
      await watch(tester, 1300); // entry done
      final loop = await watch(tester, 3400);
      expect(loop.maxAngle, greaterThan(2.5), reason: 'mini-transform 360° within one period (3.2s)');
      expect(loop.maxBursts, greaterThanOrEqualTo(1), reason: 'wand twinkle / small poof');
    });

    testWidgets('compact (40dp): sway only — no spin, no particles', (tester) async {
      await enterMagic(tester, size: 40);
      final r = await watch(tester, 5000);
      expect(r.maxAngle, inExclusiveRange(0.005, deg(4) * 0.6), reason: 'half-amplitude sway, no 360°');
      expect(r.maxBursts, 0);
      expect(placeholderFaces(tester), [MaruMood.magic]);
    });
  });

  testWidgets('reduce motion: still pose, magic face, pumpAndSettle ends', (tester) async {
    CharacterAssets.debugSetAvailable(<String>{});
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit), reduceMotion: true));
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.magic), reduceMotion: true));
    await tester.pumpAndSettle();
    expect(bodyMatrix(tester).isIdentity(), isTrue);
    expect(burstCount(tester), 0);
    expect(placeholderFaces(tester), [MaruMood.magic]);
  });

  group('assets', () {
    Future<List<String>> shown(WidgetTester tester, Set<String> assets, MaruCharacterKind kind) async {
      CharacterAssets.debugSetAvailable(assets);
      await tester.pumpWidget(app(MaruCharacter(key: UniqueKey(), kind: kind, mood: MaruMood.magic)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      return imageAssets(tester);
    }

    testWidgets('rabbit_magic.png when present, else idle image, else placeholder', (tester) async {
      expect(await shown(tester, {png('rabbit_idle'), png('rabbit_magic')}, MaruCharacterKind.rabbit), [png('rabbit_magic')]);
      expect(await shown(tester, {png('rabbit_idle')}, MaruCharacterKind.rabbit), [png('rabbit_idle')]);
      expect(await shown(tester, {png('turtle_idle'), png('rabbit_magic')}, MaruCharacterKind.turtle), [png('turtle_idle')]);
      expect(await shown(tester, <String>{}, MaruCharacterKind.rabbit), isEmpty);
      expect(placeholderFaces(tester), [MaruMood.magic]);
    });

    test('warm-up / precache list includes rabbit_magic', () {
      CharacterAssets.debugSetAvailable({png('rabbit_idle'), png('rabbit_magic'), png('turtle_idle')});
      expect(CharacterAssets.existingFor(MaruCharacterKind.rabbit), contains(png('rabbit_magic')));
      expect(CharacterAssets.existingFor(MaruCharacterKind.turtle), [png('turtle_idle')]);
    });
  });
}

double deg(double d) => d * math.pi / 180;
