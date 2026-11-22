// «Собери овощи» и «Собери фрукты»: урожай на грядках или на деревьях перетаскивают в корзинку внизу.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/motion.dart';
import '../ds/tokens.dart';
import 'kit.dart';

/// Как растёт плод: висит на кусте или дереве, или сидит в лунке, прикрытый бугорком земли.
enum Grow { hang, root }

/// Плод на сцене: точка на картинке фона в долях её ширины и высоты (для корнеплода — передний край лунки),
/// размер в долях высоты экрана и наклон.
class Crop {
  const Crop(this.id, this.at, this.size, {this.grow = Grow.hang, this.angle = 0, this.mound = 1.2, this.grip = .75, this.rise = .7});
  final String id;
  final Offset at;

  /// [mound] — ширина бугорка земли перед корнеплодом в размерах плода.
  /// [grip] — ширина зоны захвата: у узкой моркови меньше, чтобы не хватать соседнюю.
  /// [rise] — какая часть корнеплода (в размерах плода) торчит над землёй.
  final double size, angle, mound, grip, rise;
  final Grow grow;
}

/// Сцена урожая: фон, как он прижат при обрезке под экран, папка с артом и что на нём растёт.
class HarvestScene {
  const HarvestScene({required this.dir, required this.bg, required this.align, required this.title, required this.crops, required this.basketAspect, required this.rim});
  final String dir, bg, title;
  final Alignment align;
  final List<Crop> crops;

  /// Пропорции корзины и где на ней передний обод (доля высоты сверху).
  final double basketAspect, rim;
}

const vegScene = HarvestScene(
  dir: 'harvest/v2',
  bg: 'garden',
  align: Alignment(0, -.2),
  title: 'Собери овощи!',
  basketAspect: 640 / 373,
  rim: .3,
  crops: [
    // Помидоры на кусте, огурцы на плетях — верхние грядки.
    Crop('tomato', Offset(.27, .235), .12),
    Crop('tomato', Offset(.33, .27), .12),
    Crop('tomato', Offset(.415, .25), .12),
    Crop('cucumber', Offset(.565, .23), .15, angle: -.15),
    Crop('cucumber', Offset(.69, .21), .15, angle: .15),
    // Шесть лунок на нижних грядках (точка — передний край впадины на фоне): морковь, свёкла, картошка и кочан.
    Crop('carrot', Offset(.226, .45), .33, grow: Grow.root, grip: .3, rise: .76, mound: 1.35),
    Crop('beet', Offset(.503, .455), .32, grow: Grow.root, rise: .8, mound: .95),
    Crop('potato', Offset(.786, .456), .3, grow: Grow.root, rise: .78, mound: 1.05),
    Crop('carrot', Offset(.194, .54), .33, grow: Grow.root, grip: .3, rise: .76, mound: 1.45),
    Crop('beet', Offset(.512, .548), .32, grow: Grow.root, rise: .8, mound: 1.05),
    Crop('cabbage', Offset(.822, .549), .24, grow: Grow.root, rise: .7, mound: 1.4),
  ],
);

const fruitScene = HarvestScene(
  dir: 'harvest',
  bg: 'orchard',
  align: Alignment.topCenter,
  title: 'Собери фрукты!',
  basketAspect: 640 / 305,
  rim: .36,
  crops: [
    Crop('apple', Offset(.07, .3), .14),
    Crop('apple', Offset(.15, .2), .14),
    Crop('apple', Offset(.22, .34), .14),
    Crop('pear', Offset(.33, .28), .15),
    Crop('pear', Offset(.43, .21), .15),
    Crop('plum', Offset(.55, .33), .14),
    Crop('plum', Offset(.63, .24), .14),
    Crop('plum', Offset(.7, .36), .14),
    Crop('orange', Offset(.83, .19), .14),
    Crop('orange', Offset(.94, .24), .14),
    Crop('lemon', Offset(.84, .53), .14),
    Crop('lemon', Offset(.94, .62), .14),
  ],
);

class HarvestGame extends StatefulWidget {
  const HarvestGame(this.args, {super.key, required this.scene});
  final GameArgs args;
  final HarvestScene scene;
  @override
  State<HarvestGame> createState() => _HarvestGameState();
}

