import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

/// Intro video yang diputar satu kali setiap aplikasi dimulai.
class VideoIntroScreen extends StatefulWidget {
  const VideoIntroScreen({super.key});

  @override
  State<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends State<VideoIntroScreen> {
  static const _assetPath = 'assets/videos/logo-intro-mobile.mp4';
  static const _backgroundColor = Color(0xFFF7F5ED);

  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(_assetPath)
      ..addListener(_handlePlayback);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      if (!mounted || _finished) return;
      await _controller.setLooping(false);
      await _controller.setVolume(0);
      setState(() {});
      await _controller.play();
      _fallbackTimer = Timer(const Duration(seconds: 8), _finishIntro);
    } catch (_) {
      _finishIntro();
    }
  }

  void _handlePlayback() {
    final value = _controller.value;
    if (value.hasError) {
      _finishIntro();
      return;
    }
    if (!value.isInitialized || value.duration == Duration.zero) return;
    if (value.isCompleted || value.position >= value.duration) {
      _finishIntro();
    }
  }

  void _finishIntro() {
    if (_finished || !mounted) return;
    _finished = true;
    _fallbackTimer?.cancel();
    context.go('/auth/login');
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller
      ..removeListener(_handlePlayback)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SizedBox.expand(
        child: _controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const ColoredBox(color: _backgroundColor),
      ),
    );
  }
}
