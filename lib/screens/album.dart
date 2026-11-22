import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ds/components.dart';
import '../ds/landscape_artwork.dart';
import '../ds/tokens.dart';
import 'stickers.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({
    super.key,
    required this.stickers,
    required this.onPlace,
    required this.onHome,
    this.latestSticker,
  });

  final Map<String, StickerCounts> stickers;
  final ValueChanged<String> onPlace;
  final VoidCallback onHome;
  final String? latestSticker;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late int _section = _initialSection();
  int _initialSection() {
    final latest = widget.latestSticker;
    final index = stickerPages.indexWhere(
      (page) => [...page.$3, ...page.$4].any((sticker) => sticker.id == latest),
    );
    if (index >= 0) return index;
    final pending = stickerPages.indexWhere(
      (page) => [
        ...page.$3,
        ...page.$4,
      ].any((sticker) => (widget.stickers[sticker.id]?.ready ?? 0) > 0),
    );
    return pending < 0 ? 0 : pending;
  }

  @override
  Widget build(BuildContext context) {
    final (_, _, left, right) = stickerPages[_section];
    return LandscapeArtwork(
      asset: 'assets/brand/sticker-album-wide.png',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 195,
            top: 22,
            child: LbIconButton(
              LucideIcons.house,
              extent: 100,
              label: 'Домой',
              onTap: widget.onHome,
            ),
          ),
          Positioned(
            left: 650,
            right: 500,
            top: 14,
            height: 90,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5B4),
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(58),
              ),
              child: Center(
                child: Text(
                  'Альбом Умо',
                  style: body(66, FontWeight.w900, const Color(0xFF663315)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 430,
            right: 220,
            top: 125,
            height: 75,
            child: Row(
              children: [
                for (final (index, tab) in stickerPages.indexed)
                  Expanded(
                    flex: index == 2 || index == 4 ? 4 : 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Semantics(
                        selected: index == _section,
                        child: FilledButton(
                          onPressed: () => setState(() {
                            _section = index;
                          }),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 70),
                            backgroundColor: tab.$2,
                            foregroundColor: const Color(0xFF663315),
                            side: BorderSide(
                              color: Colors.white,
                              width: index == _section ? 6 : 2,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: body(27, FontWeight.w900),
                          ),
                          child: Text(tab.$1, textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final (index, page) in [left, right].indexed)
            Positioned(
              left: index == 0 ? 455 : 1080,
              top: 255,
              width: index == 0 ? 530 : 520,
              height: 435,
              child: _StickerPage(
                entries: page,
                columns: page.length >= 6 ? 3 : 2,
                stickers: widget.stickers,
                onPlace: widget.onPlace,
              ),
            ),
        ],
      ),
    );
  }
}

class _StickerPage extends StatelessWidget {
  const _StickerPage({
    required this.entries,
    required this.columns,
    required this.stickers,
    required this.onPlace,
  });

  final List<Sticker> entries;
  final int columns;
  final Map<String, StickerCounts> stickers;
  final ValueChanged<String> onPlace;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var offset = 0; offset < entries.length; offset += columns)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final sticker in entries.skip(offset).take(columns))
                Expanded(
                  child: _StickerSlot(
                    sticker: sticker,
                    counts: stickers[sticker.id] ?? (placed: 0, ready: 0),
                    onPlace: () => onPlace(sticker.id),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

class _StickerSlot extends StatelessWidget {
  const _StickerSlot({
    required this.sticker,
    required this.counts,
    required this.onPlace,
  });

  final Sticker sticker;
  final StickerCounts counts;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    final ready = counts.ready > 0;
    final collected = counts.placed > 0;
    Widget art = StickerArt(sticker);
    if (!ready && !collected) {
      art = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFBD936C), BlendMode.srcIn),
        child: art,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Semantics(
        label: ready
            ? 'Приклеить: ${sticker.name}, доступно: ${counts.ready}'
            : collected
            ? '${sticker.name}, приклеено: ${counts.placed}'
            : 'Силуэт: ${sticker.name}',
        image: true,
        button: ready,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: ready ? onPlace : null,
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: sticker.number == null
                      ? art
                      : Center(
                          child: SizedBox(
                            height: 237,
                            child: Column(
                              children: [
                                Expanded(child: art),
                                ExcludeSemantics(
                                  child: Text(
                                    '${sticker.number}',
                                    style: body(
                                      54,
                                      FontWeight.w900,
                                      const Color(0xFF663315),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                if (ready)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD45F),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 12,
                          ),
                          child: counts.ready == 1
                              ? const Icon(
                                  LucideIcons.plus,
                                  size: 26,
                                  color: Color(0xFF663315),
                                )
                              : Text(
                                  '×${counts.ready}',
                                  style: body(24, FontWeight.w900),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
