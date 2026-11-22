// Токены дизайн-системы «Лабитики» (tokens/*.css из Claude Design).
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

const appName = 'Умолапка — развивайка';

class C {
  static const gamePanel = Color(0xE0FFF8E2);
  static const slime100 = Color(0xFFE8F8CF), slime300 = Color(0xFFB6E86A), slime500 = Color(0xFF7CC62A), slime700 = Color(0xFF4A8512);
  static const flask100 = Color(0xFFD4F3F2), flask300 = Color(0xFF71D6D8), flask500 = Color(0xFF1CA9B3), flask700 = Color(0xFF0C6B74);
  static const spark100 = Color(0xFFFFF2CC), spark300 = Color(0xFFFFD75E), spark500 = Color(0xFFFFAD1F), spark700 = Color(0xFFB86A00);
  static const bubble100 = Color(0xFFFFE2EE), bubble300 = Color(0xFFFF9FC5), bubble500 = Color(0xFFF25891), bubble700 = Color(0xFFA3275A);
  static const tomato100 = Color(0xFFFFE2DB), tomato300 = Color(0xFFFF9A86), tomato500 = Color(0xFFF0573F), tomato700 = Color(0xFFA72A17);
  static const ink900 = Color(0xFF22183A), ink700 = Color(0xFF4A3F63), ink500 = Color(0xFF7A7191), ink300 = Color(0xFFB8B1C8), ink200 = Color(0xFFDCD6E6), ink100 = Color(0xFFEFEBF4);
  static const paper = Color(0xFFFFF8EC), paper2 = Color(0xFFF6EBD6), white = Color(0xFFFFFFFF);
  static const scrim = Color(0x8C22183A);
  // Палитра бабочки-птицекрылки (только сама бабочка, без неба): жёлтое поле крыльев — фон,
  // красная грудка, голубовато-мятные и зелёные пятна — элементы, чёрное крыло — контур и текст.
  static const wing = Color(0xFF091B21), wing500 = Color(0xFF5E5A2E);
  static const wingYellow = Color(0xFFFCE57A), wingYellow2 = Color(0xFFF1D45E);
  static const lime = Color(0xFFB9CF52), aqua = Color(0xFFA6DCD0), ember = Color(0xFFF05B29), coral = Color(0xFFF58A62), amber = Color(0xFFF2A93B);
  static const lemon = Color(0xFFFDEC7D);

  /// Тон темы → цвет бабочки.
  static Color wingTone(String t) => switch (t) {
    'slime' => lime,
    'flask' => aqua,
    'spark' => amber,
    'bubble' => coral,
    _ => ember,
  };

  /// Тёмный оттенок тона — бейджи и подписи на светлом.
  static Color wingToneDark(String t) => switch (t) {
    'slime' => const Color(0xFF56680F),
    'flask' => const Color(0xFF276F61),
    'spark' => const Color(0xFF94560A),
    'bubble' => const Color(0xFFA3401C),
    _ => const Color(0xFF9E2B0B),
  };

  /// Светлый оттенок тона — подложка выбранной строки.
  static Color wingToneLight(String t) => switch (t) {
    'slime' => const Color(0xFFECF2C2),
    'flask' => const Color(0xFFDEF3EE),
    'spark' => const Color(0xFFFCE3B6),
    'bubble' => const Color(0xFFFDDDCF),
    _ => const Color(0xFFFCD3C2),
  };
  static const road = Color(0xFFFFF8DA), pollenDot = Color(0xFFE2BE45), shadow = Color(0x477A5A00), sun = Color(0xFFFFF2AE), dusk = Color(0xFFF6D65C);
  static const paintRed = Color(0xFFE8463A), paintBlue = Color(0xFF2F6FE0), paintYellow = Color(0xFFFFD23F), paintGreen = Color(0xFF3DB24B);

  static const _tones = {
    'slime': [slime100, slime300, slime500, slime700],
    'flask': [flask100, flask300, flask500, flask700],
    'spark': [spark100, spark300, spark500, spark700],
    'bubble': [bubble100, bubble300, bubble500, bubble700],
    'tomato': [tomato100, tomato300, tomato500, tomato700],
  };

  /// `var(--tone-step)`, step = 100/300/500/700.
  static Color tone(String t, int step) => _tones[t]![const {100: 0, 300: 1, 500: 2, 700: 3}[step]!];

  /// .lb-tone-* — фон кнопок и плиток.
  static Color fill(String t) => switch (t) {
    'primary' => slime500,
    'secondary' || 'white' => white,
    'accent' => spark300,
    'parent' => flask300,
    'danger' => tomato500,
    'paper' => paper2,
    _ => tone(t, 300),
  };
}

class R {
  static const sm = 10.0, md = 14.0, lg = 20.0, xl = 28.0;
}

class Fonts {
  static const display = 'Unbounded', body = 'Nunito', mono = 'JetBrainsMono';
}

TextStyle display(double size, [FontWeight w = FontWeight.w700, Color color = C.ink900, double? height]) =>
    TextStyle(fontFamily: Fonts.display, fontSize: size, fontWeight: w, color: color, height: height, letterSpacing: -0.01 * size);
TextStyle body(double size, [FontWeight w = FontWeight.w600, Color color = C.ink900, double? height]) => TextStyle(fontFamily: Fonts.body, fontSize: size, fontWeight: w, color: color, height: height);
TextStyle mono(double size, [FontWeight w = FontWeight.w700, Color color = C.ink900]) => TextStyle(fontFamily: Fonts.mono, fontSize: size, fontWeight: w, color: color);

BoxShadow lip(double dy, [Color c = C.ink900]) => BoxShadow(color: c, offset: Offset(0, dy));
BoxShadow ring(double spread, Color c) => BoxShadow(color: c, spreadRadius: spread);

class Ease {
  static const out = Cubic(.22, 1, .36, 1);
  static const bounce = Cubic(.34, 1.56, .64, 1);
  static const ret = Cubic(.5, 1.6, .5, 1);
}

class Dur {
  static const fast = Duration(milliseconds: 90), med = Duration(milliseconds: 180), slow = Duration(milliseconds: 320), ret = Duration(milliseconds: 450);
}
