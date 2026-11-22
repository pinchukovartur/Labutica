// onboarding.jsx, child-home.jsx, reward.jsx — детская часть приложения.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/landscape_artwork.dart';
import '../ds/tokens.dart';
import 'stickers.dart';

/// Короткая заставка запуска. Нажатие открывает каталог сразу.
class StartupIntro extends StatefulWidget {
  const StartupIntro({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<StartupIntro> createState() => _StartupIntroState();
}

class _StartupIntroState extends State<StartupIntro>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1750),
  );

  @override
  void initState() {
    super.initState();
    _motion.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _motion.forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'Пропустить заставку',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDone,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/feed/meadow.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _motion,
                        child: Image.asset(
                          'assets/brand/mascot.png',
                          width: 168,
                          height: 190,
                          fit: BoxFit.contain,
                          semanticLabel: 'Умолапка',
                        ),
                        builder: (context, child) {
                          if (reducedMotion) return child!;
                          final t = _motion.value;
                          final bounce =
                              math.sin(t * math.pi * 2.8).abs() * (1 - t);
                          return Transform.translate(
                            offset: Offset(0, -29 * bounce),
                            child: Transform.rotate(
                              angle: .13 * math.sin(t * math.pi * 4) * (1 - t),
                              child: child,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: C.road,
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(color: C.spark300, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: C.shadow,
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Умолапка',
                              style: body(
                                50,
                                FontWeight.w900,
                                const Color(0xFF672C10),
                              ),
                            ),
                            Text(
                              '— развивайка',
                              style: body(
                                32,
                                FontWeight.w900,
                                const Color(0xFF672C10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.onDone, this.initial});
  final ValueChanged<String> onDone;
  final String? initial;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  late String age = widget.initial ?? '3';

  static const _ages = [
    ('3', 'Вторая младшая группа', Color(0xFF40DDE0)),
    ('4', 'Средняя группа', Color(0xFFFFA68A)),
    ('5', 'Старшая группа', Color(0xFFD6A4F3)),
    ('6', 'Подготовительная группа', Color(0xFFFFD745)),
  ];

  static const _artwork = 'assets/brand/sunny-welcome-wide.png';

  @override
  Widget build(BuildContext context) =>
      LandscapeArtwork(asset: _artwork, child: _artboard());

  Widget _artboard() => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;

      // Привязка к композиции рисунка: левая часть и надписи остаются из эскиза.
      Widget place(double x, double y, double w, double h, Widget child) =>
          Positioned(
            left: x * size.width,
            top: y * size.height,
            width: w * size.width,
            height: h * size.height,
            child: child,
          );

      return Stack(
        fit: StackFit.expand,
        children: [
          place(
            .137,
            .854,
            .225,
            .044,
            const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                gradient: RadialGradient(
                  colors: [Color(0x603E4213), Color(0x003E4213)],
                ),
              ),
            ),
          ),
          place(.10, .171, .32, .737, const _StandingMascot()),
          place(
            .45,
            .027,
            .50,
            .22,
            Semantics(
              header: true,
              label: appName,
              child: const SizedBox.expand(),
            ),
          ),
          place(
            .45,
            .268,
            .50,
            .078,
            Semantics(
              header: true,
              label: 'Выбери свой возраст',
              child: const SizedBox.expand(),
            ),
          ),
          for (final (i, (value, group, color)) in _ages.indexed)
            place(
              i.isEven ? .49 : .655,
              i < 2 ? .38 : .565,
              .145,
              .15,
              _WelcomeButton(
                label: '$value+',
                hint: group,
                color: color,
                selected: age == value,
                onTap: () => setState(() => age = value),
              ),
            ),
          place(
            .486,
            .744,
            .318,
            .185,
            Semantics(
              button: true,
              label: 'Начать',
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(size.height * .086),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => widget.onDone(age),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _StandingMascot extends StatefulWidget {
  const _StandingMascot();

  @override
  State<_StandingMascot> createState() => _StandingMascotState();
}

class _StandingMascotState extends State<_StandingMascot>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _motion.value = 0;
    } else {
      _replay();
    }
  }

  void _replay() => _motion.forward(from: 0);

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Semantics(
      label: 'Умолапка',
      button: _reduceMotion == false,
      hint: _reduceMotion == false
          ? 'Нажми, чтобы Умолапка помахала лапкой'
          : null,
      child: GestureDetector(
        onTap: _reduceMotion == false ? _replay : null,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final progress = _motion.value;
            final waving =
                (progress >= .10 && progress < .38) ||
                (progress >= .51 && progress < .80);
            final wave = math.sin(progress * 2 * math.pi);
            final jump = wave * wave * (1 - .55 * progress);
            return Transform.translate(
              offset: Offset(0, -constraints.maxHeight * .1 * jump),
              child: Transform.rotate(
                angle: math.sin(progress * 4 * math.pi) * .06 * (1 - progress),
                alignment: Alignment.bottomCenter,
                child: IndexedStack(
                  index: waving ? 1 : 0,
                  sizing: StackFit.expand,
                  children: [
                    for (final asset in ['sunny-mascot', 'sunny-mascot-wave'])
                      Image.asset(
                        'assets/brand/$asset.png',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

const _berry = Color(0xFF5B0929);

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.hint,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label, hint;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final radius = BorderRadius.circular(constraints.maxHeight * .35);
      final outline = Color.lerp(color, const Color(0xFF472134), .21)!;
      return Semantics(
        button: true,
        selected: selected,
        hint: hint,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? const Color(0xFFE39A04) : outline,
                width: selected ? 3 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, Color.lerp(color, outline, .55)!],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Text(
                  label,
                  style: body(
                    constraints.maxHeight * .61,
                    FontWeight.w900,
                    _berry,
                    1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class Reward extends StatelessWidget {
  const Reward({
    super.key,
    required this.stars,
    required this.onHome,
    required this.onReplay,
    this.sticker,
    this.onAlbum,
  });
  final int stars;
  final Sticker? sticker;
  final VoidCallback onHome, onReplay;
  final VoidCallback? onAlbum;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: C.slime100,
    // Горизонтально: герой слева, звёзды и кнопки справа.
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/brand/mascot.png',
              width: 240,
              height: 240,
              fit: BoxFit.contain,
              semanticLabel: 'Ума лапка',
            ),
            const SizedBox(width: 64),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 14),
                StarReward(stars: stars, size: 76),
                if (sticker case final reward?) ...[
                  const SizedBox(height: 8),
                  SizedBox(width: 125, height: 102, child: StickerArt(reward)),
                  Text(
                    'Твоя наклейка — ${reward.name}',
                    style: body(16, FontWeight.w900),
                  ),
                ],
                const SizedBox(height: 12),
                if (onAlbum != null) ...[
                  LbButton(
                    sticker != null ? 'Открыть альбом' : 'Альбом',
                    icon: LucideIcons.bookOpen,
                    onTap: onAlbum,
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LbIconButton(
                      LucideIcons.house,
                      size: 'lg',
                      label: 'Домой',
                      onTap: onHome,
                    ),
                    const SizedBox(width: 20),
                    LbIconButton(
                      LucideIcons.rotateCcw,
                      size: 'lg',
                      label: 'Ещё раз',
                      onTap: onReplay,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