class _HarvestGameState extends GameState<HarvestGame> {
  /// Горка в корзине: сколько плодов в каждом ряду снизу вверх.
  static const _pileRows = [4, 4, 3, 2, 2];
  static const _bgSize = Size(1536, 1024), _moundAspect = 152 / 640;
  String get dir => widget.scene.dir;
  final picked = <int>{};
  bool over = false, dragging = false, idle = true;
  Timer? _idleTimer;

  /// Текущий рывок: насколько сдвинут палец и где он был, когда плод вышел (null — ещё сидит).
  final _pull = ValueNotifier<(Offset, Offset?)>((Offset.zero, null));

  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => 1;
  List<Crop> get items => widget.scene.crops;

  @override
  void dispose() {
    _idleTimer?.cancel();
    _pull.dispose();
    super.dispose();
  }

  /// Рука-подсказка появляется в начале и после паузы без действий.
  void _restartIdle() {
    _idleTimer?.cancel();
    idle = false;
    _idleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => idle = true);
    });
  }

  void drop(int i) {
    over = false;
    if (g.lock || picked.contains(i)) return;
    picked.add(i);
    _restartIdle();
    g.good();
    if (picked.length == items.length) g.finish(900);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight;
        // Фон обрезается по BoxFit.cover — считаем, где на экране окажется точка картинки.
        final k = math.max(w / _bgSize.width, h / _bgSize.height);
        final img = Size(_bgSize.width * k, _bgSize.height * k);
        final o = Offset((w - img.width) * (widget.scene.align.x + 1) / 2, (h - img.height) * (widget.scene.align.y + 1) / 2);
        Offset at(Offset p) => o + Offset(p.dx * img.width, p.dy * img.height);

        final s = (h * .2).clamp(64.0, 120.0);
        final bw = (h * .5).clamp(170.0, 300.0), bh = bw / widget.scene.basketAspect;
        final basket = Offset(w / 2, h - bh / 2 - 6);
        final next = List.generate(items.length, (i) => i).where((i) => !picked.contains(i)).firstOrNull;
        final showHand = idle && !dragging && next != null && !g.lock;

        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: Image.asset('assets/$dir/${widget.scene.bg}.jpg', fit: BoxFit.cover, alignment: widget.scene.align)),
          // Корзина под урожаем: её горка доходит до нижних грядок и не должна перехватывать касания.
          _basket(basket, bw, bh, s),
          // От дальних к ближним: ботва нижнего ряда закрывает землю верхнего, а не наоборот.
          for (final i in [for (var i = 0; i < items.length; i++) i]..sort((a, b) => items[a].at.dy.compareTo(items[b].at.dy)))
            ..._crop(i, items[i], at(items[i].at), items[i].size * h, hinted: showHand && i == next),
          if (showHand) Positioned.fill(child: IgnorePointer(child: _HandHint(from: at(items[next].at), to: basket.translate(0, -bh * .2)))),
          Positioned(left: 20, right: 20, top: 10, child: _header()),
        ]);
      });

  /// Плод на сцене. Корнеплод сидит в лунке фона, перед ним бугорок земли — видна только верхняя часть.
  /// Сорванный уносит бугорок с собой, остаётся пустая лунка.
  List<Widget> _crop(int i, Crop c, Offset p, double s, {required bool hinted}) {
    final art = Transform.rotate(angle: c.angle, child: Pic('$dir/${c.id}', w: s, h: s));
    final root = c.grow == Grow.root;
    final mw = s * c.mound, mh = mw * _moundAspect;
    final top = root ? p.dy - s * c.rise : p.dy - s / 2;
    // Линия земли: всё ниже прячется за бугорком.
    final ground = p.dy + mh * .1;
    // Сколько тянуть, чтобы плод вышел: корнеплод сидит крепче, с куста срывается быстрее.
    final pull = s * (root ? .55 : .3);
    final gw = s * c.grip;
    if (picked.contains(i)) return const [];
    return [
      Positioned(
        left: p.dx - gw / 2,
        top: top,
        width: gw,
        height: root ? ground - top : s,
        child: Semantics(
          label: c.id,
          child: Draggable<int>(
            data: i,
            maxSimultaneousDrags: g.lock ? 0 : 1,
            onDragStarted: () => setState(() {
              _pull.value = (Offset.zero, null);
              dragging = true;
              _idleTimer?.cancel();
              idle = false;
            }),
            onDragUpdate: (d) {
              final (off, out) = _pull.value;
              final next = off + d.delta;
              _pull.value = (next, out ?? (next.distance >= pull ? next : null));
            },
            onDragEnd: (_) => setState(() {
              dragging = false;
              _restartIdle();
            }),
            feedback: Material(
              type: MaterialType.transparency,
              child: _Pulled(pull: _pull, dist: pull, size: s, width: gw, clip: root ? ground - top : null, child: art),
            ),
            childWhenDragging: const SizedBox.shrink(),
            // Подсвеченный плод светится и пульсирует, как на референсе.
            child: HintPulse(
              active: hinted,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [if (hinted) BoxShadow(color: C.lemon.withValues(alpha: .85), blurRadius: 26, spreadRadius: 4)]),
                // Корнеплод режем только снизу, по линии земли; по бокам картинка шире зоны захвата.
                child: ClipRect(
                  clipper: root ? _Above(ground - top) : null,
                  clipBehavior: root ? Clip.hardEdge : Clip.none,
                  child: OverflowBox(alignment: Alignment.topCenter, minWidth: s, maxWidth: s, minHeight: s, maxHeight: s, child: art),
                ),
              ),
            ),
          ),
        ),
      ),
      // Бугорок земли перед корнеплодом; касания не ловит, чтобы не закрывать соседей.
      if (root) Positioned(left: p.dx - mw / 2, top: p.dy - mh * .55, width: mw, height: mh, child: IgnorePointer(child: Pic('$dir/mound', w: mw, h: mh))),
    ];
  }

  /// Корзинка внизу по центру. Собранное складывается горкой: задняя стенка, плоды, передний обод поверх.
  Widget _basket(Offset c, double bw, double bh, double s) {
    final it = bw * .36, step = it * .36;
    final pile = _pileRows.length * step + it * .6;
    final rim = pile + bh * widget.scene.rim; // линия обода от верха области
    final slots = [
      for (final (r, n) in _pileRows.indexed)
        for (var k = 0; k < n; k++) Offset(bw * (.5 + (k - (n - 1) / 2) * .19), rim - r * step),
    ];
    // Горка — только картинка и касаний не ловит; принимает плоды сам корпус корзины.
    return Positioned(
      left: c.dx - bw / 2,
      top: c.dy - bh / 2 - pile,
      width: bw,
      height: bh + pile,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedScale(
              scale: over ? 1.08 : 1,
              duration: Dur.fast,
              alignment: Alignment.bottomCenter,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(left: 0, right: 0, bottom: 0, height: bh, child: Pic('$dir/basket', w: bw, h: bh)),
                for (final (n, i) in picked.indexed)
                  if (n < slots.length)
                    Positioned(
                      left: slots[n].dx - it / 2,
                      top: slots[n].dy - it * .55,
                      width: it,
                      height: it,
                      child: Pop(child: Transform.rotate(angle: ((i * 37) % 9 - 4) * .07, child: Pic('$dir/${items[i].id}', w: it, h: it))),
                    ),
                Positioned(left: 0, right: 0, bottom: 0, height: bh, child: Pic('$dir/basket_front', w: bw, h: bh)),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bh,
          child: DragTarget<int>(
            onWillAcceptWithDetails: (_) {
              if (g.lock) return false;
              setState(() => over = true);
              return true;
            },
            onLeave: (_) => setState(() => over = false),
            // В корзину — только уже вытащенный плод; проверяем при отпускании: плод над корзиной
            // мог оказаться в её зоне ещё до рывка.
            onAcceptWithDetails: (d) {
              if (_pull.value.$2 != null) {
                drop(d.data);
              } else {
                setState(() => over = false);
              }
            },
            builder: (_, _, _) => const SizedBox.expand(),
          ),
        ),
      ]),
    );
  }

  Widget _header() {
    BoxDecoration pill() => BoxDecoration(color: C.road, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: C.shadow, blurRadius: 10, offset: Offset(0, 4))]);
    return Row(children: [
      LbIconButton(LucideIcons.house, label: 'Домой', onTap: args.onHome),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: pill(),
        child: Text(widget.scene.title, style: display(18, FontWeight.w800, C.wing)),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
        decoration: pill(),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Pic('$dir/basket', w: 44, h: 22),
          const SizedBox(width: 8),
          Text('${picked.length}/${items.length}', style: display(16, FontWeight.w800, C.wing)),
        ]),
      ),
      const SizedBox(width: 12),
      LbIconButton(LucideIcons.circleQuestionMark, label: 'Правила игры', onTap: () => showRules(context, args.def)),
    ]);
  }
}

