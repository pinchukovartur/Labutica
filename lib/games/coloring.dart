// Раскраска: по цветному образцу или самостоятельно.
// Каждая партия берёт случайную картинку из библиотеки (не ту, что была в прошлый раз).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

const _paint = {
  'red': C.paintRed,
  'orange': C.spark500,
  'yellow': C.paintYellow,
  'green': C.paintGreen,
  'blue': C.paintBlue,
  'purple': Color(0xFF8A5CD6),
  'pink': C.bubble500,
  'brown': Color(0xFF9A5B2E),
};

// ───────────────────────── Картинки ─────────────────────────

/// Картинка-раскраска на холсте 300×250.
/// [parts] — закрашиваемые части, снизу вверх по слоям; [lines] — контурные
/// детали (усики, ниточки); [inks] — мелкие тёмные детали (зрачки).
class ColoringPicture {
  const ColoringPicture(
    this.name,
    this.parts, {
    this.lines = const [],
    this.inks = const [],
  });
  final String name;
  final List<Path> parts, lines, inks;
}

Path _circle(double cx, double cy, double r) =>
    Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
Path _oval(double l, double t, double r, double b) =>
    Path()..addOval(Rect.fromLTRB(l, t, r, b));
Path _rect(double l, double t, double w, double h) =>
    Path()..addRect(Rect.fromLTWH(l, t, w, h));
Path _rrect(double l, double t, double r, double b, double rad) =>
    Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)));

Path _poly(List<double> xy) {
  final p = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    p.lineTo(xy[i], xy[i + 1]);
  }
  return p..close();
}

/// Эллипс с центром (cx, cy), повёрнутый на [deg] градусов.
Path _rotOval(double cx, double cy, double rx, double ry, double deg) {
  final m = Matrix4.translationValues(cx, cy, 0)
    ..multiply(Matrix4.rotationZ(deg * math.pi / 180));
  return (Path()..addOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      ))
      .transform(m.storage);
}

Path _star(double cx, double cy, double r) => _poly([
  for (var i = 0; i < 10; i++) ...[
    cx + (i.isEven ? r : r * .45) * math.cos(-math.pi / 2 + i * math.pi / 5),
    cy + (i.isEven ? r : r * .45) * math.sin(-math.pi / 2 + i * math.pi / 5),
  ],
]);

Path _line(List<double> xy) {
  final p = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    p.lineTo(xy[i], xy[i + 1]);
  }
  return p;
}

Path _curve(double x1, double y1, double cx, double cy, double x2, double y2) =>
    Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(cx, cy, x2, y2);

Path _union(List<Path> ps) =>
    ps.reduce((a, b) => Path.combine(PathOperation.union, a, b));

