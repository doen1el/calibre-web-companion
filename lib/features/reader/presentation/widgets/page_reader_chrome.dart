import 'package:flutter/material.dart';

class PageReaderChrome extends StatelessWidget {
  final String title;
  final int page;
  final int pageCount;
  final bool visible;
  final ValueChanged<int> onSeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleChrome;
  final List<Widget> actions;
  final bool reverseTapZones;
  final Widget child;

  const PageReaderChrome({
    super.key,
    required this.title,
    required this.page,
    required this.pageCount,
    required this.visible,
    required this.onSeek,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleChrome,
    required this.child,
    this.actions = const [],
    this.reverseTapZones = false,
  });

  void _onTapUp(BuildContext context, TapUpDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    final dx = details.globalPosition.dx;
    if (dx < width / 3) {
      reverseTapZones ? onNext() : onPrevious();
    } else if (dx > width * 2 / 3) {
      reverseTapZones ? onPrevious() : onNext();
    } else {
      onToggleChrome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = theme.colorScheme.surface.withValues(alpha: .94);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _onTapUp(context, details),
              child: child,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            top: visible ? 0 : -120,
            left: 0,
            right: 0,
            child: Material(
              color: barColor,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            bottom: visible ? 0 : -140,
            left: 0,
            right: 0,
            child: Material(
              color: barColor,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            pageCount > 1
                                ? Directionality(
                                  textDirection:
                                      reverseTapZones
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                  child: Slider(
                                    value:
                                        page.clamp(0, pageCount - 1).toDouble(),
                                    max: (pageCount - 1).toDouble(),
                                    divisions: pageCount - 1,
                                    label: '${page + 1}',
                                    onChanged: (value) => onSeek(value.round()),
                                  ),
                                )
                                : const SizedBox(height: 48),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pageCount > 0 ? '${page + 1} / $pageCount' : '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
