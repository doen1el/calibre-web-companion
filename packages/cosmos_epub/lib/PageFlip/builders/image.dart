import 'package:cosmos_epub/PageFlip/effects/flip_effect.dart';
import 'package:flutter/material.dart';

class PageFlipImage extends StatefulWidget {
  const PageFlipImage({
    Key? key,
    required this.amount,
    this.image,
    this.backgroundColor = const Color(0xFFFFFFCC),
    this.isRightSwipe = false,
  }) : super(key: key);

  final Animation<double> amount;
  final ImageProvider? image;
  final Color? backgroundColor;
  final bool isRightSwipe;

  @override
  State<PageFlipImage> createState() => _PageFlipImageState();
}

class _PageFlipImageState extends State<PageFlipImage> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  bool _isListeningToStream = false;

  late ImageStreamListener _imageListener;

  @override
  void initState() {
    super.initState();
    _imageListener = ImageStreamListener(_handleImageFrame);
  }

  @override
  void dispose() {
    _stopListeningToStream();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    if (TickerMode.of(context)) {
      _listenToStream();
    } else {
      _stopListeningToStream();
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(PageFlipImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _resolveImage();
    }
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    final ImageStream newStream =
        widget.image!.resolve(createLocalImageConfiguration(context));
    _updateSourceStream(newStream);
  }

  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    setState(() => _imageInfo = imageInfo);
  }

  // Updates _imageStream to newStream, and moves the stream listener
  // registration from the old stream to the new stream (if a listener was
  // registered).
  void _updateSourceStream(ImageStream newStream) {
    if (_imageStream?.key == newStream.key) return;

    if (_isListeningToStream) _imageStream?.removeListener(_imageListener);

    _imageStream = newStream;
    if (_isListeningToStream) _imageStream?.addListener(_imageListener);
  }

  void _listenToStream() {
    if (_isListeningToStream) return;
    _imageStream?.addListener(_imageListener);
    _isListeningToStream = true;
  }

  void _stopListeningToStream() {
    if (!_isListeningToStream) return;
    _imageStream?.removeListener(_imageListener);
    _isListeningToStream = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_imageInfo != null) {
      return CustomPaint(
        painter: PageFlipEffect(
          amount: widget.amount,
          image: _imageInfo!.image,
          backgroundColor: widget.backgroundColor,
          isRightSwipe: widget.isRightSwipe,
        ),
        size: Size.infinite,
      );
    } else {
      return const SizedBox();
    }
  }
}
