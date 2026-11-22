import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labutica/ds/components.dart';
import 'package:labutica/games/coloring.dart';
import 'package:labutica/games/kit.dart';
import 'package:labutica/games/registry.dart';

void main() {
  for (final mode in ['По образцу', 'Самостоятельно']) {
    testWidgets('раскраска завершается в режиме $mode', (t) async {
      t.view.physicalSize = const Size(915, 412);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      int? stars;
      final def = games['coloring']!;
      await t.pumpWidget(
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
      await t.tap(find.text(mode));
      await t.pump();
      final canvas = find.byKey(const ValueKey('coloring-canvas'));
      final semantics = t.widget<Semantics>(
        find
            .ancestor(
              of: canvas,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    coloringPictures.any(
                      (pic) => pic.name == widget.properties.label,
                    ),
              ),
            )
            .first,
      );
      final picture = coloringPictures.singleWhere(
        (pic) => pic.name == semantics.properties.label,
      );
      final sample = coloringSample(picture);
      expect(
        find.text('Образец'),
        mode == 'По образцу' ? findsOneWidget : findsNothing,
      );
      expect(
        t
            .widget<LbIconButton>(
              find.byWidgetPredicate(
                (w) => w is LbIconButton && w.label == 'Готово',
              ),
            )
            .onTap,
        isNull,
      );
      final points = <int, Offset>{};
      for (double y = 0; y < 250; y += 2) {
        for (double x = 0; x < 300; x += 2) {
          final point = Offset(x, y);
          for (var i = picture.parts.length - 1; i >= 0; i--) {
            if (picture.parts[i].contains(point)) {
              points.putIfAbsent(i, () => point);
              break;
            }
          }
        }
      }
      for (final entry in points.entries) {
        final swatch = find.byWidgetPredicate(
          (w) => w is Swatch && w.color == sample[entry.key],
        );
        await t.tap(
          find.ancestor(of: swatch, matching: find.byType(AnswerTile)),
        );
        await t.pump();
        final box = t.renderObject<RenderBox>(canvas);
        await t.tapAt(box.localToGlobal(entry.value));
        await t.pump();
        if (mode == 'Самостоятельно') break;
      }
      final done = find.byWidgetPredicate(
        (w) => w is LbIconButton && w.label == 'Готово',
      );
      expect(t.widget<LbIconButton>(done).onTap, isNotNull);
      await t.tap(done);
      await t.pump(const Duration(milliseconds: 350));
      expect(stars, 3);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
