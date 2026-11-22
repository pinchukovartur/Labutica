// Анимации из tokens/effects.css: lb-pop, lb-wiggle, lb-hint, lb-fade.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// lb-pop: scale .85→1 + opacity 0→1, var(--dur-slow) var(--ease-bounce).
/// Проигрывается при монтировании и каждый раз, когда меняется [trigger].
class Pop extends StatefulWidget {
  const Pop({super.key, required this.child, this.delay = Duration.zero, this.trigger, this.enabled = true});
  final Widget child;
  final Duration delay;
  final Object? trigger;
  final bool enabled;
  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: Dur.slow);
  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() {
    if (!widget.enabled) {
      c.value = 1;
      return;
    }
    c.value = 0;
    if (widget.delay == Duration.zero) {
      c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) c.forward();
      });
    }
  }

  @override
  void didUpdateWidget(Pop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _play();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, child) {
          final t = Ease.bounce.transform(c.value);
          return Opacity(opacity: c.value.clamp(0, 1), child: Transform.scale(scale: .85 + .15 * t, child: child));
        },
        child: widget.child,
      );
}

/// lb-wiggle .3s 2 — покачивание при ошибке. Срабатывает, когда [active] становится true.
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.child, required this.active});
  final Widget child;
  final bool active;
  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  @override
  void initState() {
    super.initState();
    if (widget.active) c.forward();
  }

  @override
  void didUpdateWidget(Wiggle old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) c.forward(from: 0);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, child) {
          // 0 → -6° → +6° → 0, дважды.
          final p = (c.value * 2) % 1;
          double deg;
          if (p < .25) {
            deg = -6 * (p / .25);
          } else if (p < .75) {
            deg = -6 + 12 * ((p - .25) / .5);
          } else {
            deg = 6 * (1 - (p - .75) / .25);
          }
          if (c.value == 0 || c.value == 1) deg = 0;
          return Transform.rotate(angle: deg * math.pi / 180, child: child);
        },
        child: widget.child,
      );
}

/// lb-hint 1.2s infinite — мягкая пульсация подсказки.
class HintPulse extends StatefulWidget {
  const HintPulse({super.key, required this.child, required this.active});
  final Widget child;
  final bool active;
  @override
  State<HintPulse> createState() => _HintPulseState();
}

class _HintPulseState extends State<HintPulse> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.active) {
      c.repeat();
    } else {
      c.stop();
      c.value = 0;
    }
  }

  @override
  void didUpdateWidget(HintPulse old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, child) {
          final p = c.value < .5 ? c.value * 2 : (1 - c.value) * 2;
          return Transform.scale(scale: 1 + .08 * Ease.out.transform(p), child: child);
        },
        child: widget.child,
      );
}