final coloringPictures = <ColoringPicture>[
  ColoringPicture('Домик', [
    _circle(262, 36, 24), // солнце
    _rrect(2, 208, 298, 248, 10), // трава
    _rect(196, 40, 26, 50), // труба
    _rect(60, 104, 180, 104), // стена
    _poly([40, 106, 150, 26, 260, 106]), // крыша
    _rrect(80, 126, 114, 160, 4), // окно
    _rrect(132, 140, 172, 208, 4), // дверь
  ]),
  ColoringPicture(
    'Рыбка',
    [
      _rrect(2, 212, 298, 248, 10), // песок
      _rotOval(30, 170, 11, 42, -10), // водоросль
      _rotOval(52, 186, 9, 30, 16), // водоросль
      _poly([205, 125, 265, 78, 252, 125, 265, 172]), // хвост
      _poly([100, 80, 140, 38, 172, 78]), // верхний плавник
      _poly([118, 172, 140, 204, 162, 170]), // нижний плавник
      _oval(50, 70, 220, 180), // тело
      _oval(140, 80, 168, 170), // полоска
      _circle(85, 115, 13), // глаз
      _circle(248, 52, 12), // пузырь
      _circle(270, 22, 8), // пузырь
    ],
    lines: [
      _curve(56, 136, 66, 142, 74, 134), // рот
    ],
    inks: [_circle(82, 115, 6)],
  ),
  ColoringPicture(
    'Машинка',
    [
      _rrect(2, 216, 298, 246, 8), // дорога
      _poly([85, 120, 110, 68, 190, 68, 222, 120]), // кабина
      _poly([102, 116, 120, 80, 148, 80, 148, 116]), // окно
      _poly([156, 116, 156, 80, 184, 80, 204, 116]), // окно
      _rrect(30, 115, 270, 185, 18), // кузов
      _oval(250, 128, 266, 150), // фара
      _circle(88, 188, 28), // колесо
      _circle(212, 188, 28), // колесо
      _circle(88, 188, 11), // диск
      _circle(212, 188, 11), // диск
    ],
    lines: [
      _line([152, 122, 152, 178]), // дверь
    ],
  ),
  ColoringPicture('Цветок', [
    _rrect(144, 105, 156, 186, 5), // стебель
    _rotOval(122, 152, 26, 11, -30), // лист
    _rotOval(178, 140, 26, 11, 30), // лист
    for (var i = 0; i < 6; i++)
      _rotOval(
        150 + 32 * math.cos(i * math.pi / 3),
        82 + 32 * math.sin(i * math.pi / 3),
        24,
        14,
        i * 60.0,
      ), // лепестки
    _circle(150, 82, 18), // серединка
    _poly([108, 192, 192, 192, 180, 246, 120, 246]), // горшок
    _rrect(98, 180, 202, 198, 5), // край горшка
  ]),
  ColoringPicture(
    'Бабочка',
    [
      _rotOval(110, 158, 38, 30, 25), // нижнее крыло
      _rotOval(190, 158, 38, 30, -25), // нижнее крыло
      _rotOval(100, 92, 52, 40, -25), // верхнее крыло
      _rotOval(200, 92, 52, 40, 25), // верхнее крыло
      _circle(95, 90, 13), // пятнышко
      _circle(205, 90, 13), // пятнышко
      _circle(110, 162, 8), // пятнышко
      _circle(190, 162, 8), // пятнышко
      _rrect(140, 70, 160, 202, 10), // тельце
      _circle(150, 58, 14), // голова
      _circle(114, 20, 7), // кончик усика
      _circle(186, 20, 7), // кончик усика
    ],
    lines: [
      _curve(145, 46, 132, 22, 118, 22),
      _curve(155, 46, 168, 22, 182, 22),
    ],
    inks: [_circle(145, 56, 2.5), _circle(155, 56, 2.5)],
  ),
  ColoringPicture('Грибок', [
    _circle(40, 40, 22), // солнце
    _rrect(2, 210, 298, 246, 10), // трава
    _rrect(118, 128, 182, 216, 16), // ножка
    Path.combine(
      PathOperation.intersect,
      _oval(45, 35, 255, 245),
      _rect(0, 0, 300, 140),
    ), // шляпка
    _circle(110, 95, 14), // пятнышко
    _circle(160, 64, 12), // пятнышко
    _circle(200, 106, 15), // пятнышко
    _circle(150, 120, 8), // пятнышко
  ]),
  ColoringPicture('Ёлочка', [
    _rrect(2, 214, 298, 246, 10), // снег
    _rect(135, 192, 30, 28), // ствол
    _poly([150, 100, 245, 198, 55, 198]), // нижний ярус
    _poly([150, 56, 225, 142, 75, 142]), // средний ярус
    _poly([150, 22, 205, 86, 95, 86]), // верхний ярус
    _circle(115, 178, 9), // шарик
    _circle(185, 172, 9), // шарик
    _circle(122, 124, 8), // шарик
    _circle(176, 118, 8), // шарик
    _circle(150, 70, 7), // шарик
    _star(150, 22, 18), // звезда
  ]),
  ColoringPicture('Кораблик', [
    _circle(255, 45, 22), // солнце
    _rect(146, 22, 8, 142), // мачта
    _poly([154, 22, 186, 30, 154, 38]), // флажок
    _poly([158, 48, 158, 150, 235, 150]), // большой парус
    _poly([142, 62, 142, 150, 85, 150]), // малый парус
    _poly([50, 160, 250, 160, 220, 206, 80, 206]), // корпус
    _circle(110, 180, 8), // иллюминатор
    _circle(150, 180, 8), // иллюминатор
    _circle(190, 180, 8), // иллюминатор
    Path() // море
      ..moveTo(2, 196)
      ..quadraticBezierTo(39, 184, 76, 196)
      ..quadraticBezierTo(113, 208, 150, 196)
      ..quadraticBezierTo(187, 184, 224, 196)
      ..quadraticBezierTo(261, 208, 298, 196)
      ..lineTo(298, 246)
      ..lineTo(2, 246)
      ..close(),
  ]),
  ColoringPicture(
    'Снеговик',
    [
      _rrect(2, 214, 298, 246, 10), // сугроб
      _circle(150, 180, 42), // низ
      _circle(150, 112, 32), // середина
      _circle(150, 60, 25), // голова
      _rrect(118, 82, 182, 94, 6), // шарф
      _rrect(160, 88, 172, 122, 4), // кончик шарфа
      _rrect(130, 4, 170, 32, 4), // шапка
      _rrect(120, 30, 180, 40, 3), // поля шапки
      _poly([148, 58, 176, 63, 148, 68]), // нос-морковка
      _circle(150, 108, 5), // пуговица
      _circle(150, 126, 5), // пуговица
      _circle(150, 166, 6), // пуговица
      _circle(150, 188, 6), // пуговица
    ],
    lines: [
      _line([120, 108, 82, 86, 70, 90]),
      _line([82, 86, 78, 74]),
      _line([180, 108, 218, 84, 230, 88]),
      _line([218, 84, 222, 72]),
    ],
    inks: [_circle(141, 52, 3.5), _circle(159, 52, 3.5)],
  ),
  ColoringPicture(
    'Шарики',
    [
      _circle(40, 40, 22), // солнце
      _union([
        _circle(228, 42, 18),
        _circle(252, 32, 22),
        _circle(276, 44, 16),
        _rrect(214, 40, 290, 60, 10),
      ]), // облако
      _oval(58, 62, 132, 152), // шарик
      _oval(178, 72, 250, 160), // шарик
      _oval(118, 30, 192, 124), // шарик
      _poly([95, 152, 88, 162, 102, 162]), // узелок
      _poly([214, 160, 207, 170, 221, 170]), // узелок
      _poly([155, 124, 148, 134, 162, 134]), // узелок
      _poly([150, 232, 130, 220, 130, 244]), // бантик
      _poly([150, 232, 170, 220, 170, 244]), // бантик
    ],
    lines: [
      _curve(95, 162, 110, 205, 150, 232),
      _curve(155, 134, 140, 185, 150, 232),
      _curve(214, 170, 195, 210, 150, 232),
    ],
  ),
  ColoringPicture('Ракета', [
    _star(42, 42, 14), // звезда
    _star(262, 58, 12), // звезда
    _star(56, 186, 12), // звезда
    _star(250, 196, 14), // звезда
    _poly([126, 188, 150, 246, 174, 188]), // пламя
    _poly([118, 138, 82, 196, 118, 186]), // крыло
    _poly([182, 138, 218, 196, 182, 186]), // крыло
    _rect(118, 70, 64, 122), // корпус
    _rect(118, 152, 64, 14), // полоска
    Path() // нос
      ..moveTo(118, 72)
      ..quadraticBezierTo(120, 30, 150, 8)
      ..quadraticBezierTo(180, 30, 182, 72)
      ..close(),
    _circle(150, 110, 17), // иллюминатор
  ]),
];

