// games-misc.jsx — Найди пару (E1), Поровну (E5), Колесо дня (E15). Раскраска — в coloring.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

// ───────────────────────── Найди пару ─────────────────────────

/// Вещи сохнут на верёвке: у висящей вещи потерялась пара, её нужно найти среди трёх внизу.
class FindPairGame extends StatefulWidget {
  const FindPairGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<FindPairGame> createState() => _FindPairGameState();
}

class _FindPairGameState extends GameState<FindPairGame> {
  static const _t = ['red', 'blue', 'yellow', 'green', 'pink'], _i = ['sock', 'mitten', 'shirt', 'hat', 'boot'];

  /// Фон двора (clothes/yard.jpg) и верёвка на нём: центр провиса и его глубина, в пикселях картинки.
  static const _bg = Size(1672, 941);
  static double _ropeY(double x) => 272 - 22 * ((x - 960) / 320) * ((x - 960) / 320);

  // Раунд — висящая вещь и три варианта: сначала носочки другого цвета,
  // потом та же вещь другого цвета, потом вперемешку: другой цвет или другая вещь того же цвета.
  late final List<(String, List<String>)> rounds = () {
    final out = <(String, List<String>)>[];
    for (final c in pick(_t, 2)) {
      out.add(('sock-$c', ['sock-$c', ...pick(_t.where((t) => t != c), 2).map((t) => 'sock-$t')]));
    }
    for (final i in pick(_i.where((i) => i != 'sock'), 2)) {
      final c = pick(_t, 1).first;
      out.add(('$i-$c', ['$i-$c', ...pick(_t.where((t) => t != c), 2).map((t) => '$i-$t')]));
    }
    for (var k = 0; k < 2; k++) {
      final i = pick(_i, 1).first, c = pick(_t, 1).first;
      out.add(('$i-$c', ['$i-$c', '$i-${pick(_t.where((t) => t != c), 1).first}', '${pick(_i.where((x) => x != i), 1).first}-$c']));
    }
    return [for (final (w, o) in out) (w, shuffle(o))];
  }();
  String? placed;
  bool over = false;

  /// Где на экране лежит поле игры: по нему пересчитываем верёвку с фона в свои координаты.
  final _area = GlobalKey();
  Offset? _origin;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() {
    placed = null;
    over = false;
  }

  void choose(String o) {
    over = false;
    if (g.lock || placed != null) return;
    if (o == rounds[g.round].$1) {
      setState(() => placed = o);
      g.ok(o, 1100);
    } else {
      g.bad(o);
    }
  }

