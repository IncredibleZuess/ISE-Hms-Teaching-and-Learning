import '/flutter_flow/flutter_flow_util.dart';
import 'audio_recorder_widget.dart' show AudioRecorderWidget;
import 'package:flutter/material.dart';

class AudioRecorderModel extends FlutterFlowModel<AudioRecorderWidget> {
  ///  Local state fields for this component.

  bool isRecording = false;

  bool hasRecording = false;

  String? recordingPath;

  int recordingDuration = 0;

  bool isPlaying = false;

  double currentPosition = 0.0;

  double totalDuration = 0.0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
