// Экраны вне игр в горизонтальной ориентации: без исключений и переполнений вёрстки.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labutica/ds/components.dart';
import 'package:labutica/main.dart';
import 'package:labutica/games/kit.dart';
import 'package:labutica/screens/album.dart';
import 'package:labutica/screens/all_games.dart';
import 'package:labutica/screens/child.dart';
import 'package:labutica/screens/parent.dart';
import 'package:labutica/screens/stickers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpScreen(WidgetTester tester, Widget w) async {
  tester.view.physicalSize = const Size(2400, 1080);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: w)));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('разворот зверят показывает силуэты, а вкладки только текст', (
    t,
  ) async {
    await pumpScreen(
      t,
      AlbumScreen(
        stickers: const {},
        onPlace: (_) => fail('Силуэты нельзя приклеить'),
        onHome: () {},
      ),
    );
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Силуэт: ')), findsNWidgets(13));
    expect(find.byType(FilledButton), findsNWidgets(6));
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(find.text('Приклеенные'), findsNothing);
    expect(find.text('Можно приклеить'), findsNothing);
    for (final (label, count) in [
      ('Игрушки', 12),
      ('Овощи и фрукты', 8),
      ('Счёт', 4),
      ('Цвета и формы', 4),
      ('День и ночь', 4),
    ]) {
      await t.tap(find.text(label));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'^Силуэт: ')), findsNWidgets(count));
      if (label == 'Счёт') {
        for (var number = 1; number <= 4; number++) {
          expect(find.text('$number'), findsOneWidget);
        }
        expect(find.bySemanticsLabel('Силуэт: Одна ракушка'), findsOneWidget);
      }
    }
  });

  test('старые награды сохраняют количество при переходе на наклейки', () {
    final restored = decodeStickers({
      'mama': [2, 1],
      'puzzle': [9, 6],
      'animal:cat': [1, 0],
    });
    expect(restored.keys.every(stickerCatalog.containsKey), isTrue);
    expect(restored.values.fold(0, (sum, count) => sum + count.ready), 12);
    expect(restored.values.fold(0, (sum, count) => sum + count.placed), 7);
  });

  testWidgets('игра выдаёт одну наклейку и обе кнопки открывают один альбом', (
    t,
  ) async {
    const audioChannel = MethodChannel('labutica/task_audio');
    final messenger = t.binding.defaultBinaryMessenger;
    final sounds = <String>[];
    messenger.setMockMethodCallHandler(audioChannel, (call) async {
      sounds.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(audioChannel, null));
    SharedPreferences.setMockInitialValues({
      'lb-kit': '{"age":"4","scr":"home"}',
    });
    final prefs = await SharedPreferences.getInstance();
    await pumpScreen(t, LabuticaApp(prefs: prefs));
    await t.pumpAndSettle();

    Future<void> start() async {
      await t.tap(find.bySemanticsLabel('Пазлы'));
      await t.pumpAndSettle();
    }

    Future<Sticker> finish() async {
      final args = t.widget<GameShell>(find.byType(GameShell)).args;
      args.onDone(3);
      args.onDone(3);
      await t.pumpAndSettle();
      final reward = t.widget<Reward>(find.byType(Reward)).sticker!;
      expect(find.text('Твоя наклейка — ${reward.name}'), findsOneWidget);
      return reward;
    }

    await start();
    expect(prefs.getString('lb-stickers'), isNull);
    final first = await finish();
    expect(sounds, ['playStickerReward']);
    final ready = find.bySemanticsLabel(
      'Приклеить: ${first.name}, доступно: 1',
    );

    await t.tap(find.text('Открыть альбом'));
    await t.pumpAndSettle();
    expect(ready, findsOneWidget);
    await t.tap(find.bySemanticsLabel('Домой'));
    await t.pumpAndSettle();

    await t.tap(find.byTooltip('Альбом Ума лапки'));
    await t.pumpAndSettle();
    expect(ready, findsOneWidget);
    await t.tap(ready);
    await t.pumpAndSettle();
    expect(
      find.bySemanticsLabel('${first.name}, приклеено: 1'),
      findsOneWidget,
    );
    await t.tap(find.bySemanticsLabel('Домой'));
    await t.pumpAndSettle();

    await start();
    final second = await finish();
    expect(sounds, ['playStickerReward', 'playStickerReward']);
    expect(second.id, isNot(first.id));
  });

  testWidgets('онбординг передаёт выбранный возраст', (t) async {
    String? age;
    await pumpScreen(
      t,
      Onboarding(initial: '4', onDone: (value) => age = value),
    );
    expect(find.bySemanticsLabel('Выбери свой возраст'), findsOneWidget);
    final artboard = t.getSize(
      find.byKey(const ValueKey('landscape-artboard')),
    );
    expect(artboard.aspectRatio, closeTo(1870 / 841, .001));
    await t.pumpAndSettle();
    final mascot = find.bySemanticsLabel('Умолапка');
    final pose = find.descendant(
      of: mascot,
      matching: find.byType(IndexedStack),
    );
    final restingY = t.getCenter(pose).dy;
    expect(t.widget<IndexedStack>(pose).index, 0);
    await t.tap(mascot);
    await t.pump();
    await t.pump(const Duration(milliseconds: 380));
    expect(t.getCenter(pose).dy, lessThan(restingY));
    expect(t.widget<IndexedStack>(pose).index, 1);
    await t.tap(find.text('6+'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Начать'));
    expect(age, '6');
  });
  testWidgets('каталог открывает игру с полки', (t) async {
    String? opened;
    await pumpScreen(
      t,
      AllGamesScreen(
        age: '4',
        starCount: 0,
        onOpen: (id) => opened = id,
        onParent: () {},
        onExit: () {},
        onAlbum: () {},
      ),
    );
    final shelf = find.byType(AllGamesScreen);
    await t.tap(
      find.descendant(of: shelf, matching: find.bySemanticsLabel('Пазлы')),
    );
    await t.pumpAndSettle();
    expect(opened, 'puzzle');
  });

  testWidgets('домик возвращает на полку игр', (t) async {
    SharedPreferences.setMockInitialValues({
      'lb-kit': '{"age":"4","scr":"home"}',
    });
    final prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = const Size(2400, 1080);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    await t.pumpWidget(LabuticaApp(prefs: prefs));
    expect(find.byType(StartupIntro), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.byType(StartupIntro), findsNothing);

    expect(find.byType(AllGamesScreen), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Пазлы'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Домой'));
    await t.pumpAndSettle();

    expect(find.byType(AllGamesScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Пазлы'), findsOneWidget);
  });

  testWidgets(
    'одна наклейка за два раунда, приклеивание и повторное открытие альбома',
    (t) async {
      SharedPreferences.setMockInitialValues({
        'lb-kit': '{"age":"4","scr":"home"}',
      });
      final prefs = await SharedPreferences.getInstance();
      t.view.physicalSize = const Size(2400, 1080);
      t.view.devicePixelRatio = 2.625;
      addTearDown(t.view.reset);
      await t.pumpWidget(LabuticaApp(prefs: prefs));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Почини мостик'));
      await t.pumpAndSettle();

      final board = find.byKey(const ValueKey('bridge-long'));
      final gap = find.byKey(const ValueKey('bridge-gap'));
      Future<void> solve() async {
        await t.drag(board, t.getCenter(gap) - t.getCenter(board));
        await t.pump();
      }

      await solve();
      expect(prefs.getString('lb-stickers'), isNull);
      await t.pump(const Duration(milliseconds: 1700));
      await solve();
      await t.pump(const Duration(milliseconds: 1700));
      await t.pumpAndSettle();
      final sticker = t.widget<Reward>(find.byType(Reward)).sticker!;
      expect(jsonDecode(prefs.getString('lb-stickers')!), {
        sticker.id: [1, 0],
      });

      await t.tap(find.text('Открыть альбом'));
      await t.pumpAndSettle();
      await t.tap(
        find.bySemanticsLabel('Приклеить: ${sticker.name}, доступно: 1'),
      );
      await t.pumpAndSettle();
      expect(jsonDecode(prefs.getString('lb-stickers')!), {
        sticker.id: [0, 1],
      });

      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(LabuticaApp(prefs: prefs));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Альбом Ума лапки'));
      await t.pumpAndSettle();
      final page = stickerPages.firstWhere(
        (page) => [...page.$3, ...page.$4].contains(sticker),
      );
      await t.tap(find.text(page.$1));
      await t.pumpAndSettle();
      expect(
        find.bySemanticsLabel('${sticker.name}, приклеено: 1'),
        findsOneWidget,
      );
    },
  );

  for (final age in ['3', '4', '5', '6']) {
    testWidgets('чему учимся $age+', (t) async {
      await pumpScreen(
        t,
        AllGamesScreen(
          age: age,
          starCount: 0,
          onOpen: (_) {},
          onParent: () {},
          onExit: () {},
          onAlbum: () {},
        ),
      );
      await t.tap(find.byTooltip('Чему учимся в этом возрасте'));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Чему учимся в $age+'), findsOneWidget);
    });
  }
  testWidgets(
    'награда',
    (t) => pumpScreen(t, Reward(stars: 2, onHome: () {}, onReplay: () {})),
  );
  testWidgets(
    'родители',
    (t) =>
        pumpScreen(t, ParentHome(age: '3', onBack: () {}, onSettings: () {})),
  );
  testWidgets('настройки и тост', (t) async {
    await pumpScreen(t, ParentSettings(onBack: () {}, onChangeAge: () {}));
    await t.tap(find.text('Сохранить'));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('20 минут'));
    await t.pump(const Duration(seconds: 3));
  });
  testWidgets('родительский замок', (t) async {
    await pumpScreen(
      t,
      Builder(
        builder: (ctx) =>
            Center(child: LbButton('open', onTap: () => showParentGate(ctx))),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(ParentGate), findsOneWidget);
  });
}
