import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/shared/characters/maru_character.dart';
import 'package:maru/shared/characters/src/character_assets.dart';
import 'package:maru/shared/characters/src/placeholder_painter.dart';

Widget app(Widget child) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: Scaffold(body: Center(child: child)),
      ),
    );

List<String> imageAssets(WidgetTester tester) =>
    tester.widgetList<Image>(find.byType(Image)).map((img) => (img.image as AssetImage).assetName).toList();

List<CharacterPlaceholderPainter> placeholders(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<CharacterPlaceholderPainter>()
    .toList();

String png(String name) => '${CharacterAssets.dir}$name.png';

Future<void> pumpFor(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 20) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  tearDown(() {
    CharacterAssets.debugSetAvailable(null);
    CharacterAssets.forcePlaceholder.value = false;
  });

  test('public API: MaruOutfit order, default outfit is normal (existing calls unchanged)', () {
    expect(MaruOutfit.values, [MaruOutfit.normal, MaruOutfit.lab]);
    expect(const MaruCharacter(kind: MaruCharacterKind.rabbit).outfit, MaruOutfit.normal);
    expect(const MaruCharacterBubble(kind: MaruCharacterKind.turtle, message: 'hi').outfit, MaruOutfit.normal);
  });

  group('lab fallback chain', () {
    Future<List<String>> shown(WidgetTester tester, Set<String> assets, MaruMood mood,
        {MaruCharacterKind kind = MaruCharacterKind.rabbit, MaruOutfit outfit = MaruOutfit.lab}) async {
      CharacterAssets.debugSetAvailable(assets);
      await tester.pumpWidget(app(MaruCharacter(key: UniqueKey(), kind: kind, mood: mood, outfit: outfit)));
      await pumpFor(tester, 200);
      expect(tester.takeException(), isNull);
      return imageAssets(tester);
    }

    testWidgets('lab_<mood> → lab_idle → <mood> → idle → placeholder', (tester) async {
      final all = {png('rabbit_lab_happy'), png('rabbit_lab_idle'), png('rabbit_happy'), png('rabbit_idle')};
      expect(await shown(tester, all, MaruMood.happy), [png('rabbit_lab_happy')]);
      expect(await shown(tester, all..remove(png('rabbit_lab_happy')), MaruMood.happy), [png('rabbit_lab_idle')]);
      expect(await shown(tester, all..remove(png('rabbit_lab_idle')), MaruMood.happy), [png('rabbit_happy')]);
      expect(await shown(tester, all..remove(png('rabbit_happy')), MaruMood.happy), [png('rabbit_idle')]);
      expect(await shown(tester, <String>{}, MaruMood.happy), isEmpty);
      final ph = placeholders(tester).single;
      expect((ph.face, ph.outfit), (MaruMood.happy, MaruOutfit.lab));
    });

    testWidgets('only some lab PNGs (the 4 being made): costume kept, other moods use lab_idle', (tester) async {
      final assets = {
        for (final k in MaruCharacterKind.values)
          for (final m in MaruMood.values) png('${k.name}_${m.name}'),
        png('rabbit_blink'),
        png('turtle_blink'),
        png('rabbit_lab_idle'),
        png('rabbit_lab_happy'),
        png('turtle_lab_idle'),
        png('turtle_lab_thinking'),
      };
      expect(await shown(tester, assets, MaruMood.happy), [png('rabbit_lab_happy')]);
      expect(await shown(tester, assets, MaruMood.sad), [png('rabbit_lab_idle')]);
      expect(await shown(tester, assets, MaruMood.thinking, kind: MaruCharacterKind.turtle), [png('turtle_lab_thinking')]);
      expect(await shown(tester, assets, MaruMood.cheer, kind: MaruCharacterKind.turtle), [png('turtle_lab_idle')]);
      // Normal outfit never picks lab files.
      expect(await shown(tester, assets, MaruMood.happy, outfit: MaruOutfit.normal), [png('rabbit_happy')]);
    });
  });

  group('blink', () {
    testWidgets('lab idle does not use the normal blink; lab_blink is used when present', (tester) async {
      CharacterAssets.debugSetAvailable({png('rabbit_idle'), png('rabbit_blink'), png('rabbit_lab_idle')});
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit, outfit: MaruOutfit.lab)));
      await pumpFor(tester, 800);
      expect(imageAssets(tester), [png('rabbit_lab_idle')]);

      CharacterAssets.debugSetAvailable({png('rabbit_idle'), png('rabbit_blink'), png('rabbit_lab_idle'), png('rabbit_lab_blink')});
      await tester.pumpWidget(app(MaruCharacter(key: UniqueKey(), kind: MaruCharacterKind.rabbit, outfit: MaruOutfit.lab)));
      await pumpFor(tester, 800);
      expect(imageAssets(tester), [png('rabbit_lab_idle'), png('rabbit_lab_blink')]);
    });

    testWidgets('normal outfit keeps its blink', (tester) async {
      CharacterAssets.debugSetAvailable({png('rabbit_idle'), png('rabbit_blink'), png('rabbit_lab_idle'), png('rabbit_lab_blink')});
      await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit)));
      await pumpFor(tester, 800);
      expect(imageAssets(tester), [png('rabbit_idle'), png('rabbit_blink')]);
    });
  });

  testWidgets('changing outfit cross-fades to the lab image (and back)', (tester) async {
    CharacterAssets.debugSetAvailable({png('turtle_thinking'), png('turtle_idle'), png('turtle_lab_thinking')});
    Widget turtle(MaruOutfit o) => app(MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.thinking, outfit: o));
    await tester.pumpWidget(turtle(MaruOutfit.normal));
    await pumpFor(tester, 400);
    expect(imageAssets(tester), [png('turtle_thinking')]);

    await tester.pumpWidget(turtle(MaruOutfit.lab));
    await tester.pump(const Duration(milliseconds: 60));
    expect(imageAssets(tester), containsAll([png('turtle_thinking'), png('turtle_lab_thinking')]), reason: 'mid cross-fade');
    await pumpFor(tester, 300);
    expect(imageAssets(tester), [png('turtle_lab_thinking')]);

    await tester.pumpWidget(turtle(MaruOutfit.normal));
    await pumpFor(tester, 300);
    expect(imageAssets(tester), [png('turtle_thinking')]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('placeholder follows the outfit', (tester) async {
    CharacterAssets.debugSetAvailable(<String>{});
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.turtle, outfit: MaruOutfit.lab)));
    await tester.pump();
    expect(placeholders(tester).single.outfit, MaruOutfit.lab);
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.turtle)));
    await pumpFor(tester, 300);
    expect(placeholders(tester).single.outfit, MaruOutfit.normal);
  });

  testWidgets('bubble passes the outfit: talking while typing falls back to lab_idle', (tester) async {
    CharacterAssets.debugSetAvailable({png('rabbit_idle'), png('rabbit_talking'), png('rabbit_lab_idle'), png('rabbit_lab_happy')});
    await tester.pumpWidget(app(const MaruCharacterBubble(
      kind: MaruCharacterKind.rabbit,
      mood: MaruMood.happy,
      outfit: MaruOutfit.lab,
      message: 'Lab time!',
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(imageAssets(tester), [png('rabbit_lab_idle')], reason: 'talking → lab_idle, not rabbit_talking');
    await pumpFor(tester, 1000);
    expect(imageAssets(tester), [png('rabbit_lab_happy')]);
  });

  test('warm-up / precache list includes the lab PNGs that exist', () {
    CharacterAssets.debugSetAvailable({png('rabbit_idle'), png('rabbit_lab_idle'), png('rabbit_lab_happy'), png('turtle_idle')});
    expect(CharacterAssets.existingFor(MaruCharacterKind.rabbit),
        [png('rabbit_idle'), png('rabbit_lab_idle'), png('rabbit_lab_happy')]);
    expect(CharacterAssets.existingFor(MaruCharacterKind.turtle), [png('turtle_idle')]);
  });
}
