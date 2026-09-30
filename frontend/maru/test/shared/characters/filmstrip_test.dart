// Motion filmstrips for review (not part of the normal test run):
//   FILMSTRIP_OUT=/some/dir flutter test test/shared/characters/filmstrip_test.dart
// Writes one PNG per character: a row per reaction, a frame every [stepMs].
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/shared/characters/maru_character.dart';
import 'package:maru/shared/characters/src/character_assets.dart';

const stepMs = 60;
const frames = 26;
const charSize = 100.0;
const cellW = 130.0;
const cellH = 170.0;

final outDir = Platform.environment['FILMSTRIP_OUT'];

class _Harness extends StatefulWidget {
  const _Harness({super.key, required this.kind});

  final MaruCharacterKind kind;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  MaruMood mood = MaruMood.idle;
  int replay = 0;
  final tapKey = GlobalKey();

  void set(MaruMood m) => setState(() => mood = m);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: cellW,
        height: cellH,
        child: Align(
          alignment: const Alignment(0, 0.8),
          child: MaruCharacter(key: tapKey, kind: widget.kind, mood: mood, size: charSize, reactionKey: replay),
        ),
      );
}

void main() {
  setUp(() => CharacterAssets.debugSetAvailable(<String>{}));

  for (final kind in MaruCharacterKind.values) {
    testWidgets('filmstrip ${kind.name}', (tester) async {
      final boundaryKey = GlobalKey();
      final harnessKey = GlobalKey<_HarnessState>();
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4EFF))),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(color: Colors.white, child: _Harness(key: harnessKey, kind: kind)),
            ),
          ),
        ),
      ));

      final rows = <String, List<ui.Image>>{};
      Future<void> capture(String label, Future<void> Function() trigger) async {
        // Return to a calm idle between rows.
        harnessKey.currentState!.set(MaruMood.idle);
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await trigger();
        final images = <ui.Image>[];
        for (var i = 0; i < frames; i++) {
          await tester.pump(i == 0 ? Duration.zero : const Duration(milliseconds: stepMs));
          final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          images.add((await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!);
        }
        rows[label] = images;
      }

      for (final m in MaruMood.values.where((m) => m != MaruMood.idle)) {
        await capture(m.name, () async => harnessKey.currentState!.set(m));
      }
      await capture('tap', () => tester.tap(find.byKey(harnessKey.currentState!.tapKey)));

      if (outDir == null) return;
      final png = await tester.runAsync(() async {
        const labelW = 70.0;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final w = labelW + cellW * frames;
        final h = cellH * rows.length + 20;
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
        var y = 20.0;
        for (var i = 0; i < frames; i++) {
          final tp = TextPainter(
            text: TextSpan(text: '${i * stepMs}ms', style: const TextStyle(color: Colors.black, fontSize: 10)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(labelW + cellW * i + 4, 4));
        }
        for (final entry in rows.entries) {
          final tp = TextPainter(
            text: TextSpan(text: entry.key, style: const TextStyle(color: Colors.black, fontSize: 12)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(4, y + cellH / 2));
          for (var i = 0; i < entry.value.length; i++) {
            canvas.drawImage(entry.value[i], Offset(labelW + cellW * i, y), Paint());
            // Floor line: box top = (cellH - size) * 0.9 (Alignment y 0.8), feet at 0.94·size.
            final floor = y + (cellH - charSize) * 0.9 + charSize * 0.94;
            canvas.drawLine(
              Offset(labelW + cellW * i, floor),
              Offset(labelW + cellW * (i + 1), floor),
              Paint()..color = const Color(0x44FF0000),
            );
          }
          y += cellH;
        }
        final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$outDir/filmstrip_${kind.name}.png').writeAsBytesSync(png!.buffer.asUint8List());
    }, skip: outDir == null);
  }
}
