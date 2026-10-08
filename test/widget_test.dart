// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_music/main.dart';
import 'package:little_music/locked_player.dart';

import 'lock_test.dart' show FakeTransport;

void main() {
  testWidgets('child interface has only play pause and no track selection', (
    tester,
  ) async {
    final p = LockedPlayer(const [
      Song('a', 'A', 'Approved', 'a'),
    ], FakeTransport());
    await p.initialize();
    await tester.pumpWidget(MusicApp(player: p));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.skip_next), findsNothing);
    await tester.tap(find.text('播放音樂'));
    await tester.pump();
    expect(p.playing, isTrue);
    expect(find.text('暫停一下'), findsOneWidget);
    await tester.tap(find.text('暫停一下'));
    await tester.pump();
    expect(p.playing, isFalse);
  });
  testWidgets('small screen large text and reduced motion remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final p = LockedPlayer([], FakeTransport());
    await tester.pumpWidget(MusicApp(player: p));
    await tester.pump();
    expect(find.text('還沒有音樂'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
