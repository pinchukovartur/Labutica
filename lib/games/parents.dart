// «Найди родителей»: малыша нужно перетащить пальцем к его маме и папе.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

/// Виды, для которых есть арт пары родителей (`animals/<вид>-parents.png`).
const parentSpecies = ['cat', 'dog', 'cow', 'goat', 'horse', 'pig', 'sheep', 'hen', 'duck'];

/// Малыши, которых легко перепутать: их родителей не показываем в одном раунде.
const lookAlike = {'hen': 'duck', 'duck': 'hen', 'cow': 'goat', 'goat': 'cow'};

class ParentsGame extends StatefulWidget {
  const ParentsGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<ParentsGame> createState() => _ParentsGameState();
}

class _ParentsGameState extends GameState<ParentsGame> {
  // За игру — все виды по разу, в случайном порядке.
  late final rounds = shuffle(parentSpecies);
  late var order = _targets(rounds[0]);
  String? placed, hover;

  /// Малыша уже трогали в этом раунде — чёрточки «внимание» больше не нужны.
  bool touched = false;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() {
    order = _targets(rounds[g.round]);
    placed = null;
    touched = false;
    hover = null;
  }

  /// На экране три пары родителей: нужная и две случайные — как было до козы.
  List<String> _targets(String baby) => parentTargets(baby);

  void drop(String target, String baby) {
    hover = null;
    if (g.lock) return;
    if (target == baby) {
      placed = target;
      g.ok(target, 1300);
    } else {
      g.bad(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baby = rounds[g.round];
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      // Сцена на ферме: малыш стоит на траве у забора, родители — на площадке ниже.
      child: LayoutBuilder(
        builder: (_, c) {
          final h = c.maxHeight, w = c.maxWidth;
          final s = h * .36, feet = h * .46;
          final babyPic = Pic('animals/$baby-baby', w: s, h: s, align: Alignment.bottomCenter);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (placed == null) ...[
                Positioned(left: (w - s * .8) / 2, top: feet - s * .07, width: s * .8, height: s * .14, child: const _GroundShadow()),
                Positioned(
                  left: (w - s) / 2,
                  top: feet - s,
                  width: s,
                  height: s,
                  child: Listener(
                    onPointerDown: (_) => setState(() => touched = true),
                    child: Draggable<String>(
                      key: ValueKey('baby-${g.round}'),
                      data: baby,
                      maxSimultaneousDrags: g.lock ? 0 : 1,
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: Transform.rotate(angle: -.07, child: Transform.scale(scale: 1.08, child: babyPic)),
                      ),
                      childWhenDragging: Opacity(opacity: .25, child: babyPic),
                      child: HintPulse(active: g.hint, child: babyPic),
                    ),
                  ),
                ),
                // Жёлтые чёрточки «внимание» у головы малыша — до первого касания.
                if (!touched)
                  Positioned(
                    left: w / 2 + s * .22,
                    top: feet - s * 1.28,
                    width: s * .5,
                    height: s * .5,
                    child: const IgnorePointer(child: CustomPaint(painter: _Attention())),
                  ),
              ],
              // Пары родителей в один ряд, ногами на площадке.
              Positioned(
                left: w * .02,
                right: w * .02,
                top: h * .47,
                bottom: 0,
                child: Row(
                  children: [
                    for (final (i, sp) in order.indexed) ...[if (i > 0) SizedBox(width: w * .05), Expanded(child: _target(sp, baby))],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _target(String sp, String baby) {
    final m = g.marks[sp];
    final over = hover == sp;
    final hint = g.hint && sp == baby && placed == null;
    return Wiggle(
      active: m == 'wrong',
      child: HintPulse(
        active: hint,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (_) {
            if (g.lock) return false;
            setState(() => hover = sp);
            return true;
          },
          onLeave: (_) => setState(() => hover = null),
          onAcceptWithDetails: (d) => drop(sp, d.data),
          builder: (_, _, _) => AnimatedScale(
            scale: over ? 1.03 : 1,
            duration: Dur.fast,
            child: AnimatedContainer(
              duration: Dur.fast,
              width: double.infinity,
              decoration: BoxDecoration(
                // Карточки без фона: родители стоят прямо на ферме, подсветка — только при ответе и наведении.
                color: switch (m) {
                  'correct' => C.slime300.withValues(alpha: .55),
                  'wrong' => C.tomato300.withValues(alpha: .55),
                  _ => over ? C.white.withValues(alpha: .35) : Colors.transparent,
                },
                border: Border.all(width: 5, color: hint ? C.spark300 : (over ? C.white : Colors.transparent)),
                borderRadius: BorderRadius.circular(R.xl),
              ),
              child: LayoutBuilder(
                builder: (_, c) {
                  final b = c.maxHeight * .62;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(left: c.maxWidth * .1, right: c.maxWidth * .1, bottom: 2, height: 18, child: const _GroundShadow()),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Pic('animals/$sp-parents', w: c.maxWidth - 16, h: c.maxHeight - 16, align: Alignment.bottomCenter),
                        ),
                      ),
                      // Малыш «вернулся» к родителям: встаёт посередине, между мамой и папой.
                      if (placed == sp)
                        Positioned(
                          left: (c.maxWidth - b) / 2,
                          bottom: 4,
                          width: b,
                          height: b,
                          child: Pop(
                            child: Pic('animals/$sp-baby', w: b, h: b),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Мягкая тень на земле под животным.
class _GroundShadow extends StatelessWidget {
  const _GroundShadow();
  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _ShadowPainter());
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter();
  @override
  void paint(Canvas canvas, Size size) => canvas.drawOval(
    Offset.zero & size,
    Paint()
      ..color = const Color(0x38000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * .3),
  );

  @override
  bool shouldRepaint(_ShadowPainter old) => false;
}

/// Три жёлтые чёрточки веером — «посмотри на меня».
class _Attention extends CustomPainter {
  const _Attention();
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final p = Paint()
      ..color = C.amber
      ..strokeWidth = s * .11
      ..strokeCap = StrokeCap.round;
    final o = Offset(s * .05, s * .95);
    for (final a in [-1.75, -1.15, -.55]) {
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(o + d * s * .5, o + d * s * .8, p);
    }
  }

  @override
  bool shouldRepaint(_Attention old) => false;
}

/// Три карточки раунда: родители малыша и две случайные пары, кроме похожих на него.
List<String> parentTargets(String baby) => shuffle([baby, ...pick(parentSpecies.where((s) => s != baby && s != lookAlike[baby]), 2)]);
