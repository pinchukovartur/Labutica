// Лабитики — Android-приложение по прототипу ui_kits/android-app (Claude Design).
// Поток: онбординг (возраст) → главная → игра → награда; замок → родительский вход → дашборд → настройки.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ds/game_audio.dart';
import 'ds/tokens.dart';
import 'games/kit.dart';
import 'games/registry.dart';
import 'screens/album.dart';
import 'screens/all_games.dart';
import 'screens/child.dart';
import 'screens/parent.dart';
import 'screens/stickers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Игра в горизонтальной ориентации, на весь экран (системные панели — по свайпу от края).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  runApp(LabuticaApp(prefs: prefs));
}

class LabuticaApp extends StatelessWidget {
  const LabuticaApp({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: appName,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      scaffoldBackgroundColor: C.paper,
      fontFamily: Fonts.body,
      colorScheme: ColorScheme.fromSeed(
        seedColor: C.slime500,
        surface: C.paper,
      ),
    ),
    home: AppShell(prefs: prefs),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Те же ключи, что и localStorage в прототипе: lb-kit и lb-stars.
  late final Map<String, dynamic> _saved = _read('lb-kit');
  late String? age = _saved['age'] as String?;
  late String scr = age != null
      ? (_saved['scr'] as String? ?? 'home')
      : 'onboarding';
  late String game = games.containsKey(_saved['game'])
      ? _saved['game'] as String
      : 'shapes';
  late Map<String, int> stars = _read(
    'lb-stars',
  ).map((k, v) => MapEntry(k, (v as num).toInt()));
  late final _stickers = decodeStickers(_read('lb-stickers'));
  final _random = Random();
  Sticker? _rewardSticker;
  String? _albumSticker;
  int lastStars = 3;
  int key = 0;
  bool _showIntro = true;

  Map<String, dynamic> _read(String k) {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(widget.prefs.getString(k) ?? '{}') as Map,
      );
    } catch (_) {
      return {};
    }
  }

  void go(String s) {
    setState(() => scr = s);
    widget.prefs.setString(
      'lb-kit',
      jsonEncode({
        'age': age,
        'scr': s == 'reward' || s == 'game' || s == 'album' ? 'home' : s,
        'game': game,
      }),
    );
  }

  void _saveStickers() {
    widget.prefs.setString(
      'lb-stickers',
      jsonEncode({
        for (final MapEntry(key: id, value: counts) in _stickers.entries)
          id: [counts.ready, counts.placed],
      }),
    );
  }

  Sticker _earnSticker() {
    final missing = stickerCatalog.values
        .where((sticker) => !_stickers.containsKey(sticker.id))
        .toList();
    final candidates = missing.isEmpty
        ? stickerCatalog.values.toList()
        : missing;
    final sticker = candidates[_random.nextInt(candidates.length)];
    final counts = _stickers[sticker.id] ?? (ready: 0, placed: 0);
    _stickers[sticker.id] = (ready: counts.ready + 1, placed: counts.placed);
    _saveStickers();
    return sticker;
  }

  void _placeSticker(String id) {
    final counts = _stickers[id];
    if (counts == null || counts.ready == 0) return;
    setState(
      () =>
          _stickers[id] = (ready: counts.ready - 1, placed: counts.placed + 1),
    );
    _saveStickers();
  }

  void _startGame(String id) {
    game = id;
    key++;
    _rewardSticker = null;
    go('game');
  }

  void _openAlbum({String? latestSticker}) {
    _albumSticker = latestSticker;
    go('album');
  }

  void done(int s) {
    lastStars = s;
    _rewardSticker = _earnSticker();
    stars = {...stars, game: (stars[game] ?? 0) > s ? stars[game]! : s};
    widget.prefs.setString('lb-stars', jsonEncode(stars));
    go('reward');
    unawaited(playGameSound(GameSound.stickerReward));
  }

  Future<void> openParent() async {
    if (await showParentGate(context)) go('parent');
  }

  /// Системная «Назад»: на шаг вверх по потоку; с главной и онбординга — выход.
  String? get _backTarget => switch (scr) {
    'game' || 'reward' || 'parent' || 'album' => 'home',
    'settings' => 'parent',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final a = age ?? '3';
    final run = key;
    final background = switch (scr) {
      'game' => games[game]!.bg,
      _ => null,
    };
    final Widget body = switch (scr) {
      'onboarding' => Onboarding(
        initial: age,
        onDone: (v) {
          age = v;
          go('home');
        },
      ),
      'game' => KeyedSubtree(
        key: ValueKey('game-$key'),
        child: games[game]!.build(
          GameArgs(
            def: games[game]!,
            age: int.tryParse(a) ?? 3,
            onHome: () => go('home'),
            onDone: (result) {
              if (scr == 'game' && key == run) done(result);
            },
          ),
        ),
      ),
      'reward' => Reward(
        stars: lastStars,
        onHome: () => go('home'),
        onReplay: () => _startGame(game),
        sticker: _rewardSticker,
        onAlbum: () => _openAlbum(latestSticker: _rewardSticker?.id),
      ),
      'album' => AlbumScreen(
        stickers: _stickers,
        latestSticker: _albumSticker,
        onPlace: _placeSticker,
        onHome: () => go('home'),
      ),
      'parent' => ParentHome(
        age: a,
        onBack: () => go('home'),
        onSettings: () => go('settings'),
      ),
      'settings' => ParentSettings(
        onBack: () => go('parent'),
        onChangeAge: () => go('onboarding'),
      ),
      _ => AllGamesScreen(
        age: a,
        starCount: stars.values.fold<int>(0, (sum, value) => sum + value),
        onOpen: _startGame,
        onAlbum: _openAlbum,
        readyStickers: _stickers.values.fold<int>(
          0,
          (sum, item) => sum + item.ready,
        ),
        onParent: openParent,
        onExit: () => go('onboarding'),
      ),
    };
    final edgeToEdge =
        {'onboarding', 'home', 'album'}.contains(scr) ||
        (scr == 'game' && game == 'bridge');
    return PopScope(
      canPop: _backTarget == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _backTarget != null) go(_backTarget!);
      },
      child: Scaffold(
        backgroundColor: switch (scr) {
          'reward' => C.slime100,
          'album' => const Color(0xFF526A2E),
          'onboarding' => C.wingYellow,
          _ => C.paper,
        },
        body: Stack(
          children: [
            if (background != null)
              Positioned.fill(
                child: Image.asset(
                  'assets/$background',
                  fit: BoxFit.cover,
                  alignment: scr == 'game'
                      ? games[game]!.bgAlign
                      : Alignment.center,
                  excludeFromSemantics: true,
                ),
              ),
            SafeArea(
              left: !edgeToEdge,
              right: !edgeToEdge,
              top: !edgeToEdge,
              bottom: !edgeToEdge,
              child: ExcludeSemantics(
                excluding: _showIntro,
                child: AnimatedSwitcher(
                  duration: Dur.med,
                  child: KeyedSubtree(key: ValueKey('$scr-$key'), child: body),
                ),
              ),
            ),
            if (_showIntro)
              Positioned.fill(
                child: StartupIntro(
                  onDone: () => setState(() => _showIntro = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
