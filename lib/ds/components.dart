// Компоненты дизайн-системы «Лабитики» (components/* и components.css из Claude Design).
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'motion.dart';
import 'tokens.dart';

// ───────────────────────── .lb-press ─────────────────────────

/// Объёмная «пластилиновая» кнопка: обводка 3px, нижняя «губа» и блик сверху.
/// При нажатии опускается на высоту губы.
class Press extends StatefulWidget {
  const Press({
    super.key,
    required this.child,
    this.onTap,
    this.color = C.white,
    this.radius = R.md,
    this.circle = false,
    this.lip = 5,
    this.width,
    this.height,
    this.rings = const [],
    this.lift = 0,
    this.lipOverride,
    this.disabled = false,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final bool circle;
  final double lip;
  final double? width, height;
  final List<BoxShadow> rings;
  final double lift;
  final double? lipOverride;
  final bool disabled;
  final EdgeInsets padding;
  final AlignmentGeometry alignment;
  final String? semanticLabel;
  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final active = w.onTap != null && !w.disabled;
    final pressed = _down && active;
    final lipH = w.disabled ? 5.0 : (w.lipOverride ?? w.lip);
    final inner = math.max(0.0, w.radius - 3);
    final content = Stack(fit: StackFit.passthrough, children: [
      Padding(
        padding: w.padding,
        child: Align(alignment: w.alignment, widthFactor: w.width == null ? 1 : null, heightFactor: w.height == null ? 1 : null, child: w.child),
      ),
      const Positioned(top: 0, left: 0, right: 0, height: 4, child: ColoredBox(color: Color(0x66FFFFFF))),
    ]);
    Widget box = AnimatedContainer(
      duration: Dur.fast,
      curve: Ease.out,
      width: w.width,
      height: w.height,
      transform: Matrix4.translationValues(0, pressed ? w.lip : w.lift, 0),
      decoration: BoxDecoration(
        color: w.disabled ? C.ink100 : w.color,
        shape: w.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: w.circle ? null : BorderRadius.circular(w.radius),
        border: Border.all(color: w.disabled ? C.ink300 : C.ink900, width: 3),
        boxShadow: pressed ? const [] : [...w.rings, lip(lipH, w.disabled ? C.ink300 : C.ink900)],
      ),
      child: w.circle ? ClipOval(child: content) : ClipRRect(borderRadius: BorderRadius.circular(inner), child: content),
    );
    if (w.disabled) {
      box = DefaultTextStyle.merge(style: const TextStyle(color: C.ink500), child: IconTheme.merge(data: const IconThemeData(color: C.ink500), child: box));
    }
    return Semantics(
      button: true,
      label: w.semanticLabel,
      enabled: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: active ? (_) => _set(true) : null,
        onTapUp: active ? (_) => _set(false) : null,
        onTapCancel: active ? () => _set(false) : null,
        onTap: active ? w.onTap : null,
        child: box,
      ),
    );
  }
}

// ───────────────────────── Button / IconButton ─────────────────────────

class LbButton extends StatelessWidget {
  const LbButton(this.label, {super.key, this.variant = 'primary', this.size = 'md', this.icon, this.iconRight, this.block = false, this.disabled = false, this.onTap});
  final String label;
  final String variant, size;
  final IconData? icon, iconRight;
  final bool block, disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (height, pad, fontSize, iconSize) = switch (size) {
      'sm' => (38.0, 14.0, 13.0, 16.0),
      'lg' => (64.0, 28.0, 18.0, 22.0),
      _ => (50.0, 20.0, 15.0, 18.0),
    };
    final action = disabled ? null : onTap;
    final color = variant == 'ghost'
        ? (action == null ? C.ink500 : C.ink900)
        : _ActionButton.foreground(action != null);
    final row = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: iconSize, color: color), const SizedBox(width: 8)],
        Text(label, style: display(fontSize, FontWeight.w700, color)),
        if (iconRight != null) ...[const SizedBox(width: 8), Icon(iconRight, size: iconSize, color: color)],
      ],
    );
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Center(widthFactor: block ? null : 1, child: row),
    );
    if (variant == 'ghost') {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: action,
          child: SizedBox(height: height, child: content),
        ),
      );
    }
    return _ActionButton(height: height, onTap: action, child: content);
  }
}

