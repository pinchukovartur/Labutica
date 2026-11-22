import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/landscape_artwork.dart';
import '../games/registry.dart';
import 'goals.dart';

class AllGamesScreen extends StatelessWidget {
  const AllGamesScreen({
    super.key,
    required this.age,
    required this.starCount,
    required this.onOpen,
    required this.onParent,
    required this.onExit,
    required this.onAlbum,
    this.readyStickers = 0,
  });

  final String age;
  final int starCount;
  final ValueChanged<String> onOpen;
  final VoidCallback onParent, onExit, onAlbum;
  final int readyStickers;

  // Coordinates on the shelf artwork. Each card opens the corresponding registry entry.
  static const _cards = {
    'bridge': Rect.fromLTRB(296, 128, 535, 282),
    'mama': Rect.fromLTRB(545, 128, 776, 282),
    'shadows': Rect.fromLTRB(787, 128, 1014, 282),
    'odd': Rect.fromLTRB(1025, 128, 1260, 282),
    'count': Rect.fromLTRB(1270, 128, 1512, 282),
    'veggies': Rect.fromLTRB(296, 303, 535, 449),
    'fruits': Rect.fromLTRB(545, 303, 776, 449),
    'houses': Rect.fromLTRB(787, 303, 1014, 449),
    'kitchen': Rect.fromLTRB(1025, 303, 1260, 449),
    'room': Rect.fromLTRB(1270, 303, 1512, 449),
    'hide': Rect.fromLTRB(296, 468, 537, 621),
    'matryoshka': Rect.fromLTRB(548, 468, 770, 621),
    'sequence': Rect.fromLTRB(780, 468, 1027, 621),
    'puzzle': Rect.fromLTRB(1038, 468, 1283, 621),
    'shapes': Rect.fromLTRB(1294, 468, 1515, 621),
    'findpair': Rect.fromLTRB(375, 641, 627, 781),
    'equal': Rect.fromLTRB(636, 641, 889, 781),
    'coloring': Rect.fromLTRB(902, 641, 1155, 781),
    'daywheel': Rect.fromLTRB(1170, 641, 1427, 781),
  };

  @override
  Widget build(BuildContext context) {
    return LandscapeArtwork(
      asset: 'assets/brand/all-games-wide.png',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 780,
            top: 14,
            width: 370,
            height: 84,
            child: Semantics(header: true, label: 'Все игры'),
          ),
          for (final MapEntry(key: id, value: bounds) in _cards.entries)
            Positioned.fromRect(
              rect: bounds,
              child: Semantics(
                label: games[id]!.label,
                button: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    focusColor: const Color(0x6623DBCD),
                    onTap: () => onOpen(id),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 9,
            left: 195,
            child: _menuButton(
              'Выйти в меню выбора возраста',
              LucideIcons.arrowLeft,
              onExit,
            ),
          ),
          Positioned(
            top: 154,
            left: 195,
            child: _menuButton(
              'Чему учимся в этом возрасте',
              LucideIcons.circleQuestionMark,
              () => showAgeGoals(context, age),
            ),
          ),
          Positioned(
            top: 9,
            right: 195,
            child: _menuButton(
              'Для родителей',
              LucideIcons.lock,
              onParent,
              count: starCount,
            ),
          ),
          Positioned.fromRect(
            rect: const Rect.fromLTRB(1180, 4, 1480, 94),
            child: Tooltip(
              message: 'Альбом Ума лапки',
              excludeFromSemantics: true,
              child: Semantics(
                label: 'Альбом Ума лапки',
                value: readyStickers > 0 ? 'Наклеек: $readyStickers' : null,
                button: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    focusColor: const Color(0x6623DBCD),
                    onTap: onAlbum,
                    child: Stack(
                      children: [
                        if (readyStickers > 0)
                          Positioned(
                            top: 6,
                            right: 0,
                            child: ExcludeSemantics(
                              child: Badge.count(
                                count: readyStickers,
                                largeSize: 32,
                                textStyle: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    int count = 0,
  }) {
    return LbIconButton(
      icon,
      label: label,
      extent: 84,
      onTap: onPressed,
      badge: count > 0 ? count.toString() : null,
    );
  }
}