  void _measure() {
    final box = _area.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !mounted) return;
    final o = box.localToGlobal(Offset.zero);
    if (o != _origin) setState(() => _origin = o);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final (want, opts) = rounds[g.round];
    final scr = MediaQuery.sizeOf(context);
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      child: SizedBox.expand(
        key: _area,
        child: _origin == null
            ? null
            : LayoutBuilder(
                builder: (_, c) {
                  // Фон растянут AppShell на весь экран (BoxFit.cover по центру) — та же раскладка здесь.
                  final k = math.max(scr.width / _bg.width, scr.height / _bg.height);
                  final off = Offset((scr.width - _bg.width * k) / 2, (scr.height - _bg.height * k) / 2) - _origin!;
                  Offset rope(double x) => off + Offset(x, _ropeY(x)) * k;
                  final s = scr.height * .3, o = s * .66, tray = s * .84;
                  final hung = rope(830), slot = rope(1090);
                  Rect at(Offset p) => Rect.fromLTWH(p.dx - s / 2, p.dy - s * .06, s, s);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fromRect(
                        rect: at(hung),
                        child: Pic('clothes/$want', w: s, h: s, align: Alignment.topCenter),
                      ),
                      Positioned.fromRect(
                        rect: at(slot),
                        child: placed != null
                            ? Pop(
                                child: Pic('clothes/$want', w: s, h: s, align: Alignment.topCenter),
                              )
                            : _slot(want, s),
                      ),
                      for (final p in [hung, slot])
                        Positioned(
                          left: p.dx - s * .05,
                          top: p.dy - s * .13,
                          width: s * .1,
                          height: s * .28,
                          child: const CustomPaint(painter: _Peg()),
                        ),
                      // Варианты внизу — без плиток, прямо на светлой полке.
                      Positioned(
                        left: (c.maxWidth - o * 4.2) / 2,
                        width: o * 4.2,
                        bottom: 0,
                        height: tray,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: C.gamePanel, borderRadius: BorderRadius.circular(tray / 2)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [for (final x in opts) SizedBox(width: o, height: o, child: x == placed ? null : _option(x, want, o))],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  /// Пустое место на прищепке: белый силуэт нужной вещи с тёмным контуром.
  Widget _slot(String want, double s) => DragTarget<String>(
    onWillAcceptWithDetails: (_) {
      if (g.lock) return false;
      setState(() => over = true);
      return true;
    },
    onLeave: (_) => setState(() => over = false),
    onAcceptWithDetails: (d) => choose(d.data),
    builder: (_, _, _) => AnimatedScale(
      scale: over ? 1.06 : 1,
      duration: Dur.fast,
      child: Stack(
        children: [
          Transform.scale(
            scale: 1.06,
            child: Pic('clothes/$want', w: s, h: s, align: Alignment.topCenter, color: C.ink900.withValues(alpha: .45)),
          ),
          Pic(
            'clothes/$want',
            w: s,
            h: s,
            align: Alignment.topCenter,
            color: C.white.withValues(alpha: over ? 1 : .85),
          ),
        ],
      ),
    ),
  );

  Widget _option(String x, String want, double o) {
    final pic = Pic('clothes/$x', w: o, h: o);
    return Wiggle(
      active: g.marks[x] == 'wrong',
      child: HintPulse(
        active: g.hint && x == want && placed == null,
        child: Draggable<String>(
          data: x,
          maxSimultaneousDrags: g.lock ? 0 : 1,
          feedback: Material(
            type: MaterialType.transparency,
            child: Transform.rotate(angle: -.07, child: Transform.scale(scale: 1.1, child: pic)),
          ),
          childWhenDragging: Opacity(opacity: .25, child: pic),
          child: GestureDetector(onTap: () => choose(x), child: pic),
        ),
      ),
    );
  }
}

/// Деревянная прищепка: две половинки и пружинка.
class _Peg extends CustomPainter {
  const _Peg();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * .35));
    canvas.drawRRect(body, Paint()..color = C.amber);
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFFB86E1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .12,
    );
    final line = Paint()
      ..color = const Color(0xFFB86E1C)
      ..strokeWidth = w * .1;
    canvas.drawLine(Offset(w / 2, h * .08), Offset(w / 2, h * .92), line);
    canvas.drawLine(Offset(w * .1, h * .42), Offset(w * .9, h * .42), line);
  }

  @override
  bool shouldRepaint(_Peg old) => false;
}

// ───────────────────────── Поровну ─────────────────────────

class EqualGame extends StatefulWidget {
  const EqualGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<EqualGame> createState() => _EqualGameState();
}

class _EqualGameState extends GameState<EqualGame> {
  late final rounds = shuffle(const [(3, 1), (2, 4), (4, 2), (1, 3), (3, 5), (2, 1)]).take(5).toList();
  late final pairs = rounds
      .map((_) => ('animals/${pick(['cat', 'dog', 'horse', 'pig', 'sheep', 'cow', 'goat'], 1).first}-baby', 'produce/${pick(['carrot', 'apple', 'pear', 'banana', 'cherry', 'orange'], 1).first}'))
      .toList();
  late int m = rounds[0].$2;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() => m = rounds[g.round].$2;

  @override
  Widget build(BuildContext context) {
    final (n, _) = rounds[g.round];
    final (a, f) = pairs[g.round];
    void change(int d) {
      if (g.lock) return;
      final v = (m + d).clamp(0, 6);
      setState(() => m = v);
      if (v == n) g.ok('_', 1000);
    }

    final ok = g.marks['_'] == 'correct';
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      task: TaskCard(icons: [Pic(a, w: 44, h: 44), Pic(f, w: 44, h: 44)], text: 'Сделай поровну: каждому малышу по угощению'),
      // Горизонтально: малыши слева, угощения посередине, «плюс» справа.
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: LbCard(
                color: C.gamePanel,
                padding: 14,
                child: Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [for (var i = 0; i < n; i++) Pic(a, w: 64, h: 64)]),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Center(
              child: SizedBox(
                width: 96 * 3 + 24,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < m; i++)
                      AnswerTile(key: ValueKey('f$i'), content: Pic(f, w: 72, h: 72), label: 'убрать угощение', size: 96, state: ok ? 'correct' : 'idle', onTap: () => change(-1)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          LbIconButton(LucideIcons.plus, size: 'lg', label: 'добавить угощение', onTap: g.lock ? null : () => change(1)),
        ],
      ),
    );
  }
}

