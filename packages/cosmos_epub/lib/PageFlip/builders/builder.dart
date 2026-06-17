import 'dart:ui' as ui;

import 'package:cosmos_epub/PageFlip/effects/flip_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Map<int, ui.Image?> imageData = {};
ValueNotifier<int> currentPage = ValueNotifier(-1);
ValueNotifier<Widget> currentWidget = ValueNotifier(Container());
ValueNotifier<int> currentPageIndex = ValueNotifier(0);

class PageFlipBuilder extends StatefulWidget {
  const PageFlipBuilder({
    Key? key,
    required this.amount,
    this.backgroundColor,
    required this.child,
    required this.pageIndex,
    required this.isRightSwipe,
  }) : super(key: key);

  final Animation<double> amount;
  final int pageIndex;
  final Color? backgroundColor;
  final Widget child;
  final bool isRightSwipe;

  @override
  State<PageFlipBuilder> createState() => PageFlipBuilderState();
}

class PageFlipBuilderState extends State<PageFlipBuilder> {
  final _boundaryKey = GlobalKey();

  void _captureImage(Duration timeStamp, int index) async {
    if (_boundaryKey.currentContext == null) return;
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      if (mounted) {
        final boundary = _boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage();
        setState(() {
          imageData[index] = image.clone();
        });
      }
    } catch (e) {
      print('Ignore this error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentPage,
      builder: (context, value, child) {
        if (imageData[widget.pageIndex] != null && value >= 0) {
          return CustomPaint(
            painter: PageFlipEffect(
              amount: widget.amount,
              image: imageData[widget.pageIndex]!,
              backgroundColor: widget.backgroundColor,
              isRightSwipe: widget.isRightSwipe,
            ),
            size: Size.infinite,
          );
        } else {
          if (value == widget.pageIndex || (value == (widget.pageIndex + 1))) {
            WidgetsBinding.instance.addPostFrameCallback(
              (timeStamp) => _captureImage(timeStamp, currentPageIndex.value),
            );
          }
          if (widget.pageIndex == currentPageIndex.value ||
              (widget.pageIndex == (currentPageIndex.value + 1))) {
            return ColoredBox(
              color: widget.backgroundColor ?? Colors.black12,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: widget.child,
              ),
            );
          } else {
            return Container();
          }
        }
      },
    );
  }
}
