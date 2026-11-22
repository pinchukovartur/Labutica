// «Найди родителей»: у каждого вида есть арт пары, мамы и малыша; похожие малыши не встречаются вместе.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:labutica/games/parents.dart';

void main() {
  for (final sp in parentSpecies) {
    test('арт: $sp', () {
      for (final kind in ['parents', 'mom', 'baby']) {
        expect(File('assets/animals/$sp-$kind.png').existsSync(), isTrue, reason: '$sp-$kind.png');
      }
    });
  }
  test('похожие малыши не встречаются в одном раунде', () {
    for (final (a, b) in [('hen', 'duck'), ('cow', 'goat')]) {
      for (var i = 0; i < 200; i++) {
        expect(parentTargets(a), isNot(contains(b)));
        expect(parentTargets(b), isNot(contains(a)));
        expect(parentTargets(a), hasLength(3));
      }
    }
  });
}