/// Рука показывает жест: от плода к корзинке, по кругу.
class _HandHint extends StatefulWidget {
  const _HandHint({required this.from, required this.to});
  final Offset from, to;
  @override
  State<_HandHint> createState() => _HandHintState();
}

class _HandHintState extends State<_HandHint> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, _) {
          final t = c.value;
          // Пауза на плоде, перенос к корзине, исчезновение.
          final move = Ease.out.transform(((t - .2) / .6).clamp(0.0, 1.0));
          final p = Offset.lerp(widget.from, widget.to, move)!;
          final fade = t < .1 ? t / .1 : (t > .85 ? (1 - t) / .15 : 1.0);
          return Stack(children: [
            Positioned(
              left: p.dx - 6,
              top: p.dy - 4,
              child: Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: C.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.shadow, blurRadius: 8, offset: Offset(0, 3))]),
                  child: const Icon(LucideIcons.pointer, size: 28, color: C.wing),
                ),
              ),
            ),
          ]);
        },
      );
}

/// Плод под пальцем. Пока его не вытащили, он стоит на месте и качается, а корнеплод понемногу
/// поднимается из лунки (низ скрыт землёй). Вытащенный — подскакивает к пальцу и дальше идёт за ним.
class _Pulled extends StatelessWidget {
  const _Pulled({required this.pull, required this.dist, required this.size, required this.width, required this.clip, required this.child});
  final ValueNotifier<(Offset, Offset?)> pull;

