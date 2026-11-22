// Смоук-тест: каждая игра проходится случайными тапами до конца без исключений и переполнений вёрстки.
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labutica/games/kit.dart';
import 'package:labutica/games/registry.dart';

void main() {
  for (final age in [3, 4]) {
    for (final def in games.values) {
      testWidgets('${def.id} (возраст $age+) проходится до награды', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(2400, 1080);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        int? stars;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: def.build(
                GameArgs(
                  def: def,
                  age: age,
                  onHome: () {},
                  onDone: (s) => stars = s,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        if (def.id == 'coloring') {
          await tester.tap(find.text('Самостоятельно'));
          await tester.pump();
        }
        final r = Random(age * 100 + def.id.hashCode % 100);
        for (var i = 0; i < 12000 && stars == null; i++) {
          // Игры с перетаскиванием: тянем случайного малыша к случайной цели.
          final drags = find
              .byWidgetPredicate((w) => w is Draggable)
              .hitTestable()
              .evaluate()
              .toList();
          final drops = find
              .byWidgetPredicate((w) => w is DragTarget)
              .evaluate()
              .toList();
          if (drags.isNotEmpty && drops.isNotEmpty) {
            Offset centerOf(Element e) {
              final b = e.renderObject as RenderBox;
              return b.localToGlobal(b.size.center(Offset.zero));
            }

            final from = centerOf(drags[r.nextInt(drags.length)]);
            final to = centerOf(drops[r.nextInt(drops.length)]);
            final gesture = await tester.startGesture(
              from,
              kind: PointerDeviceKind.touch,
            );
            for (var k = 1; k <= 8; k++) {
              await gesture.moveTo(Offset.lerp(from, to, k / 8)!);
              await tester.pump(const Duration(milliseconds: 16));
            }
            await gesture.up();
            await tester.pump(const Duration(milliseconds: 120));
            await tester.pump(const Duration(milliseconds: 1500));
            continue;
          }
          // Игры-сцены без общей шапки (урожай): ждём, пока доиграется анимация.
          if (find.byType(GameShell).evaluate().isEmpty) {
            await tester.pump(const Duration(milliseconds: 500));
            continue;
          }
          final targets = find
              .byWidgetPredicate(
                (w) =>
                    w is GestureDetector &&
                    (w.onTap != null || w.onTapUp != null),
                skipOffstage: true,
              )
              .hitTestable()
              .evaluate()
              .toList();
          // Кнопки «Домой» и «Правила» не трогаем — они не продвигают игру.
          final shell =
              find.byType(GameShell).evaluate().first.renderObject as RenderBox;
          final top = shell.localToGlobal(Offset.zero).dy + 80;
          final usable = targets.where((e) {
            final b = e.renderObject as RenderBox;
            return b.localToGlobal(b.size.center(Offset.zero)).dy > top;
          }).toList();
          expect(
            usable,
            isNotEmpty,
            reason: 'нет активных элементов на шаге $i',
          );
          final box =
              usable[r.nextInt(usable.length)].renderObject as RenderBox;
          final at = Offset(
            box.size.width * (.15 + .7 * r.nextDouble()),
            box.size.height * (.15 + .7 * r.nextDouble()),
          );
          await tester.tapAt(
            box.localToGlobal(at),
            kind: PointerDeviceKind.touch,
          );
          await tester.pump(const Duration(milliseconds: 120));
          await tester.pump(const Duration(milliseconds: 1200));
        }
        await tester.pump(const Duration(seconds: 2));
        expect(stars, isNotNull, reason: 'игра не завершилась');
        expect(stars, inInclusiveRange(1, 3));
      });
    }
  }
}
