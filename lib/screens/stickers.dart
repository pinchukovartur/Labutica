import 'package:flutter/material.dart';

typedef StickerCounts = ({int ready, int placed});

class Sticker {
  const Sticker(
    this.id,
    this.name,
    this.asset, {
    this.index,
    this.columns = 2,
    this.cellAspect = 1,
    this.number,
  });

  final String id, name, asset;
  final int? index;
  final int columns;
  final double cellAspect;
  final int? number;
}

List<Sticker> _sheet(
  String asset,
  List<String> names, {
  int columns = 2,
  double cellAspect = 1,
  bool numbered = false,
}) => [
  for (final (i, name) in names.indexed)
    Sticker(
      '$asset:$i',
      name,
      'stickers/$asset.png',
      index: i,
      columns: columns,
      cellAspect: cellAspect,
      number: numbered ? i + 1 : null,
    ),
];

final stickerPages = <(String, Color, List<Sticker>, List<Sticker>)>[
  (
    'Зверята',
    const Color(0xFFFFDA83),
    const [
      Sticker('animal:cat', 'Котёнок', 'animals/cat-baby.png'),
      Sticker('animal:dog', 'Щенок', 'animals/dog-baby.png'),
      Sticker('animal:cow', 'Телёнок', 'animals/cow-baby.png'),
      Sticker('animal:goat', 'Козлёнок', 'animals/goat-baby.png'),
      Sticker('animal:horse', 'Жеребёнок', 'animals/horse-baby.png'),
      Sticker('animal:pig', 'Поросёнок', 'animals/pig-baby.png'),
      Sticker('animal:sheep', 'Ягнёнок', 'animals/sheep-baby.png'),
      Sticker('animal:hen', 'Цыплёнок', 'animals/hen-baby.png'),
      Sticker('animal:duck', 'Утёнок', 'animals/duck-baby.png'),
    ],
    const [
      Sticker('animal:bunny', 'Зайчик', 'feed/bunny.png'),
      Sticker('animal:squirrel', 'Белочка', 'feed/squirrel.png'),
      Sticker('animal:mouse', 'Мышонок', 'feed/mouse.png'),
      Sticker('animal:hedgehog', 'Ёжик', 'feed/hedgehog.png'),
    ],
  ),
  for (final (label, color, sheet) in [
    (
      'Игрушки',
      const Color(0xFFFFCAA8),
      [
        ..._sheet('toys', ['Паровозик', 'Мишка', 'Мячик', 'Пирамидка']),
        ..._sheet('toys-extra', [
          'Игрушечная уточка',
          'Парусник',
          'Воздушный змей',
          'Ксилофон',
          'Гоночная машинка',
          'Ракета',
          'Лошадка-качалка',
          'Барабан',
        ], columns: 4),
      ],
    ),
    (
      'Овощи и фрукты',
      const Color(0xFFCDE69E),
      _sheet('produce', [
        'Морковь',
        'Брокколи',
        'Свёкла',
        'Тыква',
        'Яблоко',
        'Груша',
        'Бананы',
        'Виноград',
      ], columns: 4),
    ),
    (
      'Счёт',
      const Color(0xFFB2E2FB),
      [
        const Sticker(
          'count:0',
          'Одна ракушка',
          'stickers/one-shell.png',
          number: 1,
        ),
        ..._sheet(
          'count',
          ['Одна ракушка', 'Две ракушки', 'Три кубика', 'Четыре шарика'],
          cellAspect: 2,
          numbered: true,
        ).skip(1),
      ],
    ),
    (
      'Цвета и формы',
      const Color(0xFFF1C8F7),
      _sheet('shapes', ['Круг', 'Треугольник', 'Квадрат', 'Овал']),
    ),
    (
      'День и ночь',
      const Color(0xFFC9D1FF),
      _sheet('day', ['Рассвет', 'Облако', 'Закат', 'Месяц со звёздами']),
    ),
  ])
    (
      label,
      color,
      sheet.sublist(0, sheet.length ~/ 2),
      sheet.sublist(sheet.length ~/ 2),
    ),
];

final stickerCatalog = Map<String, Sticker>.unmodifiable({
  for (final (_, _, left, right) in stickerPages)
    for (final sticker in [...left, ...right]) sticker.id: sticker,
});

// Старые награды хранились по игре. Конвертируем их в наклейки той же темы.
const _legacyGroups = [
  ['mama', 'hide'],
  ['bridge', 'odd', 'kitchen', 'room', 'findpair', 'puzzle', 'matryoshka'],
  ['veggies', 'fruits'],
  ['count', 'equal'],
  ['houses', 'shadows', 'shapes', 'coloring'],
  ['sequence', 'daywheel'],
];

Map<String, StickerCounts> decodeStickers(Map<String, dynamic> saved) {
  final result = <String, StickerCounts>{};

  void add(String id, int ready, int placed) {
    if (ready == 0 && placed == 0) return;
    final previous = result[id] ?? (ready: 0, placed: 0);
    result[id] = (
      ready: previous.ready + ready,
      placed: previous.placed + placed,
    );
  }

  for (final MapEntry(:key, :value) in saved.entries) {
    if (value case [int ready, int placed] when ready >= 0 && placed >= 0) {
      if (stickerCatalog.containsKey(key)) {
        add(key, ready, placed);
        continue;
      }
      final group = _legacyGroups.indexWhere((games) => games.contains(key));
      if (group < 0) continue;
      final (_, _, left, right) = stickerPages[group];
      final pool = [...left, ...right];
      final offset = _legacyGroups[group].indexOf(key);
      for (var i = 0; i < pool.length; i++) {
        add(
          pool[(i + offset) % pool.length].id,
          ready ~/ pool.length + (i < ready % pool.length ? 1 : 0),
          placed ~/ pool.length + (i < placed % pool.length ? 1 : 0),
        );
      }
    }
  }
  return result;
}

class StickerArt extends StatelessWidget {
  const StickerArt(this.sticker, {super.key});

  final Sticker sticker;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/${sticker.asset}',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    final index = sticker.index;
    if (index == null) return image;

    const cellHeight = 140.0;
    final cellWidth = cellHeight * sticker.cellAspect;
    return FittedBox(
      child: SizedBox(
        width: cellWidth,
        height: cellHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment(
              2 * (index % sticker.columns) / (sticker.columns - 1) - 1,
              index < sticker.columns ? -1 : 1,
            ),
            minWidth: cellWidth * sticker.columns,
            maxWidth: cellWidth * sticker.columns,
            minHeight: cellHeight * 2,
            maxHeight: cellHeight * 2,
            child: Image.asset(
              'assets/${sticker.asset}',
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