/// Какую картинку показывали в прошлый раз: подряд одна и та же не выпадает.
int _lastPicture = -1;

int _nextPicture() {
  var i = rnd.nextInt(coloringPictures.length);
  if (i == _lastPicture) {
    i =
        (i + 1 + rnd.nextInt(coloringPictures.length - 1)) %
        coloringPictures.length;
  }
  return _lastPicture = i;
}

// ───────────────────────── Игра ─────────────────────────

class ColoringGame extends StatefulWidget {
  const ColoringGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<ColoringGame> createState() => _ColoringGameState();
}

/// Цветной образец постоянен для каждой картинки и использует цвета палитры.
Map<int, Color> coloringSample(ColoringPicture picture) => {
  for (var i = 0; i < picture.parts.length; i++)
    i: _paint.values.elementAt(
      (i + coloringPictures.indexOf(picture)) % _paint.length,
    ),
};

class _ColoringGameState extends GameState<ColoringGame> {
  bool? bySample;

  late final pic = coloringPictures[_nextPicture()];
  final fill = <int, Color>{};
  String sel = 'red';
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => 1;

  void tapAt(Offset o) {
    if (g.lock) return;
    // Сверху вниз по слоям: верхняя часть перекрывает нижнюю.
    for (var i = pic.parts.length - 1; i >= 0; i--) {
      if (pic.parts[i].contains(o)) {
        return setState(() => fill[i] = _paint[sel]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bySample == null) {
      return GameShell(
        args: args,
        round: 0,
        total: 1,
        task: Text('Раскраска', style: body(20, FontWeight.w900)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Как будем раскрашивать?', style: body(24, FontWeight.w900)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  LbButton(
                    'По образцу',
                    icon: LucideIcons.image,
                    onTap: () => setState(() => bySample = true),
                  ),
                  LbButton(
                    'Самостоятельно',
                    icon: LucideIcons.palette,
                    onTap: () => setState(() => bySample = false),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final sample = coloringSample(pic);
    final started = fill.isNotEmpty;
    final all = fill.length == pic.parts.length;
    final matches = sample.entries.every(
      (entry) => fill[entry.key] == entry.value,
    );
    final canFinish = bySample! ? matches : started;

    return GameShell(
      args: args,
      round: 0,
      total: 1,
      task: Row(
        children: [
          Expanded(
            child: Text(
              bySample! ? 'Раскрась по образцу' : 'Раскрась как хочешь',
              style: body(16, FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: g.lock ? null : () => setState(() => bySample = null),
            child: const Text('Сменить режим'),
          ),
        ],
      ),

      // Горизонтально: образец, холст, палитра и завершение.
      child: Row(
        children: [
          if (bySample!) ...[
            Flexible(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Образец', style: body(16, FontWeight.w800)),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 300 / 250,
                    child: FittedBox(
                      child: CustomPaint(
                        size: const Size(300, 250),
                        painter: _PicturePainter(pic, sample),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],

          Expanded(
            child: Center(
              child: FittedBox(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: C.gamePanel,
                    borderRadius: BorderRadius.circular(R.xl),
                  ),
                  child: Semantics(
                    label: pic.name,
                    child: GestureDetector(
                      onTapUp: (d) => tapAt(d.localPosition),
                      child: CustomPaint(
                        size: const Size(300, 250),
                        key: const ValueKey('coloring-canvas'),
                        painter: _PicturePainter(pic, Map.of(fill)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 62 * 2 + 10,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final k in _paint.keys)
                  AnswerTile(
                    label: k,
                    size: 62,
                    content: Swatch(_paint[k]!, size: 40),
                    state: sel == k ? 'selected' : 'idle',
                    onTap: () => setState(() => sel = k),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Галочка оживает после первого мазка и пульсирует, когда раскрашено всё.
          Opacity(
            opacity: canFinish ? 1 : .4,
            child: HintPulse(
              active: (bySample! ? matches : all) && !g.lock,
              child: LbIconButton(
                LucideIcons.check,
                size: 'lg',
                label: 'Готово',
                onTap: canFinish && !g.lock ? () => g.finish(300) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PicturePainter extends CustomPainter {
  _PicturePainter(this.pic, this.fill);
  final ColoringPicture pic;
  final Map<int, Color> fill;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = C.ink900;
    for (final (i, p) in pic.parts.indexed) {
      canvas.drawPath(p, Paint()..color = fill[i] ?? C.white);
      canvas.drawPath(p, stroke);
    }
    for (final l in pic.lines) {
      canvas.drawPath(l, stroke);
    }
    for (final d in pic.inks) {
      canvas.drawPath(d, Paint()..color = C.ink900);
    }
  }

  @override
  bool shouldRepaint(_PicturePainter o) =>
      o.pic != pic || o.fill.toString() != fill.toString();
}
