// Общий каркас мини-игр (kit.jsx): GameShell, GameCtl (useGame), TaskCard, PromptTile, Swatch, Dots.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/game_audio.dart';
import '../ds/motion.dart';
import '../ds/tokens.dart';

final rnd = math.Random();
List<T> shuffle<T>(Iterable<T> a) => [...a]..shuffle(rnd);
List<T> pick<T>(Iterable<T> a, int n) => shuffle(a).take(n).toList();

/// Картинка из `assets/<path>.png`.
class Pic extends StatelessWidget {
  const Pic(this.path, {super.key, this.w, this.h, this.fit = BoxFit.contain, this.color, this.align = Alignment.center});
  final String path;
  final double? w, h;
  final BoxFit fit;
  final Color? color;
  final Alignment align;
  @override
  Widget build(BuildContext context) {
    final px = ((w ?? h ?? 200) * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      'assets/$path.png',
      width: w,
      height: h,
      fit: fit,
      alignment: align,
      cacheWidth: px,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

typedef DoneFn = void Function(int stars);

class GameArgs {
  const GameArgs({required this.def, required this.age, required this.onHome, required this.onDone});
  final GameDef def;
  final int age;
  final VoidCallback onHome;
  final DoneFn onDone;
}

class GameDef {
  const GameDef({required this.id, required this.label, required this.icon, required this.tone, required this.rules, required this.build, this.hint = true, this.bg = 'feed/meadow.jpg', this.bgAlign = Alignment.center});
  final String id, label, tone, rules;

  /// Фон на весь экран, путь от assets/ с расширением. Рисует AppShell — под вырезом камеры тоже.
  final String? bg;

  /// Какой частью фон прижат к экрану, когда он не помещается целиком (BoxFit.cover).
  final Alignment bgAlign;
  final IconData icon;
  final bool hint;
  final Widget Function(GameArgs a) build;
}

/// Аналог useGame: раунды, 2 ошибки подряд → подсказка, звёзды по числу ошибок.
class GameCtl extends ChangeNotifier {
  GameCtl(this.total, this.onDone);
  final int total;
  final DoneFn onDone;
  int round = 0, miss = 0, err = 0;
  Map<Object, String> marks = {};
  bool lock = false;
  bool _done = false, _disposed = false;
  final _timers = <Timer>[];

  bool get hint => miss >= 2;
  int stars() => math.max(1, 3 - err ~/ 2);

  void _later(int ms, VoidCallback f) => _timers.add(
    Timer(Duration(milliseconds: ms), () {
      if (!_disposed) f();
    }),
  );
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void finish([int delay = 700]) => _finish(delay, playSuccess: true);

  void _finish(int delay, {required bool playSuccess}) {
    if (_done) return;
    _done = true;
    lock = true;
    if (playSuccess) unawaited(playGameSound(GameSound.taskSuccess));
    _emit();
    _later(delay, () => onDone(stars()));
  }

  void next() {
    miss = 0;
    marks = {};
    lock = false;
    if (round + 1 >= total) {
      _finish(0, playSuccess: false);
    } else {
      round++;
    }
    _emit();
  }

  void ok(Object k, [int delay = 800]) {
    if (lock || _done) return;
    marks = {...marks, k: 'correct'};
    miss = 0;
    lock = true;
    unawaited(playGameSound(GameSound.taskSuccess));
    _emit();
    _later(delay, next);
  }

  void bad(Object k) {
    err++;
    miss++;
    marks = {...marks, k: 'wrong'};
    _emit();
    _later(650, () {
      if (marks[k] != 'wrong') return;
      marks = Map.of(marks)..remove(k);
      _emit();
    });
  }

  void good() {
    miss = 0;
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}

/// База для игр: создаёт GameCtl, перерисовывает на его изменения и
/// вызывает [onRound] при переходе к новому раунду (как useEffect([g.round])).
abstract class GameState<W extends StatefulWidget> extends State<W> {
  late final GameCtl g;
  GameArgs get args;
  int get totalRounds;
  int _seen = 0;
  void onRound() {}

  @override
  void initState() {
    super.initState();
    g = GameCtl(totalRounds, args.onDone)..addListener(_changed);
  }

  void _changed() {
    if (g.round != _seen) {
      _seen = g.round;
      onRound();
    }
    setState(() {});
  }

  @override
  void dispose() {
    g.dispose();
    super.dispose();
  }

  /// Состояние плитки: отметка ошибки/успеха важнее подсветки.
  String tileState(Object k, {bool done = false, bool selected = false, bool hint = false}) => done
      ? 'done'
      : g.marks[k] ??
            (selected
                ? 'selected'
                : hint
                ? 'hint'
                : 'idle');
}

/// Окно с правилами игры — кнопка «?» в шапке.
void showRules(BuildContext context, GameDef def) => showLbDialog<void>(
  context,
  title: def.label,
  body: (_) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(def.rules),
      if (def.hint) ...[
        const SizedBox(height: 8),
        Text('Ошибаться не страшно: предмет вернётся на место. После двух ошибок подряд правильный ответ подсветится.', style: body(15, FontWeight.w600, C.ink500, 1.5)),
      ],
    ],
  ),
  actions: (ctx) => [LbButton('Понятно', onTap: () => Navigator.of(ctx).pop())],
);

class GameShell extends StatelessWidget {
  const GameShell({super.key, required this.args, required this.round, required this.total, this.task, required this.child});
  final GameArgs args;
  final int round, total;
  final Widget? task;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    // С картинкой-фоном (GameDef.bg) оболочка прозрачная: фон рисует AppShell.
    color: args.def.bg == null ? C.paper : Colors.transparent,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          // В горизонтальной раскладке задание стоит в шапке, между «Домой» и прогрессом.
          child: Row(
            children: [
              LbIconButton(LucideIcons.house, label: 'Домой', onTap: args.onHome),
              const SizedBox(width: 16),
              if (task != null) ...[Expanded(child: task!), const SizedBox(width: 16)] else const Spacer(),
              ProgressDots(total: total, current: math.min(round, total - 1)),
              if (task == null) const Spacer() else const SizedBox(width: 16),
              LbIconButton(LucideIcons.circleQuestionMark, label: 'Правила игры', onTap: () => showRules(context, args.def)),
            ],
          ),
        ),
        Expanded(
          child: Padding(padding: const EdgeInsets.fromLTRB(24, 10, 24, 16), child: child),
        ),
      ],
    ),
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.icons, required this.text});
  final List<Widget> icons;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: C.gamePanel,
      borderRadius: BorderRadius.circular(R.lg),
    ),
    child: Row(
      children: [
        for (final (i, ic) in icons.indexed)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: ic,
          ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: body(15, FontWeight.w700, C.ink900, 1.3))),
      ],
    ),
  );
}

