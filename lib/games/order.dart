// games-order.jsx — OrderGame (E4): Матрёшки, Сначала — потом.
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../ds/components.dart';
import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

class OrderItem {
  const OrderItem(this.k, {this.img, this.pic, this.w = 0, this.h = 0});
  final int k;
  final String? img; // матрёшка: картинка без плитки, своего роста
  final String? pic; // картинка в плитке
  final double w, h;
}

List<List<OrderItem>> makeMatryoshka(int age) => (age >= 4 ? [4, 5, 5] : [3, 4, 5]).map((n) {
      final cols = shuffle(['red', 'blue', 'yellow', 'green', 'pink']);
      final step = n > 4 ? 18 : n > 3 ? 22 : 30, base = n > 4 ? 46 : 56;
      return List.generate(n, (i) {
        final h = (base + i * step).toDouble();
        return OrderItem(i, img: 'matryoshka/matryoshka-${cols[i]}', h: h, w: (h * .571).roundToDouble());
      });
    }).toList();

List<List<OrderItem>> makeSequence(int age) {
  const s = 'sequence/', d = 'daywheel/';
  final all = [
    ['${s}plant-1', '${s}plant-2', '${s}plant-3', '${s}plant-4'],
    ['${s}snow-1', '${s}snow-2', '${s}snow-3'],
    ['${s}apple-1', '${s}apple-2', '${s}apple-3'],
    ['${d}time-morning', '${d}time-day', '${d}time-evening', '${d}time-night'],
    ['${d}act-wake', '${d}act-lunch', '${d}act-bath', '${d}act-sleep'],
  ];
  return pick(all, 4).map((seq) => [for (final (i, p) in seq.indexed) OrderItem(i, pic: p)]).toList();
}

class OrderGame extends StatefulWidget {
  const OrderGame(this.args, {super.key, required this.make});
  final GameArgs args;
  final List<List<OrderItem>> Function(int age) make;
  @override
  State<OrderGame> createState() => _OrderGameState();
}

class _OrderGameState extends GameState<OrderGame> {
  late final rounds = widget.make(widget.args.age);
  var placed = <int>[];
  late var items = shuffle(rounds[0]);
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() {
    placed = [];
    items = shuffle(rounds[g.round]);
  }

  @override
  Widget build(BuildContext context) {
    final r = rounds[g.round];
    final nextK = placed.length < r.length ? r[placed.length].k : null;
    void choose(OrderItem it) {
      if (g.lock || placed.contains(it.k)) return;
      if (it.k == nextK) {
        placed = [...placed, it.k];
        g.good();
        if (placed.length == r.length) g.ok('_all', 1000);
      } else {
        g.bad(it.k);
      }
    }

    const sw = 76.0;
    final isImg = r.first.img != null;
    final rowH = isImg ? r.map((i) => i.h).reduce(math.max) : sw;
    final all = g.marks['_all'];

    final slots = Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (final (i, ri) in r.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: isImg ? ri.w : sw,
            height: isImg ? ri.h : sw,
            child: i < placed.length
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: isImg
                        ? Pop(enabled: all == 'correct', trigger: all, child: Pic(r[placed[i]].img!, w: ri.w, h: ri.h))
                        : AnswerTile(content: Pic(r[placed[i]].pic!, w: 64, h: 64), size: sw, state: all ?? 'idle'),
                  )
                : DashedBorder(radius: R.md, fill: C.gamePanel, child: const SizedBox.expand()),
          ),
          const SizedBox(height: 6),
          Text('${i + 1}', style: display(14, FontWeight.w700, C.ink900)),
        ]),
      ],
    ]);

    final pool = Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.end, spacing: 12, runSpacing: 12, children: [
      for (final it in items)
        if (isImg)
          _Doll(
            key: ValueKey('${g.round}-${it.k}'),
            it: it,
            hidden: placed.contains(it.k),
            wrong: g.marks[it.k] == 'wrong',
            hint: g.hint && it.k == nextK,
            onTap: () => choose(it),
          )
        else
          AnswerTile(
            key: ValueKey('${g.round}-${it.k}'),
            content: Pic(it.pic!, w: 80, h: 80),
            size: 96,
            state: tileState(it.k, done: placed.contains(it.k), hint: g.hint && it.k == nextK),
            onTap: () => choose(it),
          ),
    ]);

    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: ConstrainedBox(constraints: BoxConstraints(minHeight: rowH), child: FittedBox(fit: BoxFit.scaleDown, child: slots))),
        const Spacer(),
        pool,
      ]),
    );
  }
}

class _Doll extends StatelessWidget {
  const _Doll({super.key, required this.it, required this.hidden, required this.wrong, required this.hint, required this.onTap});
  final OrderItem it;
  final bool hidden, wrong, hint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget img = Pic(it.img!, w: it.w, h: it.h);
    if (hint) {
      // drop-shadow(0 0 8px spark-500): подсвечиваем силуэт.
      img = Stack(alignment: Alignment.center, children: [
        ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Pic(it.img!, w: it.w, h: it.h, color: C.spark500)),
        img,
      ]);
    }
    return IgnorePointer(
      ignoring: hidden,
      child: Opacity(
        opacity: hidden ? 0 : 1,
        child: Semantics(
          button: true,
          label: 'матрёшка',
          child: GestureDetector(onTap: onTap, child: HintPulse(active: hint, child: Wiggle(active: wrong, child: img))),
        ),
      ),
    );
  }
}
