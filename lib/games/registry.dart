// Реестр игр (window.LB_REG) и темы главного экрана (LB_TOPICS).
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'build.dart';
import 'bridge.dart';
import 'choice.dart';
import 'coloring.dart';
import 'feed.dart';
import 'harvest.dart';
import 'kit.dart';
import 'misc.dart';
import 'order.dart';
import 'parents.dart';
import 'scene.dart';
import 'sort.dart';

final games = <String, GameDef>{
  for (final d in [
    GameDef(
      id: 'bridge', label: 'Почини мостик', icon: LucideIcons.hammer,
      tone: 'spark', bg: 'bridge/scene-wide.png', hint: false,
      rules: 'Перетащи дощечку в проём мостика. Сначала дощечка одна, затем выбери подходящую из двух. Короткой дощечки не хватит, чтобы закрыть проём.',
      build: (a) => BridgeGame(a),
    ),
    GameDef(
      id: 'mama',
      label: 'Найди родителей',
      icon: LucideIcons.baby,
      tone: 'bubble',
      rules: 'Малыш потерялся. Наверху — маленький зверёк. Возьми его пальцем и перетащи к его маме и папе.',
      bg: 'animals/farm.jpg',
      build: (a) => ParentsGame(a),
    ),
    GameDef(
      id: 'shadows',
      label: 'Тени',
      icon: LucideIcons.moon,
      tone: 'flask',
      rules: 'Слева — цветная картинка, справа — три тени. Возьми картинку пальцем и перетащи на тень, которая к ней подходит.',
      build: (a) => ShadowGame(a),
    ),
    GameDef(
      id: 'odd',
      label: 'Четвёртый лишний',
      icon: LucideIcons.circleOff,
      tone: 'tomato',
      rules: 'Три картинки дружат, одна — лишняя. Нажми на ту, что не подходит к остальным.',
      build: (a) => ChoiceGame(a, make: makeOdd, size: 140),
    ),
    GameDef(
      id: 'count',
      label: 'Сколько?',
      icon: LucideIcons.squirrel,
      tone: 'spark',
      bg: 'feed/meadow.jpg',
      rules: 'Зверята проголодались! Посчитай, сколько их на полянке, и нажми на кучку, где угощения столько же — каждому по одному.',
      build: (a) => FeedGame(a),
    ),
    GameDef(
      id: 'veggies',
      bg: null,
      label: 'Собери овощи',
      icon: LucideIcons.carrot,
      tone: 'slime',
      hint: false,
      rules: 'Овощи поспели на грядках. Возьми каждый пальцем и перетащи в корзинку внизу.',
      build: (a) => HarvestGame(a, scene: vegScene),
    ),
    GameDef(
      id: 'fruits',
      bg: null,
      label: 'Собери фрукты',
      icon: LucideIcons.apple,
      tone: 'slime',
      hint: false,
      rules: 'Фрукты созрели на деревьях. Сорви каждый пальцем и перетащи в корзинку внизу.',
      build: (a) => HarvestGame(a, scene: fruitScene),
    ),
    GameDef(
      id: 'houses',
      label: 'Разложи по домикам',
      icon: LucideIcons.house,
      tone: 'spark',
      bg: 'houses/yard.jpg',
      rules: 'Наведи порядок: перетащи пальцем каждую вещь в домик такого же цвета.',
      build: (a) => SortGame(a, make: makeHouses),
    ),
    GameDef(
      id: 'kitchen',
      label: 'Помоги на кухне',
      icon: LucideIcons.utensilsCrossed,
      tone: 'flask',
      bg: kitchenScene.bg,
      bgAlign: kitchenScene.align,
      rules: 'Помоги навести порядок на кухне: возьми пальцем посуду с подноса и поставь на её место — на тень такой же формы.',
      build: (a) => SceneGame(a, scene: kitchenScene),
    ),
    GameDef(
      id: 'room',
      label: 'Уборка в комнате',
      icon: LucideIcons.bedDouble,
      tone: 'bubble',
      bg: roomScene.bg,
      bgAlign: roomScene.align,
      rules: 'В комнате беспорядок: возьми пальцем вещь с подноса и поставь на её место — на тень такой же формы.',
      build: (a) => SceneGame(a, scene: roomScene),
    ),
    GameDef(
      id: 'hide',
      label: 'Где спрятался?',
      icon: LucideIcons.armchair,
      tone: 'spark',
      rules: 'Котёнок прячется. Посмотри на стрелку в задании и нажми на пунктирное место, куда она показывает: на, под, в, слева или справа.',
      build: (a) => PlaceGame(a),
    ),
    GameDef(
      id: 'matryoshka',
      label: 'Матрёшки',
      icon: LucideIcons.personStanding,
      tone: 'bubble',
      rules: 'Построй матрёшек по росту. Нажимай на матрёшек по очереди: сначала на самую маленькую, потом на ту, что побольше, и так до самой большой.',
      build: (a) => OrderGame(a, make: makeMatryoshka),
    ),
    GameDef(
      id: 'sequence',
      label: 'Сначала — потом',
      icon: LucideIcons.listOrdered,
      tone: 'flask',
      rules: 'Разложи историю по порядку. Нажми на то, что было сначала, потом — что было дальше.',
      build: (a) => OrderGame(a, make: makeSequence),
    ),
    GameDef(id: 'puzzle', label: 'Пазлы', icon: LucideIcons.puzzle, tone: 'flask', rules: 'Собери картинку. Нажми на кусочек внизу, а потом на его место в рамке.', build: (a) => PuzzleGame(a)),
    GameDef(
      id: 'shapes',
      label: 'Конструктор фигур',
      icon: LucideIcons.shapes,
      tone: 'tomato',
      rules: 'Собери кораблик, бабочку и ракету. Выбери деталь справа, затем нажми на пунктирный контур слева.',
      build: (a) => ShapesGame(a),
    ),
    GameDef(
      id: 'findpair',
      label: 'Найди пару',
      icon: LucideIcons.shirt,
      tone: 'flask',
      bg: 'clothes/yard.jpg',
      rules:
          'Вещи сохнут на верёвке, но у каждой потерялась пара. Найди внизу такую же вещь того же цвета и повесь рядом: нажми на неё или перетащи на пустую прищепку. Сначала — носочки, потом другие вещи, потом всё вперемешку.',
      build: (a) => FindPairGame(a),
    ),
    GameDef(
      id: 'equal',
      label: 'Поровну',
      icon: LucideIcons.scale,
      tone: 'slime',
      hint: false,
      rules: 'Каждому малышу нужно одно угощение. Если угощений мало — нажми на «плюс». Если много — нажми на лишнее, и оно исчезнет.',
      build: (a) => EqualGame(a),
    ),
    GameDef(
      id: 'coloring',
      label: 'Раскраска',
      icon: LucideIcons.palette,
      tone: 'bubble',
      hint: false,
      rules: 'Выбери режим: «По образцу» или «Самостоятельно». Нажми на краску и закрашивай части картинки. В режиме «По образцу» повтори цвета маленькой картинки. Когда работа готова, нажми на галочку.',
      build: (a) => ColoringGame(a),
    ),
    GameDef(
      id: 'daywheel',
      label: 'Колесо дня',
      icon: LucideIcons.sunMoon,
      tone: 'flask',
      rules:
          'Посмотри на картинку в задании. Поворачивай колесо стрелками или нажатием, пока под чёрным треугольником не окажется нужная часть суток: утро, день, вечер или ночь. Потом нажми на зелёную галочку.',
      build: (a) => DayWheelGame(a),
    ),
  ])
    d.id: d,
};