class LbIconButton extends StatelessWidget {
  const LbIconButton(this.icon, {super.key, this.size = 'md', this.extent, required this.label, this.onTap, this.badge});
  final IconData icon;
  final String size, label;
  final double? extent;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final (defaultExtent, defaultIconSize) = switch (size) {
      'sm' => (40.0, 18.0),
      'lg' => (96.0, 44.0),
      _ => (52.0, 24.0),
    };
    final diameter = extent ?? defaultExtent;
    final iconSize = extent == null ? defaultIconSize : diameter * .44;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: _ActionButton(
        height: diameter,
        width: diameter,
        label: label,
        onTap: onTap,
        child: Center(
          child: Badge(
            isLabelVisible: badge != null,
            label: Text(badge ?? ''),
            backgroundColor: const Color(0xFFFFCF75),
            textColor: const Color(0xFF5A3017),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            child: Icon(
              icon,
              size: iconSize,
              color: _ActionButton.foreground(onTap != null),
              shadows: const [Shadow(color: Color(0x99043737), offset: Offset(0, 2), blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.height, this.width, this.label, required this.onTap, required this.child});

  final double height;
  final double? width;
  final String? label;
  final VoidCallback? onTap;
  final Widget child;

  static Color foreground(bool enabled) => enabled ? const Color(0xFFFFF2CF) : const Color(0xFFEAE3CF);

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final edge = (height * .048).clamp(2.0, 5.0);
    final radius = BorderRadius.circular(height / 2);
    final inner = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(height / 2 - edge),
      side: BorderSide(color: enabled ? const Color(0xFFA0DBCB) : const Color(0xFFC7CCBE), width: edge / 2),
    );
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? const [Color(0xFFFFF4D4), Color(0xFFE5B66B)]
                  : const [Color(0xFFE0DFD1), Color(0xFFB4B6A9)],
            ),
            boxShadow: enabled
                ? [BoxShadow(color: const Color(0x663C230D), offset: Offset(0, edge), blurRadius: edge * 2)]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(edge),
            child: Material(
              shape: inner,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: enabled
                        ? const [Color(0xFF168E85), Color(0xFF075B5B)]
                        : const [Color(0xFF87988C), Color(0xFF5D6D65)],
                  ),
                ),
                child: InkWell(
                  onTap: onTap,
                  customBorder: inner,
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) return const Color(0x40002E30);
                    if (states.contains(WidgetState.focused)) return const Color(0x44FFF2CF);
                    return null;
                  }),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LbBadge extends StatelessWidget {
  const LbBadge(this.text, {super.key, this.color = C.bubble500});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 22),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, border: Border.all(color: C.ink900, width: 2), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: display(11, FontWeight.w700).copyWith(height: 1, letterSpacing: 0)),
      );
}

// ───────────────────────── Stars ─────────────────────────

class LbStar extends StatelessWidget {
  const LbStar({super.key, required this.size, required this.on});
  final double size;
  final bool on;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _StarPainter(on));
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.on);
  final bool on;
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final path = Path();
    const cx = 12.0, cy = 12.6, ro = 10.2, ri = 4.9;
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? ro : ri;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset((cx + r * math.cos(a)) * k, (cy + r * math.sin(a)) * k);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = on ? C.spark500 : C.ink100);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * k
          ..strokeJoin = StrokeJoin.round
          ..color = on ? C.ink900 : C.ink300);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.on != on;
}

class StarReward extends StatelessWidget {
  const StarReward({super.key, this.stars = 3, this.size = 72});
  final int stars;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: Transform.translate(
                offset: Offset(0, i == 1 ? -14 : 0),
                child: Pop(enabled: i < stars, delay: Duration(milliseconds: i * 150), child: LbStar(size: i == 1 ? size * 1.25 : size, on: i < stars)),
              ),
            ),
        ],
      );
}

// ───────────────────────── Child UI ─────────────────────────

class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.total, required this.current});
  final int total, current;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Задание ${current + 1} из $total',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: Container(
                width: i == current ? 22 : 16,
                height: i == current ? 22 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current ? C.spark300 : C.white,
                  border: Border.all(color: C.ink900, width: 2),
                  boxShadow: i == current ? [ring(4, C.spark300)] : null,
                ),
              ),
            ),
        ]),
      );
}

