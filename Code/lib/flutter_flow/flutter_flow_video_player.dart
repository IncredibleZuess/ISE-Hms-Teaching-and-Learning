import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart' show routeObserver;

const kDefaultAspectRatio = 16 / 9;

enum VideoType {
  asset,
  network,
}

Set<VideoPlayerController> _videoPlayers = {};

class FlutterFlowVideoPlayer extends StatefulWidget {
  const FlutterFlowVideoPlayer({
    super.key,
    required this.path,
    this.videoType = VideoType.network,
    this.width,
    this.height,
    this.aspectRatio,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.allowFullScreen = true,
    this.allowPlaybackSpeedMenu = false,
    this.lazyLoad = false,
    this.pauseOnNavigate = true,
    this.rotationQuarterTurns = 0,
  });

  final String path;
  final VideoType videoType;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final bool allowFullScreen;
  final bool allowPlaybackSpeedMenu;
  final bool lazyLoad;
  final bool pauseOnNavigate;
  final int rotationQuarterTurns;

  @override
  State<StatefulWidget> createState() => _FlutterFlowVideoPlayerState();
}

class _FlutterFlowVideoPlayerState extends State<FlutterFlowVideoPlayer>
    with RouteAware {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _loggedError = false;
  bool _subscribedRoute = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    if (_subscribedRoute) {
      routeObserver.unsubscribe(this);
    }
    _disposeCurrentPlayer();
    super.dispose();
  }

  @override
  void didUpdateWidget(FlutterFlowVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _disposeCurrentPlayer();
      _initializePlayer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.pauseOnNavigate && ModalRoute.of(context) is PageRoute) {
      _subscribedRoute = true;
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    }
  }

  @override
  void didPushNext() {
    if (widget.pauseOnNavigate) {
      _videoPlayerController?.pause();
    }
  }

  double get width => widget.width == null || widget.width! >= double.infinity
      ? MediaQuery.sizeOf(context).width
      : widget.width!;

  double get height =>
      widget.height == null || widget.height! >= double.infinity
          ? width / aspectRatio
          : widget.height!;

  double get aspectRatio =>
      _chewieController?.videoPlayerController.value.aspectRatio ??
      kDefaultAspectRatio;

  void _disposeCurrentPlayer() {
    _videoPlayers.remove(_videoPlayerController);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
  }

  Future _initializePlayer() async {
    _videoPlayerController = widget.videoType == VideoType.network
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.asset(widget.path);
    if (kIsWeb && widget.autoPlay) {
      // Browsers generally don't allow autoplay unless it's muted.
      // Ideally this should be configurable, but for now we just automatically
      // mute on web.
      // See https://pub.dev/packages/video_player_web#autoplay
      _videoPlayerController!.setVolume(0);
    }
    if (!widget.lazyLoad) {
      await _videoPlayerController?.initialize();
    }
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      aspectRatio: widget.aspectRatio,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
      showControls: widget.showControls,
      allowFullScreen: widget.allowFullScreen,
      allowPlaybackSpeedChanging: widget.allowPlaybackSpeedMenu,
    );

    _videoPlayers.add(_videoPlayerController!);
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.hasError && !_loggedError) {
        print(
            'Error playing video: ${_videoPlayerController!.value.errorDescription}');
        _loggedError = true;
      }
      // Stop all other players when one video is playing.
      if (_videoPlayerController!.value.isPlaying) {
        for (var otherPlayer in _videoPlayers) {
          if (otherPlayer != _videoPlayerController &&
              otherPlayer.value.isPlaying &&
              mounted) {
            setState(() {
              otherPlayer.pause();
            });
          }
        }
      }
    });

    _chewieController!.addListener(() {
      // On web, Chewie has issues when exiting fullscreen. As a workaround,
      // reset the video player when exiting fullscreen, as suggested here:
      // https://github.com/fluttercommunity/chewie/issues/688#issuecomment-1790033300.
      if (kIsWeb && !_chewieController!.isFullScreen && _isFullScreen) {
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          final position = _videoPlayerController!.value.position;
          _disposeCurrentPlayer();
          await _initializePlayer();
          _videoPlayerController!.seekTo(position);
        });
      }
      _isFullScreen = _chewieController!.isFullScreen;
    });
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if rotation is needed (90° or 270°)
    final bool shouldSwapDimensions = widget.rotationQuarterTurns % 2 != 0;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        height: shouldSwapDimensions ? width : height,
        width: shouldSwapDimensions ? height : width,
        child: _chewieController != null &&
                (widget.lazyLoad ||
                    _chewieController!
                        .videoPlayerController.value.isInitialized)
            ? widget.rotationQuarterTurns == 0
                ? Chewie(controller: _chewieController!)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotated video layer
                      RotatedBox(
                        quarterTurns: widget.rotationQuarterTurns,
                        child: SizedBox(
                          height: shouldSwapDimensions ? width : height,
                          width: shouldSwapDimensions ? height : width,
                          child: VideoPlayer(_videoPlayerController!),
                        ),
                      ),
                      // Unrotated controls layer using basic controls
                      if (widget.showControls)
                        Positioned.fill(
                          child: _RotatedVideoControls(
                            videoPlayerController: _videoPlayerController!,
                            chewieController: _chewieController!,
                          ),
                        ),
                    ],
                  )
            : (_chewieController != null &&
                    _chewieController!.videoPlayerController.value.hasError)
                ? const Text('Error playing video')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50.0,
                        height: 50.0,
                        child: SpinKitFadingCube(
                          color: FlutterFlowTheme.of(context).tertiary,
                          size: 50.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Loading'),
                    ],
                  ),
      ),
    );
  }
}

