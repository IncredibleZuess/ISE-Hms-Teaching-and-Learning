import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'audio_recorder_model.dart';
export 'audio_recorder_model.dart';

class AudioRecorderWidget extends StatefulWidget {
  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onDiscard,
  });

  final Function(String path, int duration) onRecordingComplete;
  final Function() onDiscard;

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late AudioRecorderModel _model;
  final AudioRecorder _audioRecorder = AudioRecorder();
  AudioPlayer? _audioPlayer;
  Timer? _timer;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AudioRecorderModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      return result == PermissionStatus.granted;
    }
    return true;
  }

  Future<void> _startRecording() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio'),
          ),
        );
      }
      return;
    }

    try {
      String path;

      if (kIsWeb) {
        // For web, we don't need a file path - the record package handles it
        // We'll get a blob URL when we stop recording
        path = 'web_recording_${DateTime.now().millisecondsSinceEpoch}';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav, // WAV works better for web
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path, // Web will ignore this and return a blob URL
        );
      } else {
        // For mobile/desktop platforms
        final directory = await getTemporaryDirectory();
        path =
            '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
      }

      setState(() {
        _model.isRecording = true;
        _model.recordingPath = path;
        _model.recordingDuration = 0;
      });

      // Start duration timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _model.recordingDuration++;
          });
        }

        // Auto-stop at 5 minutes (300 seconds)
        if (_model.recordingDuration >= 300) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error starting recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();

    if (path != null) {
      setState(() {
        _model.isRecording = false;
        _model.hasRecording = true;
        _model.recordingPath = path;
      });

      // Initialize audio player for playback
      _initializeAudioPlayer(path);
    }
  }

  void _initializeAudioPlayer(String path) {
    _audioPlayer?.dispose();
    _audioPlayer = AudioPlayer();

    // Listen to player state
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _model.isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration
    _audioPlayer!.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _model.totalDuration = duration.inMilliseconds.toDouble();
        });
      }
    });

    // Listen to position
    _audioPlayer!.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _model.currentPosition = position.inMilliseconds.toDouble();
        });
      }
    });

    // Listen for playback completion
    _audioPlayer!.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _model.isPlaying = false;
          _model.currentPosition = 0.0;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer == null || _model.recordingPath == null) return;

    if (_model.isPlaying) {
      await _audioPlayer!.pause();
    } else {
      if (_model.currentPosition >= _model.totalDuration &&
          _model.totalDuration > 0) {
        // If finished, restart from beginning
        await _audioPlayer!.seek(Duration.zero);
      }

      if (kIsWeb) {
        // For web, the path is a blob URL
        await _audioPlayer!.play(UrlSource(_model.recordingPath!));
      } else {
        // For mobile/desktop, use DeviceFileSource
        await _audioPlayer!.play(DeviceFileSource(_model.recordingPath!));
      }
    }
  }

  Future<void> _replayRecording() async {
    if (_audioPlayer == null || _model.recordingPath == null) return;

    await _audioPlayer!.seek(Duration.zero);

    if (kIsWeb) {
      await _audioPlayer!.play(UrlSource(_model.recordingPath!));
    } else {
      await _audioPlayer!.play(DeviceFileSource(_model.recordingPath!));
    }
  }

  Future<void> _discardRecording() async {
    // Stop playback if playing
    await _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;

    if (_model.recordingPath != null && !kIsWeb) {
      // Only try to delete file on non-web platforms
      try {
        final file = File(_model.recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting recording: $e');
      }
    }

    setState(() {
      _model.hasRecording = false;
      _model.recordingPath = null;
      _model.recordingDuration = 0;
      _model.isPlaying = false;
      _model.currentPosition = 0.0;
      _model.totalDuration = 0.0;
    });

    widget.onDiscard();
  }

  Future<void> _saveRecording() async {
    if (_model.recordingPath != null) {
      widget.onRecordingComplete(
        _model.recordingPath!,
        _model.recordingDuration,
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
            // Recording status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_model.isRecording)
                  Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).error,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (_model.isRecording) const SizedBox(width: 8.0),
                Text(
                  _model.isRecording
                      ? 'Recording...'
                      : _model.hasRecording
                          ? 'Recording Complete'
                          : 'Voice Note Feedback',
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontFamily: 'Manrope',
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Duration display
            Text(
              _formatDuration(_model.recordingDuration),
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Urbanist',
                    color: FlutterFlowTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16.0),

            // Control buttons
            if (!_model.hasRecording)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlutterFlowIconButton(
                    borderColor: FlutterFlowTheme.of(context).primary,
                    borderRadius: 30.0,
                    borderWidth: 2.0,
                    buttonSize: 60.0,
                    fillColor: _model.isRecording
                        ? FlutterFlowTheme.of(context).error
                        : FlutterFlowTheme.of(context).primary,
                    icon: Icon(
                      _model.isRecording ? Icons.stop : Icons.mic,
                      color: FlutterFlowTheme.of(context).info,
                      size: 30.0,
                    ),
                    onPressed: () async {
                      if (_model.isRecording) {
                        await _stopRecording();
                      } else {
                        await _startRecording();
                      }
                    },
                  ),
                ],
              ),

            // Playback and action buttons
            if (_model.hasRecording)
              Column(
                children: [
                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      const SizedBox(width: 16.0),
                      // Replay button
                      FlutterFlowIconButton(
                        borderColor: FlutterFlowTheme.of(context).primary,
                        borderRadius: 30.0,
                        borderWidth: 2.0,
                        buttonSize: 60.0,
                        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                        icon: Icon(
                          Icons.replay,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 30.0,
                        ),
                        onPressed: () async {
                          await _replayRecording();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // Progress indicator
                  if (_model.totalDuration > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _model.totalDuration > 0
                                ? (_model.currentPosition / _model.totalDuration)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            backgroundColor:
                                FlutterFlowTheme.of(context).alternate,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                    (_model.currentPosition / 1000).round()),
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Manrope',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              Text(
                                _formatDuration(
                                    (_model.totalDuration / 1000).round()),
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Manrope',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  // Save/Discard buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FlutterFlowIconButton(
                        borderColor: FlutterFlowTheme.of(context).error,
                        borderRadius: 20.0,
                        borderWidth: 2.0,
                        buttonSize: 50.0,
                        fillColor: FlutterFlowTheme.of(context).error,
                        icon: Icon(
                          Icons.delete,
                          color: FlutterFlowTheme.of(context).info,
                          size: 24.0,
                        ),
                        onPressed: () async {
                          await _discardRecording();
                        },
                      ),
                      FlutterFlowIconButton(
                        borderColor: FlutterFlowTheme.of(context).success,
                        borderRadius: 20.0,
                        borderWidth: 2.0,
                        buttonSize: 50.0,
                        fillColor: FlutterFlowTheme.of(context).success,
                        icon: Icon(
                          Icons.check,
                          color: FlutterFlowTheme.of(context).info,
                          size: 24.0,
                        ),
                        onPressed: () async {
                          await _saveRecording();
                        },
                      ),
                    ],
                  ),
                ],
              ),

            // Info text
            if (!_model.isRecording && !_model.hasRecording)
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                child: Text(
                  'Tap the microphone to start recording',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Manrope',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_model.isRecording)
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                child: Text(
                  'Max duration: 5 minutes',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Manrope',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
