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

/// Faces currently drawn by the code placeholder.
List<MaruMood> placeholderFaces(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<CharacterPlaceholderPainter>()
    .map((p) => p.face)
    .toList();

/// Asset names of the character images on screen.
List<String> imageAssets(WidgetTester tester) => tester.widgetList<Image>(find.byType(Image)).map((img) {
      var provider = img.image;
      if (provider is ResizeImage) provider = provider.imageProvider;
      return (provider as AssetImage).assetName;
    }).toList();

double liftOf(WidgetTester tester) {
  final t = tester.widget<Transform>(
    find.descendant(of: find.byType(MaruCharacter), matching: find.byType(Transform)).first,
  );
  return -t.transform.getTranslation().y;
}

Future<void> pumpFor(WidgetTester tester, int ms, {int step = 20}) async {
  for (var t = 0; t < ms; t += step) {
    await tester.pump(Duration(milliseconds: step));
  }
}

Future<double> maxLift(WidgetTester tester, int ms) async {
  var best = 0.0;
  for (var t = 0; t < ms; t += 20) {
    await tester.pump(const Duration(milliseconds: 20));
    final l = liftOf(tester);
    if (l > best) best = l;
  }
  return best;
}

String png(String name) => '${CharacterAssets.dir}$name.png';

void main() {
  tearDown(() {
    CharacterAssets.debugSetAvailable(null);
    CharacterAssets.forcePlaceholder.value = false;
  });

  group('asset fallback', () {
    testWidgets('no PNGs → code placeholder for every mood, no exceptions', (tester) async {
      CharacterAssets.debugSetAvailable(<String>{});
      for (final kind in MaruCharacterKind.values) {
        for (final mood in MaruMood.values) {
          await tester.pumpWidget(app(MaruCharacter(key: UniqueKey(), kind: kind, mood: mood)));
          await pumpFor(tester, 200);
          expect(tester.takeException(), isNull);
          expect(find.byType(Image), findsNothing);
          expect(placeholderFaces(tester), [mood], reason: '${kind.name} ${mood.name}');
        }
      }
    });

    testWidgets('all PNGs → exact mood image, blink layer on idle only', (tester) async {
      CharacterAssets.debugSetAvailable({
        for (final k in MaruCharacterKind.values) ...[
          for (final m in MaruMood.values) png('${k.name}_${m.name}'),
          png('${k.name}_blink'),
        ],
      });
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.sad)));
      await pumpFor(tester, 200);
      expect(imageAssets(tester), [png('turtle_sad')]);
      expect(placeholderFaces(tester), isEmpty);

      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.turtle)));
      await pumpFor(tester, 800);
      expect(imageAssets(tester), [png('turtle_idle'), png('turtle_blink')]);
    });

    testWidgets('some PNGs → missing mood uses idle image, missing kind uses placeholder', (tester) async {
      CharacterAssets.debugSetAvailable({png('rabbit_idle'), png('rabbit_happy')});
      await tester.pumpWidget(app(const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.happy, size: 100),
          MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.sad, size: 100),
          MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.sad, size: 100),
        ],
      )));
      await pumpFor(tester, 200);
      expect(tester.takeException(), isNull);
      // No blink PNG → no blink layer, just the faces.
      expect(imageAssets(tester), [png('rabbit_happy'), png('rabbit_idle')]);
      expect(placeholderFaces(tester), [MaruMood.sad]);
    });

    testWidgets('Force placeholder overrides existing PNGs', (tester) async {
      CharacterAssets.debugSetAvailable({png('rabbit_idle')});
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit)));
      await pumpFor(tester, 100);
      expect(find.byType(Image), findsOneWidget);
      CharacterAssets.forcePlaceholder.value = true;
      await pumpFor(tester, 200);
      expect(find.byType(Image), findsNothing);
      expect(placeholderFaces(tester), [MaruMood.idle]);
    });
  });

  group('motion', () {
    setUp(() => CharacterAssets.debugSetAvailable(<String>{}));

    testWidgets('mood change swaps the face and plays the entry jump', (tester) async {
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit, size: 100)));
      await pumpFor(tester, 300);
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.happy, size: 100)));
      expect(await maxLift(tester, 900), greaterThan(8)); // spec h .12 → 12px
      await pumpFor(tester, 300);
      expect(placeholderFaces(tester), [MaruMood.happy]);
    });

    testWidgets('same mood + new reactionKey replays the reaction', (tester) async {
      Widget build(int key) =>
          app(MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.happy, size: 100, reactionKey: key));
      await tester.pumpWidget(build(0));
      await pumpFor(tester, 3000); // entry done, turtle happy loop has no hops
      expect(await maxLift(tester, 600), lessThan(1));
      await tester.pumpWidget(build(1));
      expect(await maxLift(tester, 900), greaterThan(4)); // spec h .06 → 6px
    });

    testWidgets('settleToIdleAfter returns the face to idle, parent mood untouched', (tester) async {
      await tester.pumpWidget(app(const MaruCharacter(
        kind: MaruCharacterKind.rabbit,
        mood: MaruMood.happy,
        settleToIdleAfter: Duration(milliseconds: 500),
      )));
      await pumpFor(tester, 900);
      expect(placeholderFaces(tester), [MaruMood.happy]);
      await pumpFor(tester, 1500);
      expect(placeholderFaces(tester), [MaruMood.idle]);
    });

    testWidgets('tap shows happy for ~900ms then returns', (tester) async {
      var taps = 0;
      await tester.pumpWidget(app(MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.thinking, onTap: () => taps++)));
      await pumpFor(tester, 600);
      await tester.tap(find.byType(MaruCharacter));
      await pumpFor(tester, 300);
      expect(taps, 1);
      expect(placeholderFaces(tester), [MaruMood.happy]);
      await pumpFor(tester, 900);
      expect(placeholderFaces(tester), [MaruMood.thinking]);
    });

    testWidgets('interactive: false ignores taps', (tester) async {
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit, interactive: false)));
      await pumpFor(tester, 200);
      await tester.tap(find.byType(MaruCharacter), warnIfMissed: false);
      await pumpFor(tester, 200);
      expect(placeholderFaces(tester), [MaruMood.idle]);
    });

    testWidgets('cheer spawns confetti at full size, none in compact mode', (tester) async {
      ParticleBurst? burstOf() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<ParticlePainter>()
          .single
          .burst();

      for (final (size, expectBurst) in [(120.0, true), (40.0, false)]) {
        await tester.pumpWidget(app(MaruCharacter(key: UniqueKey(), kind: MaruCharacterKind.rabbit, size: size)));
        await pumpFor(tester, 200);
        await tester.pumpWidget(app(MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.cheer, size: size)));
        var seen = false;
        for (var t = 0; t < 700; t += 20) {
          await tester.pump(const Duration(milliseconds: 20));
          seen |= burstOf() != null;
        }
        expect(seen, expectBurst, reason: 'size $size');
        await pumpFor(tester, 1200);
        expect(burstOf(), isNull, reason: 'burst cleared after 900ms');
      }
    });
  });

  group('reduce motion', () {
    setUp(() => CharacterAssets.debugSetAvailable(<String>{}));

    testWidgets('no transforms, pumpAndSettle finishes, faces still change', (tester) async {
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit, entrance: true), reduceMotion: true));
      await tester.pumpAndSettle();
      expect(liftOf(tester), 0);

      await tester.pumpWidget(app(
        const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.cheer, settleToIdleAfter: Duration(milliseconds: 300)),
        reduceMotion: true,
      ));
      await tester.pump();
      expect(placeholderFaces(tester), [MaruMood.cheer]);
      expect(liftOf(tester), 0);
      await tester.pumpAndSettle(); // ticker only runs for the pending settle, then stops
      expect(placeholderFaces(tester), [MaruMood.idle]);

      await tester.tap(find.byType(MaruCharacter));
      await tester.pump();
      expect(placeholderFaces(tester), [MaruMood.happy]);
      await tester.pumpAndSettle();
      expect(placeholderFaces(tester), [MaruMood.idle]);
      expect(liftOf(tester), 0);
    });
  });

  group('bubble', () {
    setUp(() => CharacterAssets.debugSetAvailable(<String>{}));
    const msg = 'Nice! 는 marks the topic.';

    String visibleText(WidgetTester tester) {
      final rich = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      return (rich.children!.first as TextSpan).text!.replaceAll('⁠', '');
    }

    testWidgets('types ~40 chars/s while talking, then mood + onTypingDone', (tester) async {
      var done = 0;
      await tester.pumpWidget(app(MaruCharacterBubble(
        kind: MaruCharacterKind.turtle,
        mood: MaruMood.happy,
        message: msg,
        onTypingDone: () => done++,
      )));
      await pumpFor(tester, 250);
      expect(visibleText(tester).length, inInclusiveRange(7, 12));
      expect(placeholderFaces(tester), [MaruMood.talking]);
      await pumpFor(tester, 800);
      expect(visibleText(tester), msg);
      expect(done, 1);
      await pumpFor(tester, 300);
      expect(placeholderFaces(tester), [MaruMood.happy]);
    });

    testWidgets('tap while typing shows everything at once', (tester) async {
      var done = 0;
      await tester.pumpWidget(app(MaruCharacterBubble(kind: MaruCharacterKind.rabbit, message: msg, onTypingDone: () => done++)));
      await pumpFor(tester, 100);
      expect(visibleText(tester), isNot(msg));
      await tester.tap(find.byType(Text));
      await tester.pump();
      expect(visibleText(tester), msg);
      await tester.pump();
      expect(done, 1);
    });

    testWidgets('typewriter: false and reduce motion show the full text immediately', (tester) async {
      await tester.pumpWidget(app(const MaruCharacterBubble(kind: MaruCharacterKind.turtle, message: msg, typewriter: false)));
      await tester.pump();
      expect(visibleText(tester), msg);

      await tester.pumpWidget(app(
        const MaruCharacterBubble(key: ValueKey('rm'), kind: MaruCharacterKind.turtle, message: msg),
        reduceMotion: true,
      ));
      await tester.pump();
      expect(visibleText(tester), msg);
      await tester.pumpAndSettle();
    });

    testWidgets('bubble reserves full-text size from the first frame (no layout jump)', (tester) async {
      await tester.pumpWidget(app(const SizedBox(
        width: 320,
        child: MaruCharacterBubble(kind: MaruCharacterKind.turtle, message: 'A long coaching line that wraps onto a few lines.'),
      )));
      await tester.pump();
      final first = tester.getSize(find.byType(Text));
      await pumpFor(tester, 2000);
      expect(tester.getSize(find.byType(Text)), first);
    });
  });

  testWidgets('dispose mid-reaction leaves no pending timers or tickers', (tester) async {
    CharacterAssets.debugSetAvailable(<String>{});
    await tester.pumpWidget(app(const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.cheer, entrance: true),
        MaruCharacterBubble(kind: MaruCharacterKind.turtle, message: 'Bye!'),
      ],
    )));
    await pumpFor(tester, 150);
    await tester.tap(find.byType(MaruCharacter).first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox());
    // flutter_test fails the test if a Timer is pending or a Ticker is still active.
  });
}