  /// [width] — ширина зоны захвата: картинка размером [size] стоит по её центру.
  final double dist, size, width;

  /// Линия земли от верха плода; null — плод не в земле.
  final double? clip;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<(Offset, Offset?)>(
        valueListenable: pull,
        builder: (_, v, _) {
          final (d, out) = v;
          if (out != null) {
            // Вылетает из лунки к пальцу и чуть подпрыгивает.
            final from = -out + Offset(0, clip == null ? 0 : -size * .45);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Dur.slow,
              curve: Ease.out,
              builder: (_, k, art) => Transform.translate(offset: from * (1 - k), child: Transform.scale(scale: 1 + .12 * math.sin(k * math.pi), child: art)),
              child: SizedBox(width: width, height: size, child: OverflowBox(minWidth: size, maxWidth: size, child: child)),
            );
          }
          final t = (d.distance / dist).clamp(0.0, 1.0);
          final rise = clip == null ? 0.0 : Ease.out.transform(t) * size * .45;
          final wobble = math.sin(t * math.pi * 6) * .08 * t;
          Widget art = Transform.translate(offset: Offset(0, -rise), child: Transform.rotate(angle: wobble, alignment: Alignment.bottomCenter, child: child));
          if (clip != null) art = ClipRect(clipper: _Above(clip!), child: art);
          // Плод держится на месте, сколько бы ни отъехал палец.
          return Transform.translate(offset: -d, child: SizedBox(width: width, height: size, child: OverflowBox(minWidth: size, maxWidth: size, child: art)));
        },
      );
}

/// Обрезает всё ниже линии земли [y], выше — не ограничивает.
class _Above extends CustomClipper<Rect> {
  const _Above(this.y);
  final double y;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(-size.width * 2, -size.height * 2, size.width * 3, y);
  @override
  bool shouldReclip(_Above old) => old.y != y;
}
