import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'audio_player_model.dart';
export 'audio_player_model.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.onDelete,
    this.showDeleteButton = false,
  });

  final String audioUrl;
  final Function()? onDelete;
  final bool showDeleteButton;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayerModel _model;
  late AudioPlayer _audioPlayer;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudioPlayerModel());
    _audioPlayer = AudioPlayer();

    // Listen to player state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _model.isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _model.totalDuration = duration.inMilliseconds.toDouble();
        });
      }
    });

    // Listen to position
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _model.currentPosition = position.inMilliseconds.toDouble();
        });
      }
    });

    // Listen for playback completion
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _model.isPlaying = false;
          _model.currentPosition = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_model.isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_model.currentPosition >= _model.totalDuration && _model.totalDuration > 0) {
        // If finished, restart from beginning
        await _audioPlayer.seek(Duration.zero);
      }

      // Determine the appropriate source based on the audio URL
      Source source;
      if (widget.audioUrl.startsWith('http://') || widget.audioUrl.startsWith('https://')) {
        // Server URL
        source = UrlSource(widget.audioUrl);
      } else if (kIsWeb || widget.audioUrl.startsWith('blob:')) {
        // Web blob URL
        source = UrlSource(widget.audioUrl);
      } else {
        // Local file path (mobile/desktop)
        source = DeviceFileSource(widget.audioUrl);
      }

      await _audioPlayer.play(source);
    }
  }

  Future<void> _seek(double value) async {
    final duration = Duration(milliseconds: value.toInt());
    await _audioPlayer.seek(duration);
  }

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 24.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Voice Note Feedback',
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Manrope',
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (widget.showDeleteButton && widget.onDelete != null)
                  FlutterFlowIconButton(
                    borderColor: Colors.transparent,
                    borderRadius: 20.0,
                    borderWidth: 1.0,
                    buttonSize: 36.0,
                    fillColor: FlutterFlowTheme.of(context).error,
                    icon: Icon(
                      Icons.delete,
                      color: FlutterFlowTheme.of(context).info,
                      size: 18.0,
                    ),
                    onPressed: () async {
                      var confirmDialogResponse = await showDialog<bool>(
                            context: context,
                            builder: (alertDialogContext) {
                              return AlertDialog(
                                title: const Text('Delete Voice Note'),
                                content: const Text(
                                    'Are you sure you want to delete this voice note? This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        alertDialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(alertDialogContext, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;

                      if (confirmDialogResponse && widget.onDelete != null) {
                        widget.onDelete!();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Play/Pause button
            FlutterFlowIconButton(
              borderColor: FlutterFlowTheme.of(context).primary,
              borderRadius: 30.0,
              borderWidth: 2.0,
              buttonSize: 60.0,
              fillColor: FlutterFlowTheme.of(context).primary,
              icon: Icon(
                _model.isPlaying ? Icons.pause : Icons.play_arrow,
                color: FlutterFlowTheme.of(context).info,
                size: 30.0,
              ),
              onPressed: () async {
                await _togglePlayPause();
              },
            ),
            const SizedBox(height: 16.0),

            // Progress slider
            Row(
              children: [
                Text(
                  _formatDuration(_model.currentPosition),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Manrope',
                        letterSpacing: 0.0,
                      ),
                ),
                Expanded(
                  child: Slider(
                    value: _model.totalDuration > 0
                        ? _model.currentPosition.clamp(0.0, _model.totalDuration)
                        : 0.0,
                    min: 0.0,
                    max: _model.totalDuration > 0 ? _model.totalDuration : 1.0,
                    activeColor: FlutterFlowTheme.of(context).primary,
                    inactiveColor: FlutterFlowTheme.of(context).alternate,
                    onChanged: (value) async {
                      await _seek(value);
                    },
                  ),
                ),
                Text(
                  _formatDuration(_model.totalDuration),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Manrope',
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