class Topic {
  const Topic(this.title, this.goal, this.icon, this.tone, this.games);
  final String title, goal, tone;
  final IconData icon;
  final List<String> games;
}

const topics = [
  Topic('Животные и растения', 'Кто чей детёныш, что растёт в огороде и в саду', LucideIcons.pawPrint, 'slime', ['mama', 'veggies', 'fruits']),
  Topic('Цвета', 'Различать и называть основные цвета', LucideIcons.palette, 'bubble', ['findpair', 'houses', 'coloring']),
  Topic('Счёт', 'Считать до 3, потом до 6. Больше, меньше, поровну', LucideIcons.hash, 'spark', ['count', 'equal']),
  Topic('Формы и величина', 'Фигуры, силуэты, от маленького к большому', LucideIcons.shapes, 'flask', ['shadows', 'shapes', 'matryoshka', 'kitchen', 'room', 'bridge']),
  Topic('Логика', 'Найти лишнее, собрать целое из частей', LucideIcons.lightbulb, 'tomato', ['odd', 'puzzle']),
  Topic('Время суток и времена года', 'Утро, день, вечер, ночь. Что сначала, что потом', LucideIcons.sunMoon, 'spark', ['daywheel', 'sequence']),
  Topic('Где что находится', 'На, под, слева, справа', LucideIcons.move, 'flask', ['hide']),
];
