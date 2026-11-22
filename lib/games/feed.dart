// «Сколько?»: на полянке сидят зверята, нужно выбрать кучку еды, где угощения ровно столько, сколько зверят.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

/// Зверёк и его угощение: картинки `feed/<зверёк>.png` и `feed/<еда>.png`.
const feedPairs = {'dog': 'bone', 'squirrel': 'acorn', 'cat': 'fish', 'bunny': 'carrot', 'mouse': 'cheese', 'hedgehog': 'apple'};

class FeedGame extends StatefulWidget {
  const FeedGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<FeedGame> createState() => _FeedGameState();
}

class _FeedGameState extends GameState<FeedGame> {
  // Раунд — зверёк, сколько их, и три кучки еды. До 4 лет — от 1 до 3, дальше — до 6.
  late final List<(String, int, List<int>)> rounds = () {
    final big = args.age >= 4;
    return [
      for (final a in pick(feedPairs.keys, 5))
        () {
          final n = 1 + rnd.nextInt(big ? 6 : 3);
          final opts = big
              ? [
                  n,
                  ...pick({n - 2, n - 1, n + 1, n + 2}.where((x) => x >= 1 && x <= 7), 2),
                ]
              : [1, 2, 3];
          return (a, n, shuffle(opts));
        }(),
    ];
  }();
  int? picked;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() => picked = null;

  void tap(int v) {
    if (g.lock) return;
    if (v == rounds[g.round].$2) {
      setState(() => picked = v);
      g.ok(v, 1300);
    } else {
      g.bad(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (animal, n, opts) = rounds[g.round];
    final food = feedPairs[animal]!;
    final hint = g.hint ? n : null;
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth, h = c.maxHeight;
          return Row(
            children: [
              // Зверята — на песочной площадке, внизу слева.
              SizedBox(
                width: w * .52,
                child: Align(
                  alignment: const Alignment(0, .85),
                  child: _Herd(key: ValueKey('herd-${g.round}'), pic: 'feed/$animal', n: n, w: w * .5, h: h * .62, fed: picked != null ? food : null),
                ),
              ),
              const Spacer(),
              // Три кучки еды — на светлых подносах столбиком справа, поднос не шире пяти угощений.
              SizedBox(
                width: math.min(w * .44, h * .29 * 3.4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (i, v) in opts.indexed) ...[if (i > 0) SizedBox(height: h * .03), SizedBox(height: h * .29, child: _pile(food, v, hint == v))],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pile(String food, int v, bool hint) {
    final m = g.marks[v];
    return Wiggle(
      active: m == 'wrong',
      child: HintPulse(
        active: hint,
        child: GestureDetector(
          onTap: () => tap(v),
          child: AnimatedContainer(
            duration: Dur.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: switch (m) {
                'correct' => C.slime300.withValues(alpha: .9),
                'wrong' => C.tomato300.withValues(alpha: .9),
                _ => C.gamePanel,
              },
              borderRadius: BorderRadius.circular(R.xl),
              border: Border.all(width: 4, color: hint ? C.spark300 : Colors.transparent),
            ),
            child: LayoutBuilder(
              builder: (_, c) {
                // Угощение в один ряд; если не влезает — в два.
                final rows = v > 4 ? 2 : 1;
                final perRow = (v / rows).ceil();
                final s = math.min(c.maxHeight / rows, c.maxWidth / perRow) * .92;
                return Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 0,
                    runSpacing: 0,
                    children: [
                      for (var i = 0; i < v; i++)
                        SizedBox(
                          width: s,
                          height: s,
                          child: Pic('feed/$food', w: s, h: s),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Зверята на площадке: в два ряда, дальний ряд чуть меньше и выше. Когда накормлены — у каждого лапок угощение.
class _Herd extends StatelessWidget {
  const _Herd({super.key, required this.pic, required this.n, required this.w, required this.h, this.fed});
  final String pic;
  final int n;
  final double w, h;
  final String? fed;

  @override
  Widget build(BuildContext context) {
    final back = n > 3 ? n ~/ 2 : 0, front = n - back;
    final s = math.min(h * (back > 0 ? .55 : .8), w / math.max(front, 1) * 1.05);
    Widget one(int i, double size) => Pop(
      delay: Duration(milliseconds: 60 * i),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Pic(pic, w: size, h: size, align: Alignment.bottomCenter),
            if (fed != null)
              Positioned(
                right: -size * .05,
                bottom: 0,
                width: size * .4,
                height: size * .4,
                child: Pop(
                  child: Pic('feed/$fed', w: size * .4, h: size * .4),
                ),
              ),
          ],
        ),
      ),
    );
    Widget row(int from, int count, double size) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * .02),
            child: one(from + i, size),
          ),
      ],
    );
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (back > 0) Positioned(bottom: s * .55, child: row(front, back, s * .85)),
          Positioned(bottom: 0, child: row(0, front, s)),
        ],
      ),
    );
  }
}
