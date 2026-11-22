// games-build.jsx — PuzzleGame, ShapesGame (E7): Пазлы, Конструктор фигур.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/components.dart';
import '../ds/tokens.dart';
import 'kit.dart';

/// Четвертинка картинки (q = 0..3, слева направо, сверху вниз).
class PuzzlePiece extends StatelessWidget {
  const PuzzlePiece({super.key, required this.img, required this.q, required this.s});
  final String img;
  final int q;
  final double s;
  @override
  Widget build(BuildContext context) {
    final x = q % 2, y = q ~/ 2;
    return SizedBox.square(
      dimension: s,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: s * 2,
          maxHeight: s * 2,
          alignment: Alignment(x == 0 ? -1 : 1, y == 0 ? -1 : 1),
          child: Pic(img, w: s * 2, h: s * 2, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class PuzzleGame extends StatefulWidget {
  const PuzzleGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends GameState<PuzzleGame> {
  late final rounds = pick(['car', 'bus', 'plane', 'ship', 'train', 'bike'], 3).map((n) => 'puzzles/$n').toList();
  var placed = <int>{};
  int? sel;
  var order = shuffle([0, 1, 2, 3]);
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() {
    placed = {};
    sel = null;
    order = shuffle([0, 1, 2, 3]);
  }

  void put(int i) {
    if (sel == null || g.lock || placed.contains(i)) return;
    if (i == sel) {
      placed = {...placed, i};
      sel = null;
      g.good();
      if (placed.length == 4) g.ok('_', 1000);
    } else {
      g.bad(sel!);
      setState(() => sel = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = rounds[g.round];
    const s = 128.0;
    final hintQ = g.hint ? (sel ?? order.firstWhere((q) => !placed.contains(q), orElse: () => -1)) : null;
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      // Горизонтально: поле слева, детали справа.
      child: Row(children: [
        Expanded(
          child: Center(
            child: Container(
              decoration: BoxDecoration(color: C.gamePanel, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(R.lg)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(R.lg - 3),
                child: SizedBox(
                  width: s * 2,
                  height: s * 2,
                  child: Wrap(children: [
                    for (var i = 0; i < 4; i++)
                      GestureDetector(
                        onTap: () => put(i),
                        child: Container(
                          width: s,
                          height: s,
                          foregroundDecoration: hintQ == i && sel != null ? BoxDecoration(border: Border.all(color: C.spark300, width: 6)) : null,
                          child: placed.contains(i)
                              ? PuzzlePiece(img: img, q: i, s: s)
                              : Padding(padding: const EdgeInsets.all(6), child: DashedBorder(width: 2, radius: 0, child: const SizedBox.expand())),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
        SizedBox(
          width: 212,
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            for (final q in order)
              AnswerTile(
                key: ValueKey('${g.round}-$q'),
                size: 100,
                content: PuzzlePiece(img: img, q: q, s: 94),
                state: tileState(q, done: placed.contains(q), selected: sel == q, hint: hintQ == q),
                onTap: () => setState(() => sel = sel == q ? null : q),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────── Конструктор фигур ─────────────────────────

enum _Shape {
  sail('Треугольник', Color(0xFFFFCB22), Size(56, 56)),
  hull('Полукруг', Color(0xFF08C9C5), Size(65, 34)),
  flag('Фиолетовый ромб', Color(0xFFB761EF), Size(50, 48)),
  wing('Розовый овал', Color(0xFFFF60A1), Size(62, 40)),
  butterflyBody('Жёлтый овал', Color(0xFFFFCB22), Size(33, 60)),
  fin('Трапеция', Color(0xFFFF5A55), Size(60, 40)),
  rocketBody('Шестиугольник', Color(0xFFB761EF), Size(40, 62)),
  window('Иллюминатор', Color(0xFF28B7F2), Size(44, 39)),
  flame('Жёлтый ромб', Color(0xFFFFCB22), Size(46, 46));

  const _Shape(this.label, this.color, this.tileSize);
  final String label;
  final Color color;
  final Size tileSize;

  Path path(Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    Path polygon(List<Offset> points) => Path()
      ..addPolygon([
        for (final point in points) Offset(rect.left + point.dx * rect.width, rect.top + point.dy * rect.height),
      ], true);
    return switch (this) {
      sail => polygon([Offset.zero, const Offset(1, 1), const Offset(0, 1)]),
      hull =>
        Path()
          ..addArc(Rect.fromLTRB(rect.left, rect.top - rect.height, rect.right, rect.bottom), 0, math.pi)
          ..close(),
      flag || flame => polygon([const Offset(.5, 0), const Offset(1, .5), const Offset(.5, 1), const Offset(0, .5)]),
      fin => polygon([const Offset(.25, 0), const Offset(.75, 0), const Offset(1, 1), const Offset(0, 1)]),
      rocketBody => polygon([
        const Offset(.5, 0),
        const Offset(1, .21),
        const Offset(1, .79),
        const Offset(.5, 1),
        const Offset(0, .79),
        const Offset(0, .21),
      ]),
      wing || butterflyBody || window => Path()..addOval(rect),
    };
  }
}

class _ToyPainter extends CustomPainter {
  const _ToyPainter(this.shape, {this.filled = true, this.highlight = false});
  final _Shape shape;
  final bool filled, highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.path(size);
    if (!filled) {
      canvas.drawPath(path, Paint()..color = const Color(0x33FFFFFF));
      canvas.drawPath(
        dashPath(path, 6, 5),
        Paint()
          ..color = highlight ? C.spark700 : C.ink900
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlight ? 3.5 : 2.4
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final color = shape.color;
    final dark = Color.lerp(color, C.ink900, .58)!;
    final bounds = path.getBounds();
    canvas.drawPath(path.shift(const Offset(0, 3)), Paint()..color = const Color(0x451E1434));
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, .75)!, color, color, dark],
          stops: const [0, .27, .61, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawOval(
      Rect.fromLTWH(bounds.left + bounds.width * .08, bounds.top + bounds.height * .06, bounds.width * .67, bounds.height * .27),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3FFFFFF), Color(0x00FFFFFF)],
        ).createShader(bounds.topLeft & Size(bounds.width, bounds.height * .34)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ToyPainter oldDelegate) =>
      shape != oldDelegate.shape || filled != oldDelegate.filled || highlight != oldDelegate.highlight;
}

class _Part {
  const _Part(this.shape, this.bounds, [this.turns = 0]);
  final _Shape shape;
  final Rect bounds;
  final int turns;
}

class _AssemblyDesign {
  const _AssemblyDesign(this.name, this.parts, this.choices);
  final String name;
  final List<_Part> parts;
  final List<_Shape> choices;
}

const _designs = [
  _AssemblyDesign(
    'Кораблик',
    [
      _Part(_Shape.flag, Rect.fromLTWH(63, 4, 54, 34)),
      _Part(_Shape.sail, Rect.fromLTWH(63, 38, 97, 98)),
      _Part(_Shape.hull, Rect.fromLTWH(39, 136, 156, 72)),
    ],
    [_Shape.sail, _Shape.hull, _Shape.flag, _Shape.wing, _Shape.fin],
  ),
  _AssemblyDesign(
    'Бабочка',
    [
      _Part(_Shape.hull, Rect.fromLTWH(36, 22, 66, 92), 1),
      _Part(_Shape.hull, Rect.fromLTWH(131, 22, 66, 92), 3),
      _Part(_Shape.wing, Rect.fromLTWH(18, 111, 89, 66)),
      _Part(_Shape.wing, Rect.fromLTWH(126, 111, 89, 66)),
      _Part(_Shape.butterflyBody, Rect.fromLTWH(97, 56, 39, 123)),
    ],
    [_Shape.hull, _Shape.wing, _Shape.butterflyBody, _Shape.flag, _Shape.fin],
  ),
  _AssemblyDesign(
    'Ракета',
    [
      _Part(_Shape.fin, Rect.fromLTWH(27, 114, 68, 59)),
      _Part(_Shape.fin, Rect.fromLTWH(139, 114, 68, 59)),
      _Part(_Shape.flame, Rect.fromLTWH(92, 162, 50, 48)),
      _Part(_Shape.rocketBody, Rect.fromLTWH(73, 6, 88, 164)),
      _Part(_Shape.window, Rect.fromLTWH(95, 48, 44, 39)),
    ],
    [_Shape.rocketBody, _Shape.window, _Shape.fin, _Shape.hull, _Shape.flame],
  ),
];

class _Assembly extends StatelessWidget {
  const _Assembly(this.design, {this.filled, this.highlight, this.onPart});
  final _AssemblyDesign design;
  final Set<int>? filled;
  final _Shape? highlight;
  final ValueChanged<int>? onPart;

  @override
  Widget build(BuildContext context) => FittedBox(
    child: SizedBox(
      width: 234,
      height: 215,
      child: Stack(
        children: [
          for (final (i, part) in design.parts.indexed)
            Positioned.fromRect(
              rect: part.bounds,
              child: Semantics(
                label: part.shape.label,
                button: onPart != null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPart == null ? null : () => onPart!(i),
                  child: RotatedBox(
                    quarterTurns: part.turns,
                    child: CustomPaint(
                      painter: _ToyPainter(part.shape, filled: filled?.contains(i) ?? true, highlight: part.shape == highlight),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class ShapesGame extends StatefulWidget {
  const ShapesGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<ShapesGame> createState() => _ShapesGameState();
}

class _ShapesGameState extends GameState<ShapesGame> {
  final filled = <int>{};
  _Shape? selected;

  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => _designs.length;
  _AssemblyDesign get design => _designs[g.round];

  @override
  void onRound() {
    filled.clear();
    selected = null;
  }

  bool _hasOpen(_Shape shape) => design.parts.indexed.any((entry) => entry.$2.shape == shape && !filled.contains(entry.$1));

  void _place(int index) {
    final shape = selected;
    if (shape == null || g.lock || filled.contains(index)) return;
    if (design.parts[index].shape != shape) {
      selected = null;
      g.bad(shape);
      return;
    }

    filled.add(index);
    if (!_hasOpen(shape)) selected = null;
    if (filled.length == design.parts.length) {
      g.ok(shape, 950);
    } else {
      g.good();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = g.hint ? design.parts.indexed.where((entry) => !filled.contains(entry.$1)).firstOrNull?.$2.shape : null;
    return GameShell(
      args: args,
      round: g.round,
      total: totalRounds,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stripHeight = (constraints.maxHeight * .25).clamp(34.0, 93.0);
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: C.gamePanel, borderRadius: BorderRadius.circular(R.xl)),
                        alignment: Alignment.center,
                        child: Semantics(
                          label: design.name,
                          child: _Assembly(design, filled: filled, highlight: hint, onPart: _place),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: FittedBox(
                          child: Column(
                            children: [
                              _choices(design.choices.take(3), hint),
                              const SizedBox(height: 8),
                              _choices(design.choices.skip(3), hint),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: stripHeight,
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(color: C.gamePanel, borderRadius: BorderRadius.circular(R.xl)),
                child: Row(
                  children: [
                    for (final item in _designs)
                      Expanded(
                        child: Semantics(label: item.name, image: true, child: _Assembly(item)),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _choices(Iterable<_Shape> shapes, _Shape? hint) => Row(
    children: [
      for (final shape in shapes)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnswerTile(
            label: shape.label,
            size: 84,
            content: CustomPaint(size: shape.tileSize, painter: _ToyPainter(shape)),
            state: tileState(
              shape,
              done: design.parts.any((part) => part.shape == shape) && !_hasOpen(shape),
              selected: selected == shape,
              hint: hint == shape,
            ),
            onTap: g.lock ? null : () => setState(() => selected = selected == shape ? null : shape),
          ),
        ),
    ],
  );
}
