// parent.jsx — родительский вход, дашборд и настройки.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/tokens.dart';

/// Родительский замок: «Нажмите 7, затем 4». Возвращает true, если код введён.
Future<bool> showParentGate(BuildContext context) async {
  final ok = await showLbDialog<bool>(
    context,
    title: 'Для взрослых',
    maxWidth: 600,
    body: (ctx) => ParentGate(digits: const ['7', '4'], prompt: 'Нажмите 7, затем 4', onPass: () => Navigator.of(ctx).pop(true)),
  );
  return ok ?? false;
}

const _lines = [('M', 'Математика', 4, 10, 'flask'), ('C', 'Цвета', 1, 1, 'bubble'), ('N', 'Природа', 2, 6, 'slime'), ('S', 'Общество', 1, 7, 'spark'), ('R', 'Речь', 0, 3, 'tomato')];
const _weak = [('M-3.2', 'Больше, меньше, поровну', 'путается, когда предметов больше пяти'), ('N-3.5', 'Животные и детёныши', '3 ошибки в «Мама и малыш»')];

class ParentHome extends StatefulWidget {
  const ParentHome({super.key, required this.age, required this.onBack, required this.onSettings});
  final String age;
  final VoidCallback onBack, onSettings;
  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  late String tab = widget.age;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: C.paper,
    child: Column(
      children: [
        LbAppBar(
          title: 'Для родителей',
          onBack: widget.onBack,
          actions: [LbIconButton(LucideIcons.settings, size: 'sm', label: 'Настройки', onTap: widget.onSettings)],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(120, 4, 120, 24),
            children: [
              LbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Сегодня', style: display(16))),
                        Tag('${widget.age}+', tone: 'slime'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ProgressBar(label: Text('Время игры'), value: 12, max: 20, tone: 'spark', showValue: true),
                    const SizedBox(height: 8),
                    Text('минут из дневного лимита · 6 партий', style: body(13, FontWeight.w600, C.ink500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LbTabs(value: tab, onChange: (v) => setState(() => tab = v), tabs: const [('3', '3+'), ('4', '4+'), ('5', '5+'), ('6', '6+')]),
              const SizedBox(height: 16),
              LbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Темы программы', style: display(16)),
                    const SizedBox(height: 14),
                    for (final (i, l) in _lines.indexed) ...[
                      if (i > 0) const SizedBox(height: 14),
                      ProgressBar(
                        label: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${l.$1}  ', style: mono(13, FontWeight.w700, C.ink500)),
                              TextSpan(text: l.$2),
                            ],
                          ),
                        ),
                        value: tab == widget.age ? l.$3 : 0,
                        max: l.$4,
                        tone: l.$5,
                        showValue: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Где ошибается', style: display(16)),
                    const SizedBox(height: 6),
                    for (final (i, w) in _weak.indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: i > 0 ? const Border(top: BorderSide(color: C.ink100, width: 2)) : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tag(w.$1, tone: 'tomato', mono: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.$2, style: body(14, FontWeight.w800)),
                                  Text(w.$3, style: body(13, FontWeight.w600, C.ink700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LbButton('Вернуться к играм', variant: 'secondary', block: true, icon: LucideIcons.play, onTap: widget.onBack),
            ],
          ),
        ),
      ],
    ),
  );
}

class ParentSettings extends StatefulWidget {
  const ParentSettings({super.key, required this.onBack, required this.onChangeAge});
  final VoidCallback onBack, onChangeAge;
  @override
  State<ParentSettings> createState() => _ParentSettingsState();
}

class _ParentSettingsState extends State<ParentSettings> {
  String limit = '20 минут', voice = 'live';
  bool music = true, vibe = false, hint = true, saved = false;
  int _saveId = 0;

  void save() {
    final id = ++_saveId;
    setState(() => saved = true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && id == _saveId) setState(() => saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = display(15);
    return ColoredBox(
      color: C.paper,
      child: Stack(
        children: [
          Column(
            children: [
              LbAppBar(title: 'Настройки', onBack: widget.onBack),
              Expanded(
                // Горизонтально: две колонки, всё видно без прокрутки.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            LbCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Время', style: h),
                                  const SizedBox(height: 6),
                                  LbSelect(
                                    label: 'Лимит в день',
                                    value: limit,
                                    onChange: (v) => setState(() => limit = v),
                                    options: const ['15 минут', '20 минут', '30 минут', 'Без лимита'],
                                    hint: 'По окончании игра мягко завершится',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            LbCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Озвучка', style: h),
                                  const SizedBox(height: 6),
                                  LbRadio(label: 'Живой голос', checked: voice == 'live', onChange: () => setState(() => voice = 'live')),
                                  LbRadio(label: 'Синтез речи', checked: voice == 'tts', onChange: () => setState(() => voice = 'tts')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            LbCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Игра', style: h),
                                  const SizedBox(height: 6),
                                  LbSwitch(checked: music, onChange: (v) => setState(() => music = v), label: 'Фоновая музыка'),
                                  LbSwitch(checked: vibe, onChange: (v) => setState(() => vibe = v), label: 'Вибрация'),
                                  LbCheckbox(checked: hint, onChange: (v) => setState(() => hint = v), label: 'Подсказка после 2 ошибок'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            LbButton('Сохранить', block: true, onTap: save),
                            const SizedBox(height: 10),
                            LbButton('Сменить возраст', variant: 'ghost', block: true, icon: LucideIcons.baby, onTap: widget.onChangeAge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (saved)
            Positioned(
              left: 220,
              right: 220,
              bottom: 20,
              child: LbToast(title: 'Сохранено', message: 'Лимит: $limit в день'),
            ),
        ],
      ),
    );
  }
}