/// Плитка-ответ: idle / selected / hint / correct / wrong / done.
class AnswerTile extends StatelessWidget {
  const AnswerTile({super.key, this.icon, this.content, this.tone = 'white', this.size = 112, this.width, this.height, this.state = 'idle', this.onTap, this.label = ''});
  final IconData? icon;
  final Widget? content;
  final String tone, state, label;
  final double size;
  final double? width, height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      'correct' => C.slime300.withValues(alpha: .92),
      'wrong' => C.tomato300.withValues(alpha: .92),
      _ => tone == 'white' ? C.gamePanel : C.fill(tone).withValues(alpha: .92),
    };
    final border = switch (state) {
      'selected' || 'hint' => C.spark500,
      _ => Colors.transparent,
    };
    final inner = content != null
        ? DefaultTextStyle(style: display((size * .48).roundToDouble(), FontWeight.w800), child: content!)
        : Icon(icon, size: size * .55, color: C.ink900);
    final radius = BorderRadius.circular(R.lg);
    Widget tile = Semantics(
      label: label,
      button: true,
      enabled: onTap != null && state != 'done',
      selected: state == 'selected',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: state == 'done' ? null : onTap,
        child: AnimatedContainer(
          duration: Dur.fast,
          width: width ?? size,
          height: height ?? size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(color: border, width: 3),
          ),
          child: Center(child: inner),
        ),
      ),
    );
    tile = Pop(enabled: state == 'correct', trigger: state == 'correct', child: tile);
    tile = Wiggle(active: state == 'wrong', child: tile);
    tile = HintPulse(active: state == 'hint', child: tile);
    if (state == 'done') tile = IgnorePointer(child: Opacity(opacity: .35, child: tile));
    return tile;
  }
}

class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.tone, required this.art, required this.label, this.stars = 0, this.isNew = false, this.width = 160, this.height = 180, this.onTap});
  final String tone, label;
  final Widget art;
  final int stars;
  final bool isNew;
  final double width, height;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        color: C.fill(tone),
        radius: R.xl,
        lip: 7,
        width: width,
        height: height,
        semanticLabel: label,
        child: Column(children: [
          Expanded(child: Center(child: art)),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(color: C.white, border: Border(top: BorderSide(color: C.ink900, width: 3))),
            child: Row(children: [
              for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(right: 4), child: LbStar(size: 20, on: i < stars)),
              const Spacer(),
              if (isNew) const LbBadge('!'),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── Display ─────────────────────────

class LbCard extends StatelessWidget {
  const LbCard({super.key, required this.child, this.padding = 16, this.color = C.white});
  final Widget child;
  final double padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(color: color, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(R.lg), boxShadow: [lip(5)]),
        child: child,
      );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.tone = 'white', this.mono = false});
  final String text, tone;
  final bool mono;
  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: C.fill(tone), border: Border.all(color: C.ink900, width: 2), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: mono ? _mono(12) : body(13, FontWeight.w800)),
      );
  static TextStyle _mono(double s) => TextStyle(fontFamily: Fonts.mono, fontSize: s, fontWeight: FontWeight.w700, color: C.ink900);
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, required this.max, this.tone = 'slime', this.label, this.showValue = false});
  final num value, max;
  final String tone;
  final Widget? label;
  final bool showValue;
  @override
  Widget build(BuildContext context) {
    final p = (value / max).clamp(0.0, 1.0).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (label != null || showValue)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: DefaultTextStyle(
            style: body(13, FontWeight.w700),
            child: Row(children: [
              Expanded(child: label ?? const SizedBox()),
              if (showValue) Text('$value/$max', style: mono(13)),
            ]),
          ),
        ),
      Container(
        height: 20,
        decoration: BoxDecoration(color: C.ink100, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(999)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: p),
              duration: Dur.slow,
              curve: Ease.out,
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: C.tone(tone, 500), borderRadius: BorderRadius.circular(999)),
                  child: const Align(alignment: Alignment.topCenter, child: SizedBox(height: 4, width: double.infinity, child: ColoredBox(color: Color(0x66FFFFFF)))),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ───────────────────────── Navigation ─────────────────────────

class LbTabs extends StatelessWidget {
  const LbTabs({super.key, required this.tabs, required this.value, required this.onChange});
  final List<(String, String)> tabs; // (id, label)
  final String value;
  final ValueChanged<String> onChange;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: C.paper2, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(R.lg)),
        child: Row(children: [
          for (final (i, t) in tabs.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(t.$1),
                child: AnimatedContainer(
                  duration: Dur.fast,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.$1 == value ? C.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(R.md),
                    border: Border.all(color: t.$1 == value ? C.ink900 : Colors.transparent, width: 2),
                    boxShadow: t.$1 == value ? [lip(3)] : null,
                  ),
                  child: Text(t.$2, style: display(13, FontWeight.w700, t.$1 == value ? C.ink900 : C.ink700)),
                ),
              ),
            ),
          ],
        ]),
      );
}

