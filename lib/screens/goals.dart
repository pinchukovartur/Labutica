// Окно «Чему учимся»: цели выбранного возраста по ФОП ДО — цвета, формы, счёт и т. д.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/tokens.dart';

typedef Goal = (String title, String tone, IconData icon, String text);

const ageGoals = <String, (String, List<Goal>)>{
  '3': (
    'Вторая младшая группа · 3–4 года',
    [
      ('Цвета', 'bubble', LucideIcons.palette, 'Узнаёт и называет красный, жёлтый, зелёный и синий, а ещё белый и чёрный. Подбирает предметы одного цвета.'),
      ('Формы и величина', 'flask', LucideIcons.shapes, 'Круг, квадрат, треугольник. Сравнивает предметы: большой и маленький, длинный и короткий.'),
      ('Счёт', 'spark', LucideIcons.hash, 'Один и много, поровну. Сравнивает две группы предметов, прикладывая их друг к другу.'),
      ('Где что находится', 'slime', LucideIcons.move, 'Вверху и внизу, впереди и сзади, справа и слева от себя.'),
      ('Время', 'spark', LucideIcons.sunMoon, 'День и ночь, утро и вечер.'),
      (
        'Животные',
        'spark',
        LucideIcons.pawPrint,
        'Узнаёт 6–\u20608 домашних животных и их детёнышей: кошка и котёнок, собака и щенок, корова и телёнок, лошадь и жеребёнок, свинья и поросёнок, коза и козлёнок, курица и цыплёнок, утка и утёнок. По картинкам знакомится с 4–\u20605 дикими: заяц, лиса, волк, медведь. Знает, кто как голос подаёт.',
      ),
      (
        'Растения',
        'slime',
        LucideIcons.sprout,
        'Различает дерево, траву и цветок. Узнаёт 4–\u20605 овощей (морковь, капуста, огурец, помидор, картофель) и 3–\u20604 фрукта (яблоко, груша, банан, апельсин). Знает, что овощи растут на грядке, а фрукты — на дереве. Замечает: снег, дождь, листья желтеют и падают.',
      ),
    ],
  ),
  '4': (
    'Средняя группа · 4–5 лет',
    [
      ('Цвета', 'bubble', LucideIcons.palette, 'К основным добавляются оранжевый, голубой, фиолетовый, коричневый, розовый и серый. Светлые и тёмные оттенки.'),
      ('Формы и величина', 'flask', LucideIcons.shapes, 'Прямоугольник и овал, шар, куб и цилиндр. Раскладывает 3–\u20605 предметов по длине, ширине или высоте.'),
      ('Счёт', 'spark', LucideIcons.hash, 'Считает до 5, отвечает «сколько?» и «который по счёту?». Больше или меньше на один, уравнивает группы.'),
      ('Где что находится', 'slime', LucideIcons.move, 'На, над, под, между. Двигается в заданном направлении.'),
      ('Время', 'spark', LucideIcons.sunMoon, 'Части суток по порядку. Вчера, сегодня, завтра.'),
      (
        'Животные',
        'spark',
        LucideIcons.pawPrint,
        'Дикие звери наших лесов: заяц, лиса, волк, медведь, белка, ёж — где живут (нора, берлога, дупло) и чем питаются. Чем домашние животные полезны человеку. Птицы: воробей, ворона, голубь, синица, снегирь. Насекомые: бабочка, жук, муравей, пчела.',
      ),
      (
        'Растения',
        'slime',
        LucideIcons.sprout,
        'Деревья: берёза, ель, дуб, клён, рябина — отличает по листьям и стволу. Цветы: ромашка, одуванчик, колокольчик. Садовые ягоды: малина, клубника, смородина. Делит на овощи, фрукты и ягоды. Приметы каждого времени года.',
      ),
    ],
  ),
  '5': (
    'Старшая группа · 5–6 лет',
    [
      ('Цвета', 'bubble', LucideIcons.palette, 'Различает оттенки, знает, какой цвет получится, если смешать две краски.'),
      ('Формы и величина', 'flask', LucideIcons.shapes, 'Ромб и другие четырёхугольники, многоугольники. Делит предмет на 2–\u20604 равные части.'),
      ('Счёт', 'spark', LucideIcons.hash, 'Считает до 10 вперёд и назад, знает цифры от 0 до 9, понимает, из каких единиц состоит число.'),
      ('Где что находится', 'slime', LucideIcons.move, 'Слева и справа от другого предмета, ориентируется на листе бумаги.'),
      ('Время', 'spark', LucideIcons.calendarDays, 'Дни недели по порядку, времена года, что было раньше и что позже.'),
      ('Логика', 'tomato', LucideIcons.lightbulb, 'Находит закономерность в ряду, группирует предметы по двум признакам.'),
      (
        'Животные',
        'spark',
        LucideIcons.pawPrint,
        'Животные жарких стран (слон, жираф, лев, зебра, обезьяна) и Севера (белый медведь, пингвин, морж, северный олень). Перелётные и зимующие птицы. Рыбы, лягушка, насекомые. Как звери готовятся к зиме: запасы, линька, спячка.',
      ),
      (
        'Растения',
        'slime',
        LucideIcons.sprout,
        'Хвойные и лиственные деревья, кустарники, комнатные растения. Лесные ягоды и грибы — какие съедобные, а какие ядовитые. Что нужно растению: свет, вода и тепло. Как хлеб приходит на стол: от зерна до батона.',
      ),
    ],
  ),
  '6': (
    'Подготовительная группа · 6–7 лет',
    [
      ('Счёт', 'spark', LucideIcons.hash, 'Состав чисел до 10 из двух меньших, сложение и вычитание в пределах 10, простые задачи. Знаки «+», «−», «=».'),
      ('Формы', 'flask', LucideIcons.shapes, 'Отрезок и многоугольники, составляет фигуры из частей. Делит целое на 2, 4 и 8 частей.'),
      ('Величина', 'bubble', LucideIcons.ruler, 'Измеряет длину, вес и объём условной меркой.'),
      ('Где что находится', 'slime', LucideIcons.move, 'Ориентируется на листе в клетку, по простому плану или схеме.'),
      ('Время', 'spark', LucideIcons.clock, 'Часы — целый час, календарь, месяцы и дни недели.'),
      ('Логика', 'tomato', LucideIcons.lightbulb, 'Сравнивает и обобщает, решает головоломки и лабиринты, объясняет свой ответ.'),
      (
        'Животные',
        'spark',
        LucideIcons.pawPrint,
        'Делит на группы: звери, птицы, рыбы, насекомые, земноводные. Кто чем питается и кто кого ест. Как животные приспособились к месту, где живут. Красная книга: каких животных нужно беречь.',
      ),
      (
        'Растения',
        'slime',
        LucideIcons.sprout,
        'Части растения: корень, стебель, лист, цветок, семя. Как из семечка вырастает растение. Лекарственные травы: подорожник, ромашка. Природные зоны: тундра, тайга, степь, пустыня — и что там растёт. Как беречь природу.',
      ),
    ],
  ),
};