// ───────────────────────── Колесо дня ─────────────────────────

const _quarters = [
  ('morning', 'daywheel/time-morning', C.bubble100),
  ('day', 'daywheel/time-day', C.flask100),
  ('evening', 'daywheel/time-evening', C.spark100),
  ('night', 'daywheel/time-night', C.flask300),
];
const _acts = [
  ('morning', 'daywheel/act-wake', 'Когда просыпаемся?'),
  ('day', 'daywheel/act-lunch', 'Когда обедаем?'),
  ('evening', 'daywheel/act-bath', 'Когда купаемся перед сном?'),
  ('night', 'daywheel/act-sleep', 'Когда спим?'),
];

class DayWheelGame extends StatefulWidget {
  const DayWheelGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<DayWheelGame> createState() => _DayWheelGameState();
}

class _DayWheelGameState extends GameState<DayWheelGame> {
  late final rounds = shuffle(_acts);
  double rot = 90;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;

  @override
  void initState() {
    super.initState();
    onRound();
  }

  /// Новый раунд: колесо встаёт на случайную НЕправильную четверть.
  @override
  void onRound() {
    final ai = _quarters.indexWhere((q) => q.$1 == rounds[g.round].$1);
    final opts = [0, 1, 2, 3].where((t) => t != ai).toList();
    final t = opts[rnd.nextInt(3)];
    final want = ((4 - t) % 4) * 90;
    final d = ((want - rot) % 360 + 360) % 360;
    rot += d;
  }

  int get top => ((-rot / 90).round() % 4 + 4) % 4;

  void check() {
    if (g.lock) return;
    _quarters[top].$1 == rounds[g.round].$1 ? g.ok('wheel', 1000) : g.bad('wheel');
  }

  @override
  Widget build(BuildContext context) {
    final (_, img, text) = rounds[g.round];
    const w = 290.0, s = 104.0, r0 = 82.0;
    const pos = [Offset(w / 2, w / 2 - r0), Offset(w / 2 + r0, w / 2), Offset(w / 2, w / 2 + r0), Offset(w / 2 - r0, w / 2)];
    final m = g.marks['wheel'];
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      task: TaskCard(icons: [Pic(img, w: 56, h: 56)], text: text),
      // Горизонтально: колесо слева, кнопки справа.
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(size: const Size(32, 24), painter: _Pointer()),
                  const SizedBox(height: 6),
                  Wiggle(
                    active: m == 'wrong',
                    child: GestureDetector(
                      onTap: () => setState(() => rot += 90),
                      child: Container(
                        width: w,
                        height: w,
                        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [if (m == 'correct') ring(8, C.slime300), lip(5)]),
                        child: AnimatedRotation(
                          turns: rot / 360,
                          duration: Dur.ret,
                          curve: Ease.ret,
                          child: Stack(
                            children: [
                              CustomPaint(size: const Size(w, w), painter: _WheelPainter()),
                              for (final (i, q) in _quarters.indexed)
                                Positioned(
                                  left: pos[i].dx - s / 2,
                                  top: pos[i].dy - s / 2,
                                  width: s,
                                  height: s,
                                  child: AnimatedRotation(
                                    turns: -rot / 360,
                                    duration: Dur.ret,
                                    curve: Ease.ret,
                                    child: Pic(q.$2, w: s, h: s),
                                  ),
                                ),
                              Positioned(
                                left: w / 2 - 16,
                                top: w / 2 - 16,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: C.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: C.ink900, width: 3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LbIconButton(LucideIcons.rotateCcw, size: 'lg', label: 'Повернуть влево', onTap: () => setState(() => rot -= 90)),
              const SizedBox(width: 16),
              HintPulse(
                active: g.hint,
                child: LbIconButton(LucideIcons.check, size: 'lg', label: 'Проверить', onTap: check),
              ),
              const SizedBox(width: 16),
              LbIconButton(LucideIcons.rotateCw, size: 'lg', label: 'Повернуть вправо', onTap: () => setState(() => rot += 90)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // conic-gradient(from -45deg): четверть 0 (утро) — сверху.
    for (final (i, q) in _quarters.indexed) {
      canvas.drawArc(rect, (-135 + 90 * i) * math.pi / 180, math.pi / 2, true, Paint()..color = q.$3);
    }
    canvas.drawOval(
      rect.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = C.ink900,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Pointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = C.ink900,
  );
  @override
  bool shouldRepaint(_) => false;
}
