import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/tokens.dart';
import 'kit.dart';

const bridgeScene = 'assets/bridge/scene-wide.png';
const bridgeSceneSize = Size(1870, 841);

class BridgeGame extends StatefulWidget {
  const BridgeGame(this.args, {super.key});
  final GameArgs args;

  @override
  State<BridgeGame> createState() => _BridgeGameState();
}

class _BridgeGameState extends GameState<BridgeGame> {
  @override
  GameArgs get args => widget.args;
  @override
  int get totalRounds => 2;

  void accept(bool fits) {
    if (g.lock) return;
    if (fits) {
      g.ok('bridge', 1600);
    } else {
      g.bad('short');
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      final scale = math.max(
        viewport.maxWidth / bridgeSceneSize.width,
        viewport.maxHeight / bridgeSceneSize.height,
      );
      final sceneWidth = bridgeSceneSize.width * scale;
      final sceneHeight = bridgeSceneSize.height * scale;
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: OverflowBox(
              minWidth: sceneWidth,
              maxWidth: sceneWidth,
              minHeight: sceneHeight,
              maxHeight: sceneHeight,
              child: SizedBox(
                key: const ValueKey('bridge-scene'),
                width: sceneWidth,
                height: sceneHeight,
                child: _buildScene(),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 12,
            child: SafeArea(
              child: LbIconButton(
                LucideIcons.house,
                extent: 56,
                label: 'Домой',
                onTap: args.onHome,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 12,
            child: SafeArea(
              child: LbIconButton(
                LucideIcons.circleQuestionMark,
                extent: 56,
                label: 'Правила игры',
                onTap: () => showRules(context, args.def),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _buildScene() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      // Координаты на широком фоне 1870 × 841. Фон и детали
      // масштабируются одинаково, поэтому деталь точно заполняет проём.
      final plankWidth = width * 332 / 1870;
      final plankHeight = height * 64 / 841;
      final gapLeft = width * 770 / 1870;
      final gapTop = height * 368 / 841;
      final touchHeight = math.max(48.0, plankHeight);
      final repaired = g.marks['bridge'] == 'correct';
      final instruction = g.round == 0
          ? 'Перетащи дощечку'
          : 'Подбери дощечку по длине';

      Widget choice(bool fits, double center) {
        final length = fits ? plankWidth : plankWidth / 3;
        final plank = BridgePlank(width: length, height: plankHeight);
        return Positioned(
          left: center - length / 2,
          top: height * .855 - touchHeight / 2,
          child: Semantics(
            label: fits ? 'Длинная дощечка' : 'Очень короткая дощечка',
            child: Draggable<bool>(
              key: ValueKey(fits ? 'bridge-long' : 'bridge-short'),
              data: fits,
              maxSimultaneousDrags: g.lock ? 0 : 1,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(
                type: MaterialType.transparency,
                child: Transform.translate(
                  offset: Offset(-length / 2, -plankHeight / 2),
                  child: plank,
                ),
              ),
              childWhenDragging: SizedBox(width: length, height: touchHeight),
              child: Opacity(
                opacity: repaired ? 0 : 1,
                child: SizedBox(
                  width: length,
                  height: touchHeight,
                  child: Center(child: plank),
                ),
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              bridgeScene,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          Positioned(
            left: width * .29,
            top: height * .025,
            width: width * .41,
            height: height * .12,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    child: Text(
                      'Почини мостик',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF612600),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    child: Text(
                      instruction,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF814717),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: gapLeft,
            top: gapTop - (touchHeight - plankHeight) / 2,
            child: DragTarget<bool>(
              key: const ValueKey('bridge-gap'),
              onWillAcceptWithDetails: (_) => !g.lock,
              onAcceptWithDetails: (details) => accept(details.data),
              builder: (context, candidates, rejected) {
                final preview = candidates.isNotEmpty;
                final showPlank = repaired || preview;
                return SizedBox(
                  width: plankWidth,
                  height: touchHeight,
                  child: Center(
                    child: SizedBox(
                      key: const ValueKey('bridge-slot-visual'),
                      width: plankWidth,
                      height: plankHeight,
                      child: showPlank
                          ? Center(
                              child: Opacity(
                                opacity: repaired ? 1 : .75,
                                child: BridgePlank(
                                  width: preview && candidates.first == false
                                      ? plankWidth / 3
                                      : plankWidth,
                                  height: plankHeight,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          if (g.round == 1) choice(false, width * .30),
          choice(true, width * (g.round == 0 ? .50 : .66)),
          Positioned(
            left: width * .25,
            right: width * .25,
            bottom: height * .045,
            child: Text(
              repaired
                  ? 'Мостик готов!'
                  : g.marks['short'] == 'wrong'
                  ? 'Короткая. Попробуй длинную!'
                  : '${g.round + 1} / $totalRounds',
              textAlign: TextAlign.center,
              style: body(15, FontWeight.w800, const Color(0xFF73401E)),
            ),
          ),
        ],
      );
    },
  );
}

/// Берём рисунок целой доски из того же арта, что и мостик.
/// ClipRect отображает участок текстуры без изменения исходного изображения.
class BridgePlank extends StatelessWidget {
  const BridgePlank({super.key, required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Stack(
        children: [
          Positioned(
            left: -width * 770 / 332,
            top: -height * 313 / 54,
            width: width * 1870 / 332,
            height: height * 841 / 54,
            child: Image.asset(
              bridgeScene,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    ),
  );
}
