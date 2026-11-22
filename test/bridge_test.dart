import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labutica/games/bridge.dart';
import 'package:labutica/games/kit.dart';
import 'package:labutica/games/registry.dart';

void main() {
  for (final size in [const Size(915, 412), const Size(740, 360)]) {
    testWidgets('мостик: обучение, ошибка, успех при $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      int? stars;
      final def = games['bridge']!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: def.build(
              GameArgs(
                def: def,
                age: 3,
                onHome: () {},
                onDone: (value) => stars = value,
              ),
            ),
          ),
        ),
      );
      final long = find.byKey(const ValueKey('bridge-long'));
      final short = find.byKey(const ValueKey('bridge-short'));
      final gap = find.byKey(const ValueKey('bridge-gap'));
      expect(short, findsNothing);
      final sceneSize = tester.getSize(
        find.byKey(const ValueKey('bridge-scene')),
      );
      expect(
        sceneSize.width / sceneSize.height,
        closeTo(bridgeSceneSize.aspectRatio, .001),
      );
      expect(sceneSize.width, greaterThanOrEqualTo(size.width));
      expect(sceneSize.height, greaterThanOrEqualTo(size.height));
      final board = tester.widget<BridgePlank>(
        find.descendant(of: long, matching: find.byType(BridgePlank)).first,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('bridge-slot-visual'))),
        Size(board.width, board.height),
      );
      Future<void> place(Finder choice) async {
        await tester.drag(
          choice,
          tester.getCenter(gap) - tester.getCenter(choice),
        );
        await tester.pump();
      }

      await place(long);
      await tester.pump(const Duration(milliseconds: 1700));
      expect(short, findsOneWidget);
      await place(short);
      expect(find.text('Короткая. Попробуй длинную!'), findsOneWidget);
      expect(stars, isNull);
      await tester.pump(const Duration(milliseconds: 700));
      await place(long);
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pump();
      expect(stars, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
