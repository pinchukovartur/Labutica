import 'package:flutter/material.dart';

/// Единое масштабирование широкого рисунка и привязанных к нему элементов.
class LandscapeArtwork extends StatelessWidget {
  const LandscapeArtwork({super.key, required this.asset, required this.child});
  final String asset;
  final Widget child;
  static const size = Size(1870, 841);

  @override
  Widget build(BuildContext context) => ClipRect(
    child: SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox.fromSize(
          key: const ValueKey('landscape-artboard'),
          size: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}
