import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lab/models/ai_lab_model.dart';
import 'package:maru/features/lab/providers/ai_lab_provider.dart';
import 'package:maru/features/lab/repositories/ai_lab_repository.dart';
import 'package:maru/features/lab/screens/lab_screen.dart';
import 'package:maru/features/lab/utils/korean_word_wrap.dart';

class _FakeRepo extends AiLabRepository {
  _FakeRepo() : super(Dio());

  @override
  Future<List<AiLabExploreResponseModel>> explore(AiLabExploreRequestModel request) async => [
    for (final t in ['저는 밥을 먹었어요', '저는 밥을 먹을 거예요', '저는 밥을 먹겠어요'])
      AiLabExploreResponseModel(text: t, type: 'Type', explanation: 'Explanation'),
  ];
}

void main() {
  // Feedback R2 #4: after generating, results get the whole screen (form hidden); Edit brings the form back.
  testWidgets('Grammar Lab: results replace the form, Edit returns with the sentence kept', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiLabRepositoryProvider.overrideWithValue(_FakeRepo())],
        child: MaterialApp(
          // Characters loop forever; reduced motion stops the loops so pumpAndSettle can settle.
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: LabScreen(),
        ),
      ),
    );

    await tester.tap(find.text('저는 밥을 먹어요')); // example chip
    await tester.pump();
    await tester.tap(find.textContaining('Tense', findRichText: true)); // pick the rule (Explore is the default mode)
    await tester.pump();
    expect(find.text('Explore Tense'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lab-run')));
    await tester.pumpAndSettle();

    expect(find.text('Original'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    for (final t in ['저는 밥을 먹었어요', '저는 밥을 먹을 거예요', '저는 밥을 먹겠어요']) {
      // Visible without scrolling.
      final rect = tester.getRect(find.text(koreanKeepAll(t))); // shown with word joiners
      expect(rect.bottom, lessThan(874));
    }

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(TextField, '저는 밥을 먹어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
