import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double height;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.height = 400,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  YoutubePlayerController? _youtubeController;
  String? _twitchChannel;
  String? _twitchVideo;
  bool _isYoutube = false;
  bool _isTwitch = false;
  bool _isLocal = false;

  @override
  void initState() {
    super.initState();
    _parseUrl();
  }

  @override
  void didUpdateWidget(CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _viewType = null;
      _isYoutube = false;
      _isTwitch = false;
      _isLocal = false;
      _youtubeController?.close();
      _youtubeController = null;
      _parseUrl();
    }
  }

  void _parseUrl() {
    final url = widget.videoUrl;

    // YouTube Check
    final ytId = YoutubePlayerController.convertUrlToId(url);
    if (ytId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: ytId,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      );
      // Intentamos iniciar la reproducción con un pequeño delay para asegurar estabilidad
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _youtubeController?.playVideo();
      });
      return;
    }

    // Base64/Local Video Check
    if (url.startsWith('data:video')) {
      final String viewType =
          'local-video-${DateTime.now().millisecondsSinceEpoch}';
      // ignore: undefined_prefix_provider
      ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final element = html.VideoElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..controls = true
          ..autoplay = false;
        return element;
      });
      _viewType = viewType;
      _isLocal = true;
      return;
    }

    // Twitch Check
    if (url.contains('twitch.tv')) {
      _isTwitch = true;
      if (url.contains('/videos/')) {
        _twitchVideo = url.split('/videos/').last.split('?').first;
      } else {
        _twitchChannel = url.split('twitch.tv/').last.split('?').first;
      }

      // Register the factory for Twitch Iframe
      final String viewType =
          'twitch-player-${DateTime.now().millisecondsSinceEpoch}';
      // ignore: undefined_prefix_provider
      ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final element = html.IFrameElement()
          ..src = _getTwitchEmbedUrl()
          ..style.border = 'none'
          ..allowFullscreen = true;
        return element;
      });
      _viewType = viewType;
    }
  }

  String? _viewType;

  String _getTwitchEmbedUrl() {
    final domain = html.window.location.hostname;
    if (_twitchVideo != null) {
      return 'https://player.twitch.tv/?video=$_twitchVideo&parent=$domain&autoplay=true';
    }
    return 'https://player.twitch.tv/?channel=$_twitchChannel&parent=$domain&autoplay=true';
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _youtubeController != null) {
      return SizedBox(
        height: widget.height,
        child: YoutubePlayer(
          controller: _youtubeController!,
          aspectRatio: 16 / 9,
        ),
      );
    }

    if ((_isTwitch || _isLocal) && _viewType != null) {
      return SizedBox(
        height: widget.height,
        child: HtmlElementView(viewType: _viewType!),
      );
    }

    return Container(
      height: widget.height,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 40),
            SizedBox(height: 10),
            Text(
              'Video no compatible o link inválido',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
