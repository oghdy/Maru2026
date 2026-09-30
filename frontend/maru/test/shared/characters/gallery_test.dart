import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/dev/character_gallery_main.dart';
import 'package:maru/shared/characters/maru_character.dart';
import 'package:maru/shared/characters/src/character_assets.dart';

/// Body lift of [character] in logical pixels (+ = up).
double liftOf(WidgetTester tester, Finder character) {
  final t = tester.widget<Transform>(find.descendant(of: character, matching: find.byType(Transform)).first);
  return -t.transform.getTranslation().y;
}

Future<double> maxLiftOver(WidgetTester tester, Finder character, int ms) async {
  var best = 0.0;
  for (var t = 0; t < ms; t += 20) {
    await tester.pump(const Duration(milliseconds: 20));
    best = best > liftOf(tester, character) ? best : liftOf(tester, character);
  }
  return best;
}

void main() {
  setUp(() => CharacterAssets.debugSetAvailable(<String>{}));
  tearDown(() => CharacterAssets.debugSetAvailable(null));

  testWidgets('gallery starts with every debug toggle off', (tester) async {
    await tester.pumpWidget(const CharacterGalleryApp());
    await tester.pump();
    for (final label in ['Reduce motion', 'Force placeholder', 'Slow motion ×5']) {
      final chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));
      expect(chip.selected, isFalse, reason: label);
    }
    expect(CharacterAssets.forcePlaceholder.value, isFalse);
  });

  testWidgets('Scenario: pressing Correct repeatedly replays the happy jump every time', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CharacterGalleryApp());
    await tester.pump();
    final correct = find.widgetWithText(FilledButton, 'Correct');
    await tester.scrollUntilVisible(correct, 300, scrollable: find.byType(Scrollable).first);
    await tester.pump();

    final rabbit = find.byWidgetPredicate(
      (w) => w is MaruCharacter && w.kind == MaruCharacterKind.rabbit && w.size == 120,
    );
    expect(rabbit, findsOneWidget);

    for (var press = 1; press <= 3; press++) {
      await tester.tap(correct);
      // happy 🐰 jump height is 0.12·size = 14.4px; accept anything clearly airborne.
      final lift = await maxLiftOver(tester, rabbit, 900);
      expect(lift, greaterThan(10), reason: 'press $press should jump (max lift $lift)');
      // Let it land and settle back to idle (settleToIdleAfter 1600ms) before pressing again.
      await maxLiftOver(tester, rabbit, 2400);
    }
  });
}
