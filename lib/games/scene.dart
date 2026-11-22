// Сцены с тенями («Помоги на кухне», «Уборка в комнате»): вещи с подноса нужно поставить на их места — на тень такой же формы.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

class ShadowScene {
  const ShadowScene({required this.dir, required this.size, required this.align, required this.tray, required this.shadow, required this.slots, this.drawn = const {}});

  /// Папка в assets: фон `<dir>/<dir>.jpg` и картинки вещей `<dir>/<id>.png`.
  final String dir;

  /// Размер фона в пикселях.
  final Size size;

  /// Фон не помещается в широкий экран по высоте: как его прижать, чтобы влезли все тени.
  final Alignment align;

  /// В каком углу поля стоит поднос с вещами.
  final Alignment tray;

  /// Цвет теней на фоне.
  final Color shadow;

  /// Места вещей на фоне: левый, верхний, правый, нижний край в пикселях картинки.
  final Map<String, Rect> slots;

  /// Тени этих вещей на фоне нет (стёрли: была другой формы) — рисуем её сами из картинки вещи.
  final Set<String> drawn;

  String get bg => '$dir/$dir.jpg';
}

const kitchenScene = ShadowScene(
  dir: 'kitchen',
  size: Size(1536, 1024),
  align: Alignment(0, -.75),
  tray: Alignment.bottomLeft,
  shadow: Color(0xFF8F6672),
  slots: {
    'pot': Rect.fromLTRB(55, 195, 330, 392),
    'bowl': Rect.fromLTRB(574, 128, 706, 204),
    'kettle': Rect.fromLTRB(586, 245, 779, 444),
    'plate': Rect.fromLTRB(818, 566, 1105, 704),
    'fork': Rect.fromLTRB(740, 553, 802, 717),
    'spoon': Rect.fromLTRB(1118, 550, 1180, 718),
    'cup': Rect.fromLTRB(1233, 570, 1401, 699),
  },
  // Серые вилку с ложкой и тень чайника другой формы стёрли с фона.
  drawn: {'fork', 'spoon', 'kettle'},
);

const roomScene = ShadowScene(
  dir: 'room',
  size: Size(1671, 941),
  align: Alignment(0, -.6),
  tray: Alignment.bottomRight,
  shadow: Color(0xFF496CAC),
  slots: {
    'grandpa': Rect.fromLTRB(167, 281, 369, 657),
    'books': Rect.fromLTRB(276, 129, 352, 219),
    'plant': Rect.fromLTRB(388, 81, 481, 219),
    'bear': Rect.fromLTRB(711, 318, 818, 454),
    'cup': Rect.fromLTRB(797, 505, 905, 601),
    'dress': Rect.fromLTRB(1281, 188, 1428, 401),
    'blanket': Rect.fromLTRB(1382, 449, 1511, 543),
  },
  // Тени на фоне нарисованы не по этим картинкам (другой дедушка, цветок, книги) — стёрли все.
  drawn: {'grandpa', 'books', 'plant', 'bear', 'cup', 'dress', 'blanket'},
);

class SceneGame extends StatefulWidget {
  const SceneGame(this.args, {super.key, required this.scene});
  final GameArgs args;
  final ShadowScene scene;
  @override
  State<SceneGame> createState() => _SceneGameState();
}

class _SceneGameState extends GameState<SceneGame> {
  ShadowScene get sc => widget.scene;
  late final queue = shuffle(sc.slots.keys);
  final placed = <String>{};
  String? hover;

  /// Где на экране лежит поле игры: по нему пересчитываем тени с фона в свои координаты.
  final _area = GlobalKey();
  Offset? _origin;
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => 1;

  void drop(String slot, String item) {
    hover = null;
    if (g.lock || placed.contains(item)) return;
    if (slot == item) {
      placed.add(item);
      g.good();
      if (placed.length == sc.slots.length) g.finish();
    } else {
      g.bad(item);
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
    final scr = MediaQuery.sizeOf(context);
    // На подносе — три следующие вещи из очереди.
    final tray = queue.where((x) => !placed.contains(x)).take(3).toList();
    final hint = g.hint && tray.isNotEmpty ? tray.first : null;
    final item = scr.height * .17;
    // Тени лежат отдельным слоем на весь экран игры: верхние (миска на полке) выше поля, под шапкой, и касания должны до них доходить.
    return Stack(
      children: [
        GameShell(
          args: args,
          round: placed.length,
          total: sc.slots.length,
          child: Align(
            alignment: sc.tray,
            child: Container(
              width: item * 3.5,
              height: item * 1.3,
              decoration: BoxDecoration(color: C.gamePanel, borderRadius: BorderRadius.circular(R.xl)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [for (final x in tray) SizedBox(key: ValueKey(x), width: item, height: item, child: _item(x, item, hint == x))],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: SizedBox.expand(
            key: _area,
            child: _origin == null
                ? null
                : Builder(
                    builder: (_) {
                      // Фон растянут AppShell на весь экран (BoxFit.cover, sc.align) — та же раскладка здесь.
                      final k = math.max(scr.width / sc.size.width, scr.height / sc.size.height);
                      final off = Offset((scr.width - sc.size.width * k) * (sc.align.x + 1) / 2, (scr.height - sc.size.height * k) * (sc.align.y + 1) / 2) - _origin!;
                      Rect place(Rect r) {
                        final s = Rect.fromLTRB(r.left * k, r.top * k, r.right * k, r.bottom * k).shift(off);
                        return s.inflate(s.shortestSide * .03);
                      }

                      return Stack(
                        children: [for (final MapEntry(key: id, value: r) in sc.slots.entries) Positioned.fromRect(rect: place(r), child: _slot(id, hint == id))],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Место под вещь: тень. Пока пусто — принимает вещь, потом показывает её на месте.
  Widget _slot(String id, bool hint) {
    final path = '${sc.dir}/$id';
    if (placed.contains(id)) return Pop(child: Pic(path, fit: BoxFit.fill));
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        if (g.lock) return false;
        setState(() => hover = id);
        return true;
      },
      onLeave: (_) => setState(() => hover = null),
      onAcceptWithDetails: (d) => drop(id, d.data),
      builder: (_, _, _) => AnimatedScale(
        scale: hover == id ? 1.08 : 1,
        duration: Dur.fast,
        child: LayoutBuilder(
          builder: (_, c) {
            // Белая обводка — та же картинка белым, сдвинутая во все стороны.
            final o = c.biggest.shortestSide * .03;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (sc.drawn.contains(id)) ...[
                  for (var a = 0; a < 8; a++)
                    Transform.translate(
                      offset: Offset(math.cos(a * math.pi / 4), math.sin(a * math.pi / 4)) * o,
                      child: Pic(path, fit: BoxFit.fill, color: C.white),
                    ),
                  Pic(path, fit: BoxFit.fill, color: sc.shadow),
                ],
                // Подсказка: на нужной тени мигает белый силуэт.
                if (hint)
                  HintPulse(
                    active: true,
                    child: Pic(path, fit: BoxFit.fill, color: C.white.withValues(alpha: .6)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item(String id, double s, bool hint) {
    final pic = Pic('${sc.dir}/$id', w: s, h: s);
    return Wiggle(
      active: g.marks[id] == 'wrong',
      child: HintPulse(
        active: hint,
        child: Draggable<String>(
          data: id,
          maxSimultaneousDrags: g.lock ? 0 : 1,
          feedback: Material(
            type: MaterialType.transparency,
            child: Transform.scale(scale: 1.15, child: pic),
          ),
          childWhenDragging: Opacity(opacity: .25, child: pic),
          child: pic,
        ),
      ),
    );
  }
}
