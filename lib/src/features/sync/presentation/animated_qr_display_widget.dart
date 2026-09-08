import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../domain/animated_qr_codec.dart';

/// Interactive visual cycler for Animated Multi-Frame QR streaming.
///
/// Displays sequenced, cycling QR frames on-screen with play/pause and
/// next/previous navigation controls, enabling camera scanners to capture
/// complete patient datasets without network connectivity.
class AnimatedQrDisplayWidget extends StatefulWidget {
  final List<AnimatedQrFrame> frames;
  final int intervalMs;
  final bool autoPlay;

  const AnimatedQrDisplayWidget({
    super.key,
    required this.frames,
    this.intervalMs = 350,
    this.autoPlay = false,
  });

  @override
  State<AnimatedQrDisplayWidget> createState() => _AnimatedQrDisplayWidgetState();
}

class _AnimatedQrDisplayWidgetState extends State<AnimatedQrDisplayWidget> {
  int _currentIndex = 0;
  Timer? _timer;
  late bool _isPlaying;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.autoPlay;
    if (_isPlaying) {
      _startTimer();
    }
  }

  void _startTimer() {
    if (widget.frames.length <= 1) return;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: widget.intervalMs), (timer) {
      if (mounted && _isPlaying) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.frames.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextFrame() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.frames.length;
    });
  }

  void _prevFrame() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.frames.length) % widget.frames.length;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const Center(child: Text('No frames to display.'));
    }

    final frame = widget.frames[_currentIndex];
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: QrImageView(
            data: frame.toWireFormat(),
            version: QrVersions.auto,
            size: 240.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12.0),
        Text(
          'Frame ${frame.seq} of ${frame.total}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        LinearProgressIndicator(
          value: frame.seq / frame.total,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const Key('qr_prev_frame_button'),
              icon: const Icon(Icons.skip_previous_rounded),
              tooltip: 'Previous Frame',
              onPressed: _prevFrame,
            ),
            IconButton(
              key: const Key('qr_play_pause_button'),
              icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
              iconSize: 36,
              tooltip: _isPlaying ? 'Pause' : 'Play',
              onPressed: _togglePlayPause,
            ),
            IconButton(
              key: const Key('qr_next_frame_button'),
              icon: const Icon(Icons.skip_next_rounded),
              tooltip: 'Next Frame',
              onPressed: _nextFrame,
            ),
          ],
        ),
      ],
    );
  }
}
