// games-choice.jsx — ChoiceGame (E1/E3): Четвёртый лишний; ShadowGame — Тени (перетаскивание). «Сколько?» — в feed.dart.
import 'package:flutter/material.dart';

import '../ds/components.dart';
import '../ds/tokens.dart';
import 'kit.dart';

class Opt {
  const Opt(this.k, {this.content, this.icon, this.tone = 'white', this.label = ''});
  final Object k;
  final Widget? content;
  final IconData? icon;
  final String tone, label;
}

class ChoiceRound {
  const ChoiceRound({required this.answer, required this.options, this.prompt});
  final Object answer;
  final Widget? prompt;
  final List<Opt> options;
}

class ChoiceGame extends StatefulWidget {
  const ChoiceGame(this.args, {super.key, required this.make, this.size = 104});
  final GameArgs args;
  final List<ChoiceRound> Function(int age) make;
  final double size;
  @override
  State<ChoiceGame> createState() => _ChoiceGameState();
}

class _ChoiceGameState extends GameState<ChoiceGame> {
  late final rounds = widget.make(widget.args.age);
  late List<Opt> opts = shuffle(rounds[0].options);
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() => opts = shuffle(rounds[g.round].options);

  @override
  Widget build(BuildContext context) {
    final r = rounds[g.round];
    void choose(Opt o) {
      if (g.lock) return;
      o.k == r.answer ? g.ok(o.k) : g.bad(o.k);
    }

    final tiles = Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final o in opts)
          AnswerTile(
            key: ValueKey('${g.round}-${o.k}'),
            icon: o.icon,
            content: o.content,
            tone: o.tone,
            label: o.label,
            size: widget.size,
            state: tileState(o.k, hint: g.hint && o.k == r.answer),
            onTap: () => choose(o),
          ),
      ],
    );
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      // Горизонтально: вопрос слева, ответы справа.
      child: r.prompt == null
          ? Center(child: tiles)
          : Row(
              children: [
                Expanded(child: Center(child: r.prompt)),
                const SizedBox(width: 24),
                Expanded(child: Center(child: tiles)),
              ],
            ),
    );
  }
}

const _animals = ['cat', 'dog', 'cow', 'horse', 'hen', 'duck', 'pig', 'sheep', 'goat'];

// ───────────────────────── Тени ─────────────────────────

/// Раунды «Теней»: правильная картинка и три силуэта из той же группы.
List<(String, List<String>)> makeShadows() {
  final p = [
    ..._animals.map((x) => 'animals/$x-mom'),
    ...['carrot', 'cucumber', 'pear', 'cherry', 'banana', 'cabbage'].map((x) => 'produce/$x'),
  ];
  String cat(String s) => s.split('/').first;
  return pick(p, 5).map((t) => (t, [t, ...pick(p.where((x) => x != t && cat(x) == cat(t)), 2)])).toList();
}

/// «Тени»: цветную картинку перетаскивают на подходящий силуэт.
class ShadowGame extends StatefulWidget {
  const ShadowGame(this.args, {super.key});
  final GameArgs args;
  @override
  State<ShadowGame> createState() => _ShadowGameState();
}

class _ShadowGameState extends GameState<ShadowGame> {
  late final rounds = makeShadows();
  late var opts = shuffle(rounds[0].$2);
  String? hover, placed;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => rounds.length;
  @override
  void onRound() {
    opts = shuffle(rounds[g.round].$2);
    hover = null;
    placed = null;
  }

  void drop(String target) {
    hover = null;
    if (g.lock) return;
    if (target == rounds[g.round].$1) {
      placed = target;
      g.ok(target, 1000);
    } else {
      g.bad(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final answer = rounds[g.round].$1;
    const tile = 170.0, shadow = 120.0;
    final picture = PromptTile(
      size: tile,
      child: Pic(answer, w: tile * .84, h: tile * .84),
    );
    return GameShell(
      args: args,
      round: g.round,
      total: rounds.length,
      // Горизонтально: цветная картинка слева, силуэты справа.
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: placed != null ? const SizedBox.square(dimension: tile) : DragItem<String>(key: ValueKey('pic-${g.round}'), data: answer, enabled: !g.lock, hint: g.hint, child: picture),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final k in opts)
                    DragTarget<String>(
                      key: ValueKey('${g.round}-$k'),
                      onWillAcceptWithDetails: (_) {
                        if (g.lock) return false;
                        setState(() => hover = k);
                        return true;
                      },
                      onLeave: (_) => setState(() => hover = null),
                      onAcceptWithDetails: (_) => drop(k),
                      builder: (_, _, _) => AnimatedScale(
                        scale: hover == k ? 1.08 : 1,
                        duration: Dur.fast,
                        child: AnswerTile(
                          size: shadow,
                          // Когда картинку нашли, силуэт «раскрашивается» в неё.
                          content: placed == k ? Pic(k, w: 100, h: 100) : Opacity(opacity: .82, child: Pic(k, w: 100, h: 100, color: Colors.black)),
                          state: tileState(k, hint: g.hint && k == answer),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<ChoiceRound> makeOdd(int age) {
  final c = {
    'animals': _animals.map((n) => 'animals/$n-mom').toList(),
    'veg': ['carrot', 'tomato', 'cucumber', 'cabbage', 'potato', 'beet'].map((n) => 'produce/$n').toList(),
    'fruit': ['apple', 'pear', 'plum', 'cherry', 'banana', 'orange'].map((n) => 'produce/$n').toList(),
    'clothes': ['sock-red', 'mitten-blue', 'shirt-green', 'hat-yellow', 'boot-pink'].map((n) => 'clothes/$n').toList(),
    'transport': ['car', 'bus', 'plane', 'ship', 'train', 'bike'].map((n) => 'transport/$n').toList(),
  };
  bool food(String k) => k == 'veg' || k == 'fruit';
  return List.generate(5, (_) {
    late String a, b;
    do {
      [a, b] = pick(c.keys, 2);
    } while (age < 4 && food(a) && food(b));
    final odd = pick(c[b]!, 1).first;
    return ChoiceRound(
      answer: odd,
      options: [...pick(c[a]!, 3), odd].map((k) => Opt(k, content: Pic(k, w: 112, h: 112))).toList(),
    );
  });
}