/// Квадратик с иконкой для TaskCard.
class TaskIcon extends StatelessWidget {
  const TaskIcon(this.icon, {super.key});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: C.paper2,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.ink900, width: 2),
    ),
    child: Icon(icon, size: 26, color: C.ink900),
  );
}

class PromptTile extends StatelessWidget {
  const PromptTile({super.key, required this.child, this.size = 140});
  final Widget child;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: C.gamePanel,
      borderRadius: BorderRadius.circular(R.lg),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(R.lg - 3),
      child: Stack(
        children: [
          Center(child: child),
          const Positioned(top: 0, left: 0, right: 0, height: 4, child: ColoredBox(color: Color(0x66FFFFFF))),
        ],
      ),
    ),
  );
}

class Swatch extends StatelessWidget {
  const Swatch(this.color, {super.key, this.size = 44});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: C.ink900, width: 3),
    ),
  );
}

class Dots extends StatelessWidget {
  const Dots(this.n, {super.key, this.size = 14});
  final int n;
  final double size;
  @override
  Widget build(BuildContext context) {
    final cols = math.min(n, 3);
    return SizedBox(
      width: cols * size + (cols - 1) * 6,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < n; i++)
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(color: C.ink900, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

/// Карточка, которую ребёнок перетаскивает пальцем. Во время перетаскивания
/// на месте остаётся бледная копия, а «в руке» — чуть увеличенная и наклонённая.
class DragItem<T extends Object> extends StatelessWidget {
  const DragItem({super.key, required this.data, required this.child, this.enabled = true, this.hint = false});
  final T data;
  final Widget child;
  final bool enabled, hint;
  @override
  Widget build(BuildContext context) => Draggable<T>(
    data: data,
    maxSimultaneousDrags: enabled ? 1 : 0,
    feedback: Material(
      type: MaterialType.transparency,
      child: Transform.rotate(angle: -.07, child: Transform.scale(scale: 1.08, child: child)),
    ),
    childWhenDragging: Opacity(opacity: .25, child: child),
    child: HintPulse(active: hint, child: child),
  );
}
