// R-004 / CHR-1.6.4.2: no "shadow with an empty body" while the first PNG decodes.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/shared/characters/maru_character.dart';
import 'package:maru/shared/characters/src/character_assets.dart';

const idlePng = '${CharacterAssets.dir}rabbit_idle.png'; // real file in the bundle

Widget app(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

Finder get character => find.byType(MaruCharacter);

/// The floor shadow is the only drawOval in the image path.
bool isOval(Symbol method, List<dynamic> args) => method == #drawOval;

double revealOf(WidgetTester tester) => tester
    .widget<FadeTransition>(find.descendant(of: character, matching: find.byType(FadeTransition)).first)
    .opacity
    .value;

/// Horizontal scale of the body (z stays 1, so not getMaxScaleOnAxis).
double bodyScaleOf(WidgetTester tester) {
  final m = tester.widget<Transform>(find.descendant(of: character, matching: find.byType(Transform)).first).transform;
  return math.sqrt(m.storage[0] * m.storage[0] + m.storage[1] * m.storage[1]);
}

/// Real image decoding needs real async time.
Future<void> letImagesDecode(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
  await tester.pump();
}

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    CharacterAssets.debugSetAvailable({idlePng});
  });
  tearDown(() => CharacterAssets.debugSetAvailable(null));

  testWidgets('before the PNG decodes nothing is painted — not even the shadow', (tester) async {
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Image), findsOneWidget);
    expect(revealOf(tester), 0);
    expect(character, paintsNothing);
  });

  testWidgets('after decoding, body and shadow fade in over ~120ms', (tester) async {
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit)));
    await tester.pump();
    await letImagesDecode(tester);
    await tester.pump(const Duration(milliseconds: 40));
    final mid = revealOf(tester);
    expect(mid, inExclusiveRange(0, 1), reason: 'fresh decode fades in');
    await tester.pump(const Duration(milliseconds: 150));
    expect(revealOf(tester), 1);
    expect(character, paints..something(isOval)..drawImageRect()); // shadow, then the body image
  });

  testWidgets('cache hit (precached) shows the body on the very first frame', (tester) async {
    await tester.pumpWidget(app(Builder(
      builder: (context) => TextButton(
        onPressed: () => MaruCharacter.precache(context, MaruCharacterKind.rabbit),
        child: const Text('warm'),
      ),
    )));
    await tester.tap(find.text('warm'));
    await letImagesDecode(tester);

    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit)));
    expect(revealOf(tester), 1, reason: 'synchronous load → no fade');
    expect(character, paints..something(isOval)..drawImageRect());
  });

  testWidgets('entrance pop-in starts only once the image is ready', (tester) async {
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.rabbit, entrance: true)));
    await tester.pump(const Duration(milliseconds: 800)); // longer than the 550ms pop, image still loading
    expect(bodyScaleOf(tester), 0, reason: 'pop-in must not play while invisible');
    await letImagesDecode(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(bodyScaleOf(tester), greaterThan(0.5));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(bodyScaleOf(tester), closeTo(1, 0.05));
  });

  testWidgets('code placeholder is drawn immediately (no fade)', (tester) async {
    CharacterAssets.debugSetAvailable(<String>{});
    await tester.pumpWidget(app(const MaruCharacter(kind: MaruCharacterKind.turtle)));
    expect(revealOf(tester), 1);
    expect(character, paints..path()); // placeholder body
  });
}