Future<void> showAgeGoals(BuildContext context, String age) {
  final (group, goals) = ageGoals[age] ?? ageGoals['3']!;
  return showLbDialog<void>(
    context,
    title: 'Чему учимся в $age+',
    maxWidth: 680,
    body: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height - 170),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group, style: body(14, FontWeight.w800, C.wing500)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (_, c) {
                // Длинные описания (природа) — во всю ширину, короткие — в две колонки.
                final w = (c.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final g in goals)
                      SizedBox(
                        width: g.$4.length > 160 ? c.maxWidth : w,
                        child: _GoalCard(goal: g),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Ориентир — Федеральная образовательная программа дошкольного образования (ФОП ДО). Списки животных и растений — примеры, а не обязательный перечень.',
              style: body(12, FontWeight.w600, C.ink500),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final Goal goal;
  @override
  Widget build(BuildContext context) {
    final (title, tone, icon, text) = goal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.wingToneLight(tone), borderRadius: BorderRadius.circular(R.lg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: C.wingTone(tone),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.white, width: 2),
            ),
            child: Icon(icon, size: 18, color: C.wing),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: display(13, FontWeight.w700, C.wing, 1.2)),
                const SizedBox(height: 4),
                Text(text, style: body(13, FontWeight.w600, C.ink700, 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