class LbAppBar extends StatelessWidget {
  const LbAppBar({super.key, required this.title, this.onBack, this.actions = const []});
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: Row(children: [
            if (onBack != null) Padding(padding: const EdgeInsets.only(left: 8), child: LbIconButton(LucideIcons.arrowLeft, size: 'sm', label: 'Назад', onTap: onBack)) else const SizedBox(width: 8),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: display(18), overflow: TextOverflow.ellipsis)),
            ...actions,
          ]),
        ),
      );
}

// ───────────────────────── Feedback ─────────────────────────

/// Модальное окно .lb-dialog поверх затемнения .lb-scrim.
Future<T?> showLbDialog<T>(BuildContext context, {String? title, required Widget Function(BuildContext) body, List<Widget> Function(BuildContext)? actions, bool closable = true, double maxWidth = 360}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: closable,
    barrierLabel: 'Закрыть',
    barrierColor: Colors.transparent,
    transitionDuration: Dur.med,
    pageBuilder: (ctx, _, _) => LbDialog(title: title, maxWidth: maxWidth, onClose: closable ? () => Navigator.of(ctx).pop() : null, actions: actions?.call(ctx), child: body(ctx)),
    transitionBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  );
}

class LbDialog extends StatelessWidget {
  const LbDialog({super.key, this.title, required this.child, this.actions, this.onClose, this.maxWidth = 360});
  final double maxWidth;
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: const ColoredBox(color: C.scrim)),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Pop(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(color: C.paper, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(R.xl), boxShadow: [lip(7)]),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (title != null) Padding(padding: const EdgeInsets.only(right: 40, bottom: 8), child: Text(title!, style: display(20, FontWeight.w700, C.ink900, 1.25))),
                      DefaultTextStyle(style: body(15, FontWeight.w600, C.ink700, 1.5), child: child),
                      if (actions != null) ...[
                        const SizedBox(height: 20),
                        Row(children: [for (final (i, a) in actions!.indexed) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: a)]]),
                      ],
                    ]),
                    if (onClose != null) Positioned(top: -12, right: -8, child: LbIconButton(LucideIcons.x, size: 'sm', label: 'Закрыть', onTap: onClose)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
}

class ParentGate extends StatefulWidget {
  const ParentGate({super.key, this.digits = const ['7', '4'], this.prompt, required this.onPass});
  final List<String> digits;
  final String? prompt;
  final VoidCallback onPass;
  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate> {
  List<String> v = [];
  bool err = false;
  void press(String d) {
    final n = [...v, d];
    setState(() {
      err = false;
      if (n.length < widget.digits.length) {
        v = n;
        return;
      }
      v = [];
      if (n.join() == widget.digits.join()) {
        widget.onPass();
      } else {
        err = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', ''];
    // Горизонтально: задание и ячейки слева, цифры справа.
    return Row(children: [
      Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.prompt ?? 'Для взрослых: нажмите ${widget.digits.join(' и ')}', textAlign: TextAlign.center, style: display(18, FontWeight.w700, C.ink900, 1.3)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < widget.digits.length; i++)
              Container(
                width: 44,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: err ? C.tomato100 : C.white, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(12)),
                child: Text(i < v.length ? v[i] : '', style: display(24, FontWeight.w800)),
              ),
          ]),
        ]),
      ),
      const SizedBox(width: 20),
      SizedBox(
        width: 250,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          padding: const EdgeInsets.only(bottom: 5),
          children: [
            for (final d in keys)
              d.isEmpty ? const SizedBox() : Press(onTap: () => press(d), radius: R.md, semanticLabel: d, child: Text(d, style: display(22))),
          ],
        ),
      ),
    ]);
  }
}

class LbToast extends StatelessWidget {
  const LbToast({super.key, required this.title, this.message});
  final String title;
  final String? message;
  @override
  Widget build(BuildContext context) => Pop(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: C.white, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(R.lg), boxShadow: [lip(5)]),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: C.slime300, shape: BoxShape.circle, border: Border.all(color: C.ink900, width: 2)),
              child: const Icon(LucideIcons.check, size: 22, color: C.ink900),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: display(14)),
                if (message != null) Text(message!, style: body(13, FontWeight.w600, C.ink700)),
              ]),
            ),
          ]),
        ),
      );
}

// ───────────────────────── Forms ─────────────────────────

