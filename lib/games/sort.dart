// games-sort.jsx — SortGame (E2): Разложи по домикам; PlaceGame (E8): Где спрятался?
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

class SortItem {
  const SortItem(this.img, this.k);
  final String img, k;
}

class SortBin {
  const SortBin(this.k, this.img);
  final String k, img;
}

class SortData {
  const SortData({required this.items, required this.bins});
  final List<SortItem> items;
  final List<SortBin> bins;
}

SortData makeHouses(int age) {
  final cols = pick(['red', 'blue', 'yellow', 'green'], 3);
  final things = shuffle(['sock', 'mitten', 'shirt', 'hat', 'boot']);
  final items = [
    for (final (i, c) in cols.indexed) ...[things[i], things[(i + 2) % 5]].map((t) => SortItem('clothes/$t-$c', c)),
  ];
  return SortData(items: shuffle(items), bins: cols.map((c) => SortBin(c, 'houses/house-$c')).toList());
}

class SortGame extends StatefulWidget {
  const SortGame(this.args, {super.key, required this.make});
  final GameArgs args;
  final SortData Function(int age) make;
  @override
  State<SortGame> createState() => _SortGameState();
}

class _SortGameState extends GameState<SortGame> {
  late final data = widget.make(widget.args.age);
  final placed = <int, String>{};
  String? hover, wrongBin;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => 1;