// Custom controls widget for rotated videos
class _RotatedVideoControls extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final ChewieController chewieController;

  const _RotatedVideoControls({
    required this.videoPlayerController,
    required this.chewieController,
  });

  @override
  State<_RotatedVideoControls> createState() => _RotatedVideoControlsState();
}

class _RotatedVideoControlsState extends State<_RotatedVideoControls> {
  bool _hideControls = false;

  @override
  void initState() {
    super.initState();
    widget.videoPlayerController.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.videoPlayerController.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.videoPlayerController.value.isPlaying;
    final position = widget.videoPlayerController.value.position;
    final duration = widget.videoPlayerController.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _hideControls = !_hideControls;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: _hideControls
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  // Semi-transparent overlay
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  // Center play/pause button
                  Center(
                    child: IconButton(
                      iconSize: 64.0,
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isPlaying) {
                            widget.videoPlayerController.pause();
                          } else {
                            widget.videoPlayerController.play();
                          }
                        });
                      },
                    ),
                  ),
                  // Bottom controls bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (value) {
                                final newPosition = duration * value;
                                widget.videoPlayerController.seekTo(newPosition);
                              },
                              activeColor: FlutterFlowTheme.of(context).primary,
                              inactiveColor: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          // Time display and controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                ),
                              ),
                              if (widget.chewieController.allowFullScreen)
                                IconButton(
                                  icon: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    // Pause the video
                                    await widget.videoPlayerController.pause();

                                    // Navigate to fullscreen page
                                    if (context.mounted) {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => _FullscreenVideoPlayer(
                                            videoPlayerController: widget.videoPlayerController,
                                            chewieController: widget.chewieController,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Fullscreen video player widget
class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final ChewieController chewieController;

  const _FullscreenVideoPlayer({
    required this.videoPlayerController,
    required this.chewieController,
  });

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  bool _hideControls = false;

  @override
  void initState() {
    super.initState();
    // Set landscape orientation for fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Resume playing
    widget.videoPlayerController.play();
    widget.videoPlayerController.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.videoPlayerController.removeListener(_updateState);
    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.videoPlayerController.value.isPlaying;
    final position = widget.videoPlayerController.value.position;
    final duration = widget.videoPlayerController.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _hideControls = !_hideControls;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: widget.videoPlayerController.value.aspectRatio,
                child: VideoPlayer(widget.videoPlayerController),
              ),
            ),
            // Controls overlay
            if (!_hideControls)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Stack(
                  children: [
                    // Center play/pause button
                    Center(
                      child: IconButton(
                        iconSize: 80.0,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isPlaying) {
                              widget.videoPlayerController.pause();
                            } else {
                              widget.videoPlayerController.play();
                            }
                          });
                        },
                      ),
                    ),
                    // Top bar with close button
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.black.withValues(alpha: 0.5),
                        child: SafeArea(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom controls bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.black.withValues(alpha: 0.5),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3.0,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8.0,
                                        ),
                                      ),
                                      child: Slider(
                                        value: progress.clamp(0.0, 1.0),
                                        onChanged: (value) {
                                          final newPosition = duration * value;
                                          widget.videoPlayerController
                                              .seekTo(newPosition);
                                        },
                                        activeColor: Colors.white,
                                        inactiveColor:
                                            Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