class LbSelect extends StatelessWidget {
  const LbSelect({super.key, required this.label, required this.options, required this.value, required this.onChange, this.hint});
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChange;
  final String? hint;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(label, style: display(13)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => showLbDialog<void>(
            context,
            title: label,
            body: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
              for (final o in options) LbRadio(label: o, checked: o == value, onChange: () {
                onChange(o);
                Navigator.of(ctx).pop();
              }),
            ]),
          ),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: C.white, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(R.md)),
            child: Row(children: [
              Expanded(child: Text(value, style: body(16, FontWeight.w700))),
              const Icon(LucideIcons.chevronDown, size: 20, color: C.ink900),
            ]),
          ),
        ),
        if (hint != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(hint!, style: body(13, FontWeight.w600, C.ink500))),
      ]);
}

class LbSwitch extends StatelessWidget {
  const LbSwitch({super.key, required this.checked, required this.onChange, required this.label});
  final bool checked;
  final ValueChanged<bool> onChange;
  final String label;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChange(!checked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            AnimatedContainer(
              duration: Dur.med,
              width: 58,
              height: 34,
              decoration: BoxDecoration(color: checked ? C.slime500 : C.ink200, border: Border.all(color: C.ink900, width: 3), borderRadius: BorderRadius.circular(999)),
              child: AnimatedAlign(
                duration: Dur.slow,
                curve: Ease.bounce,
                alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(color: C.white, shape: BoxShape.circle, border: Border.all(color: C.ink900, width: 3)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: body(15, FontWeight.w700))),
          ]),
        ),
      );
}

class _CheckBase extends StatelessWidget {
  const _CheckBase({required this.label, required this.checked, required this.onTap, required this.round});
  final String label;
  final bool checked, round;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            AnimatedContainer(
              duration: Dur.fast,
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked && !round ? C.slime500 : C.white,
                shape: round ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: round ? null : BorderRadius.circular(9),
                border: Border.all(color: C.ink900, width: 3),
                boxShadow: [lip(3)],
              ),
              child: !checked
                  ? null
                  : round
                      ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: C.ink900, shape: BoxShape.circle))
                      : const Icon(LucideIcons.check, size: 18, color: C.ink900),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: body(15, FontWeight.w700))),
          ]),
        ),
      );
}

class LbCheckbox extends StatelessWidget {
  const LbCheckbox({super.key, required this.label, required this.checked, required this.onChange});
  final String label;
  final bool checked;
  final ValueChanged<bool> onChange;
  @override
  Widget build(BuildContext context) => _CheckBase(label: label, checked: checked, round: false, onTap: () => onChange(!checked));
}

class LbRadio extends StatelessWidget {
  const LbRadio({super.key, required this.label, required this.checked, required this.onChange});
  final String label;
  final bool checked;
  final VoidCallback onChange;
  @override
  Widget build(BuildContext context) => _CheckBase(label: label, checked: checked, round: true, onTap: onChange);
}

// ───────────────────────── Утилиты ─────────────────────────

/// Пунктирная скруглённая рамка (border: 3px dashed).
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, this.child, this.color = C.ink300, this.radius = R.md, this.width = 3, this.dash = 9, this.gap = 6, this.fill});
  final Widget? child;
  final Color color;
  final double radius, width, dash, gap;
  final Color? fill;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashPainter(color, radius, width, dash, gap, fill), child: child);
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius, this.width, this.dash, this.gap, this.fill);
  final Color color;
  final double radius, width, dash, gap;
  final Color? fill;
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius((Offset.zero & size).deflate(width / 2), Radius.circular(math.max(0, radius - width / 2)));
    if (fill != null) canvas.drawRRect(rr, Paint()..color = fill!);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawPath(dashPath(Path()..addRRect(rr), dash, gap), paint);
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color || o.radius != radius || o.fill != fill;
}

Path dashPath(Path src, double dash, double gap) {
  final out = Path();
  for (final m in src.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      out.addPath(m.extractPath(d, math.min(d + dash, m.length)), Offset.zero);
      d += dash + gap;
    }
  }
  return out;
}

/// .lb-placeholder — штриховка на месте будущего арта.
class ArtPlaceholder extends StatelessWidget {
  const ArtPlaceholder(this.text, {super.key, this.size = 220});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: DashedBorder(
          radius: R.xl,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(R.xl),
            child: CustomPaint(
              painter: _Stripes(),
              child: Center(child: Text(text.toUpperCase(), style: mono(11, FontWeight.w700, C.ink500).copyWith(letterSpacing: .66))),
            ),
          ),
        ),
      );
}

class _Stripes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0F22183A)
      ..strokeWidth = 8 / math.sqrt2 * 1.4;
    for (double x = -size.height; x < size.width + size.height; x += 16 * math.sqrt2) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