  /// Вещь [i] отпустили над корзиной или домиком [bin].
  void drop(String bin, int i) {
    hover = null;
    if (g.lock || placed.containsKey(i)) return;
    if (data.items[i].k == bin) {
      placed[i] = bin;
      g.good();
      if (placed.length == data.items.length) g.finish();
    } else {
      g.bad(i);
      setState(() => wrongBin = bin);
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && wrongBin == bin) setState(() => wrongBin = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintI = g.hint ? List.generate(data.items.length, (i) => i).firstWhere((i) => !placed.containsKey(i), orElse: () => -1) : -1;
    final hintBin = hintI >= 0 ? data.items[hintI].k : null;
    final grid = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, it) in data.items.indexed)
          placed.containsKey(i)
              ? AnswerTile(content: Pic(it.img, w: 72, h: 72), size: 86, state: 'done')
              : DragItem<int>(
                  data: i,
                  enabled: !g.lock,
                  child: AnswerTile(
                    content: Pic(it.img, w: 72, h: 72),
                    size: 86,
                    state: tileState(i, hint: hintI == i),
                  ),
                ),
      ],
    );
    return GameShell(
      args: args,
      round: placed.length,
      total: data.items.length,
      // Горизонтально: вещи на светлой панели слева, домики стоят на площадке во дворе справа.
      child: Row(
        children: [
          Center(
            child: Container(
              width: 86 * 3 + 24 + 28,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: C.gamePanel, borderRadius: BorderRadius.circular(R.xl)),
              child: grid,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(padding: const EdgeInsets.only(bottom: 18), child: _houses(hintBin)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _placedIn(String k, double size) => [
    for (final (i, it) in data.items.indexed)
      if (placed[i] == k)
        Pop(
          child: Pic(it.img, w: size, h: size),
        ),
  ];

  /// Корзина или домик, куда можно бросить вещь. Под пальцем — чуть увеличивается.
  Widget _target(String k, Widget Function(bool over) builder) => Semantics(
    label: k,
    child: Wiggle(
      active: wrongBin == k,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) {
          if (g.lock) return false;
          setState(() => hover = k);
          return true;
        },
        onLeave: (_) => setState(() => hover = null),
        onAcceptWithDetails: (d) => drop(k, d.data),
        builder: (_, _, _) => AnimatedScale(scale: hover == k ? 1.05 : 1, duration: Dur.fast, child: builder(hover == k)),
      ),
    ),
  );

  Widget _houses(String? hintBin) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final (i, b) in data.bins.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: AspectRatio(
              aspectRatio: 1,
              child: _target(
                b.k,
                // Домик стоит прямо на земле: без подложки, под пальцем только чуть растёт.
                (over) => HintPulse(
                  active: hintBin == b.k,
                  child: SizedBox.expand(
                    child: LayoutBuilder(
                      builder: (_, c) {
                        final w = c.maxWidth;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Pic(b.img, w: w, h: w),
                            ),
                            Positioned(
                              left: w * .3,
                              right: w * .3,
                              top: w * .54,
                              bottom: w * .16,
                              child: Wrap(alignment: WrapAlignment.center, runAlignment: WrapAlignment.end, spacing: 1, runSpacing: 1, children: _placedIn(b.k, w * .4 * .46)),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

// ───────────────────────── Где спрятался? ─────────────────────────

class _Obj {
  const _Obj(this.img, this.ar, this.oh, this.names, this.rel, [this.onY = 0]);
  final String img;
  final double ar, oh, onY;
  final List<String> names, rel;
}

const _objs = {
  'chair': _Obj('place-chair', .716, 180, ['на стул', 'под стул', 'слева от стула', 'справа от стула'], ['on', 'under', 'left', 'right'], .6),
  'table': _Obj('place-table', 1.504, 115, ['на стол', 'под стол', 'слева от стола', 'справа от стола'], ['on', 'under', 'left', 'right'], .06),
  'box': _Obj('place-box', 1.393, 120, ['в коробку', 'слева от коробки', 'справа от коробки'], ['in', 'left', 'right']),
};
const _arrows = {'on': LucideIcons.arrowUp, 'under': LucideIcons.arrowDown, 'left': LucideIcons.arrowLeft, 'right': LucideIcons.arrowRight, 'in': LucideIcons.arrowDownToLine};
const _cat = 'animals/cat-baby';

class PlaceGame extends StatefulWidget {
  const PlaceGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<PlaceGame> createState() => _PlaceGameState();
}

class _PlaceGameState extends GameState<PlaceGame> {
  late final List<(String, String, String)> rounds = () {
    final all = <(String, String, String)>[];
    _objs.forEach((o, v) {
      for (final (i, r) in v.rel.indexed) {
        all.add((o, r, v.names[i]));
      }
    });
    return shuffle(['on', 'under', 'left', 'right', 'in'].map((r) => pick(all.where((x) => x.$2 == r), 1).first));
  }();
  String? at;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() => at = null;

  @override
  Widget build(BuildContext context) {
    final (o, rel, text) = rounds[g.round];
    final ob = _objs[o]!;
    const z = 64.0;
    final oh = ob.oh, ow = (oh * ob.ar).roundToDouble(), l = z + 14, t = o == 'table' ? z + 4 : 16.0;
    final sw = ow + 2 * l, sh = t + oh + 6;
    final boxRim = t + oh * .38;
    final c = {
      'on': Offset(l + ow / 2, t + oh * ob.onY - z / 2),
      'under': Offset(l + ow / 2, t + oh - z / 2),
      'left': Offset(l - z / 2 - 8, t + oh - z / 2),
      'right': Offset(l + ow + z / 2 + 8, t + oh - z / 2),
      'in': Offset(l + ow / 2, boxRim - z / 4),
    };
    void tap(String zone) {
      if (g.lock || at != null) return;
      if (zone == rel) {
        at = zone;
        g.ok(zone, 1100);
      } else {
        g.bad(zone);
      }
    }

    Widget cat(String zone) {
      final p = c[zone]!;
      final size = zone == 'in' || (zone == 'under' && o == 'chair') ? 52.0 : z;
      return Positioned(
        left: p.dx - size / 2,
        top: zone == 'in' ? boxRim - size : p.dy + z / 2 - size,
        width: size,
        height: size,
        child: Pop(child: Pic(_cat, w: size, h: size)),
      );
    }

    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      task: TaskCard(icons: [const Pic(_cat, w: 44, h: 44), TaskIcon(_arrows[rel]!)], text: 'Посади котёнка $text'),
      // Горизонтально: сцена слева, котёнок справа.
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                child: SizedBox(
                  width: sw,
                  height: sh,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: t + oh - 2,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: C.ink200, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      Positioned(
                        left: l,
                        top: t,
                        width: ow,
                        height: oh,
                        child: Pic('places/${ob.img}', w: ow, h: oh, fit: BoxFit.fill),
                      ),
                      if (at != null) cat(at!),
                      for (final zone in ob.rel) _zone(c[zone]!, z, zone, rel, () => tap(zone)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Center(
              child: at == null ? const AnswerTile(content: Pic(_cat, w: 80, h: 80), label: 'котёнок', size: 96, state: 'selected') : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _zone(Offset p, double z, String zone, String rel, VoidCallback onTap) {
    final m = g.marks[zone];
    final hint = g.hint && zone == rel && at == null;
    return Positioned(
      left: p.dx - z / 2,
      top: p.dy - z / 2,
      width: z,
      height: z,
      child: Wiggle(
        active: m == 'wrong',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(color: m == 'wrong' ? const Color(0x40F0573F) : Colors.transparent, borderRadius: BorderRadius.circular(18), boxShadow: hint ? [ring(6, C.spark300)] : null),
            child: at != null ? null : DashedBorder(radius: 18, color: hint ? C.spark500 : C.ink300, child: const SizedBox.expand()),
          ),
        ),
      ),
    );
  }
}
