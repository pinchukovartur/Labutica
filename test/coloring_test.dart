// Каждую часть каждой картинки раскраски можно закрасить: она где-то не перекрыта
// другими частями и попадает в холст 300×250.
import 'package:flutter_test/flutter_test.dart';
import 'package:labutica/games/coloring.dart';

void main() {
  test('картинок 11, названия разные', () {
    expect(coloringPictures.length, 11);
    expect(coloringPictures.map((p) => p.name).toSet().length, 11);
  });
  for (final pic in coloringPictures) {
    test('${pic.name}: все части достижимы нажатием', () {
      final reachable = <int>{};
      for (double y = 0; y < 250; y += 1.5) {
        for (double x = 0; x < 300; x += 1.5) {
          for (var i = pic.parts.length - 1; i >= 0; i--) {
            if (pic.parts[i].contains(Offset(x, y))) {
              reachable.add(i);
              break;
            }
          }
        }
      }
      final missing = [for (var i = 0; i < pic.parts.length; i++) if (!reachable.contains(i)) i];
      expect(missing, isEmpty, reason: 'недоступные части: $missing');
    });
  }
}
