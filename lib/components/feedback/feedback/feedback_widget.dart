import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/components/audio/audio_player_widget.dart';
import '/components/audio/audio_recorder_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'feedback_model.dart';
export 'feedback_model.dart';

class FeedbackWidget extends StatefulWidget {
  const FeedbackWidget({
    super.key,
    this.submissionID,
    this.totalMarks,
    this.readOnly = false,
  });

  final String? submissionID;
  final String? totalMarks;
  final bool readOnly;

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  late FeedbackModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeedbackModel());

    _model.txtMarkFocusNode ??= FocusNode();
    _model.txtMarkFocusNode!.addListener(() => safeSetState(() {}));

    _model.txtCommentFocusNode ??= FocusNode();
    _model.txtCommentFocusNode!.addListener(() => safeSetState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
            child: FutureBuilder<ApiCallResponse>(
              future: FeedbackGroup.getFeedbackCall.call(
                submissionID: widget.submissionID,
                token: currentAuthenticationToken,
              ),
              builder: (context, snapshot) {
                // Customize what your widget looks like when it's loading.
                if (!snapshot.hasData) {
                  return Center(
                    child: SizedBox(
                      width: 50.0,
                      height: 50.0,
                      child: SpinKitFadingCube(
                        color: FlutterFlowTheme.of(context).tertiary,
                        size: 50.0,
                      ),
                    ),
                  );
                }
                final containerGetFeedbackResponse = snapshot.data!;

                // Extract voice note fields from response (only once, unless deleted)
                if (!_model.voiceNoteInitialized && !_model.voiceNoteDeleted) {
                  _model.voiceNotePath = FeedbackGroup.getFeedbackCall
                      .voiceNotePath(containerGetFeedbackResponse.jsonBody);
                  _model.voiceNoteFileName = FeedbackGroup.getFeedbackCall
                      .voiceNoteFileName(containerGetFeedbackResponse.jsonBody);
                  _model.voiceNoteDuration = FeedbackGroup.getFeedbackCall
                      .voiceNoteDuration(containerGetFeedbackResponse.jsonBody);
                  _model.hasVoiceNote = _model.voiceNotePath != null &&
                      _model.voiceNotePath!.isNotEmpty;
                  _model.voiceNoteInitialized = true;
                }

                return Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 700.0,
                  ),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12.0,
                        color: Color(0x33000000),
                        offset: Offset(
                          0.0,
                          5.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Form(
                    key: _model.formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: const AlignmentDirectional(0.0, -1.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Feedback',
                                          style: FlutterFlowTheme.of(context)
                                              .headlineLarge
                                              .override(
                                                fontFamily: 'Urbanist',
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FlutterFlowIconButton(
                                    borderColor: Colors.transparent,
                                    borderRadius: 30.0,
                                    borderWidth: 1.0,
                                    buttonSize: 44.0,
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 24.0,
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!widget.readOnly &&
                              FeedbackGroup.getFeedbackCall.feedbackExists(
                                containerGetFeedbackResponse.jsonBody,
                              ) ==
                                  't')
                            Align(
                              alignment: const AlignmentDirectional(-1.0, 0.0),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 5.0, 0.0, 0.0),
                                child: FlutterFlowIconButton(
                                  borderColor: Colors.transparent,
                                  borderRadius: 10.0,
                                  borderWidth: 1.0,
                                  buttonSize: 40.0,
                                  fillColor: FlutterFlowTheme.of(context).error,
                                  icon: Icon(
                                    Icons.delete,
                                    color: FlutterFlowTheme.of(context).info,
                                    size: 25.0,
                                  ),
                                  onPressed: () async {
                                    var confirmDialogResponse =
                                        await showDialog<bool>(
                                              context: context,
                                              builder: (alertDialogContext) {
                                                return AlertDialog(
                                                  title: const Text('Warning'),
                                                  content: const Text(
                                                      'Are you sure you would like to delete this feedback? This cannot be undone'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              alertDialogContext,
                                                              false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              alertDialogContext,
                                                              true),
                                                      child: const Text('Confirm'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ) ??
                                            false;
                                    if (confirmDialogResponse) {
                                      _model.delete = await FeedbackGroup
                                          .deleteFeedbackCall
                                          .call(
                                        feedbackID:
                                            FeedbackGroup.getFeedbackCall
                                                .feedbackID(
                                                  containerGetFeedbackResponse
                                                      .jsonBody,
                                                )
                                                ?.toString(),
                                        token: currentAuthenticationToken,
                                      );

                                      if ((_model.delete?.succeeded ?? true)) {
                                        await showDialog(
                                          context: context,
                                          builder: (alertDialogContext) {
                                            return AlertDialog(
                                              title: const Text('Success'),
                                              content: Text(FeedbackGroup
                                                  .deleteFeedbackCall
                                                  .errorMessage(
                                                (_model.delete?.jsonBody ?? ''),
                                              )!),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext),
                                                  child: const Text('Ok'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        await showDialog(
                                          context: context,
                                          builder: (alertDialogContext) {
                                            return AlertDialog(
                                              title: const Text('Error'),
                                              content: Text(FeedbackGroup
                                                  .deleteFeedbackCall
                                                  .errorMessage(
                                                (_model.delete?.jsonBody ?? ''),
                                              )!),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext),
                                                  child: const Text('Ok'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    }

                                    safeSetState(() {});
                                  },
                                ),
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: TextFormField(
                                  controller: _model.txtMarkTextController ??=
                                      TextEditingController(
                                    text: FeedbackGroup.getFeedbackCall.mark(
                                      containerGetFeedbackResponse.jsonBody,
                                    ),
                                  ),
                                  focusNode: _model.txtMarkFocusNode,
                                  autofocus: !widget.readOnly,
                                  readOnly: widget.readOnly,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: 'Mark',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          fontFamily: 'Manrope',
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily: 'Manrope',
                                          letterSpacing: 0.0,
                                        ),
                                    errorStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Manrope',
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          fontSize: 12.0,
                                          letterSpacing: 0.0,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .tertiary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    contentPadding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            16.0, 20.0, 16.0, 20.0),
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Manrope',
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  keyboardType: TextInputType.number,
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  validator: _model
                                      .txtMarkTextControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    20.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  '/',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontSize: 30.0,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    15.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  valueOrDefault<String>(
                                    widget.totalMarks,
                                    '0',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontSize: 20.0,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 20.0, 0.0, 0.0),
                            child: TextFormField(
                              controller: _model.txtCommentTextController ??=
                                  TextEditingController(
                                text: FeedbackGroup.getFeedbackCall.comment(
                                  containerGetFeedbackResponse.jsonBody,
                                ),
                              ),
                              focusNode: _model.txtCommentFocusNode,
                              autofocus: false,
                              readOnly: widget.readOnly,
                              textCapitalization: TextCapitalization.words,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: 'Comment',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .override(
                                      fontFamily: 'Manrope',
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      fontFamily: 'Manrope',
                                      letterSpacing: 0.0,
                                    ),
                                errorStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Manrope',
                                      color: FlutterFlowTheme.of(context).error,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        FlutterFlowTheme.of(context).tertiary,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                filled: true,
                                fillColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 20.0, 16.0, 20.0),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .override(
                                    fontFamily: 'Manrope',
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: null,
                              minLines: 4,
                              cursorColor: FlutterFlowTheme.of(context).primary,
                              validator: _model
                                  .txtCommentTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                          // Voice Note Section
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 20.0, 0.0, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Show existing voice note player
                                if (_model.hasVoiceNote &&
                                    !_model.showVoiceRecorder &&
                                    _model.voiceNotePath != null)
                                  AudioPlayerWidget(
                                    audioUrl: _model.voiceNotePath!,
                                    showDeleteButton: !widget.readOnly,
                                    onDelete: () async {
                                      final feedbackID = FeedbackGroup
                                          .getFeedbackCall
                                          .feedbackID(
                                              containerGetFeedbackResponse
                                                  .jsonBody)
                                          ?.toString();

                                      if (feedbackID != null) {
                                        // Voice note exists on server - delete via API
                                        _model.deleteVoiceNote =
                                            await FeedbackGroup
                                                .deleteVoiceNoteFeedbackCall
                                                .call(
                                          feedbackID: feedbackID,
                                          token: currentAuthenticationToken,
                                        );

                                        if (_model
                                                .deleteVoiceNote?.succeeded ??
                                            false) {
                                          setState(() {
                                            _model.hasVoiceNote = false;
                                            _model.voiceNotePath = null;
                                            _model.voiceNoteFileName = null;
                                            _model.voiceNoteDuration = null;
                                            _model.recordedAudioPath = null;
                                            _model.recordedAudioDuration = null;
                                            _model.voiceNoteDeleted = true; // Mark as deleted
                                          });

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Voice note deleted successfully'),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Failed to delete voice note'),
                                            ),
                                          );
                                        }
                                      } else {
                                        // Local recording only - just clear the state
                                        setState(() {
                                          _model.hasVoiceNote = false;
                                          _model.voiceNotePath = null;
                                          _model.voiceNoteFileName = null;
                                          _model.voiceNoteDuration = null;
                                          _model.recordedAudioPath = null;
                                          _model.recordedAudioDuration = null;
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Voice note deleted successfully'),
                                          ),
                                        );
                                      }
                                    },
                                  ),

                                // Show voice recorder (only for lecturers)
                                if (!widget.readOnly && _model.showVoiceRecorder)
                                  AudioRecorderWidget(
                                    onRecordingComplete:
                                        (String path, int duration) async {
                                      setState(() {
                                        _model.recordedAudioPath = path;
                                        _model.recordedAudioDuration = duration;
                                        _model.showVoiceRecorder = false;
                                      });

                                      // Upload voice note if feedback already exists
                                      final feedbackID = FeedbackGroup
                                          .getFeedbackCall
                                          .feedbackID(
                                              containerGetFeedbackResponse
                                                  .jsonBody)
                                          ?.toString();

                                      if (feedbackID != null) {
                                        setState(() {
                                          _model.isUploadingVoice = true;
                                        });

                                        try {
                                          Uint8List bytes;
                                          String fileName;

                                          if (kIsWeb) {
                                            // For web, path is a blob URL
                                            final response = await http.get(Uri.parse(path));
                                            bytes = Uint8List.fromList(response.bodyBytes);
                                            fileName = 'voice_note.wav';
                                          } else {
                                            // For mobile/desktop, path is a file path
                                            final file = File(path);
                                            bytes = await file.readAsBytes();
                                            fileName = 'voice_note.m4a';
                                          }

                                          _model.uploadVoiceNote =
                                              await FeedbackGroup
                                                  .uploadVoiceNoteFeedbackCall
                                                  .call(
                                            feedbackID: feedbackID,
                                            voiceNote: FFUploadedFile(
                                              name: fileName,
                                              bytes: bytes,
                                            ),
                                            duration: duration,
                                            token: currentAuthenticationToken,
                                          );

                                          setState(() {
                                            _model.isUploadingVoice = false;
                                          });

                                          if (_model.uploadVoiceNote?.succeeded ??
                                              false) {
                                            // Update state with new voice note data
                                            setState(() {
                                              _model.voiceNotePath = '$baseUrl/v1/feedback/$feedbackID/voice-note/stream';
                                              _model.voiceNoteFileName = fileName;
                                              _model.voiceNoteDuration = duration;
                                              _model.hasVoiceNote = true;
                                              _model.voiceNoteDeleted = false; // Clear deleted flag
                                            });

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Voice note uploaded successfully'),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Failed to upload voice note'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setState(() {
                                            _model.isUploadingVoice = false;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error uploading voice note: $e'),
                                            ),
                                          );
                                        }
                                      } else {
                                        // Save for later upload after feedback is created
                                        // Set the voice note fields with local path for playback
                                        setState(() {
                                          _model.voiceNotePath = path;
                                          _model.voiceNoteFileName = kIsWeb ? 'voice_note.wav' : 'voice_note.m4a';
                                          _model.voiceNoteDuration = duration;
                                          _model.hasVoiceNote = true;
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Voice note will be uploaded after saving feedback'),
                                          ),
                                        );
                                      }
                                    },
                                    onDiscard: () {
                                      setState(() {
                                        _model.showVoiceRecorder = false;
                                        _model.recordedAudioPath = null;
                                        _model.recordedAudioDuration = null;
                                      });
                                    },
                                  ),

                                // Toggle button for voice recorder (only for lecturers)
                                if (!widget.readOnly &&
                                    !_model.showVoiceRecorder &&
                                    !_model.hasVoiceNote)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 8.0, 0.0, 0.0),
                                    child: FFButtonWidget(
                                      onPressed: () async {
                                        setState(() {
                                          _model.showVoiceRecorder = true;
                                        });
                                      },
                                      text: 'Add Voice Note',
                                      icon: const Icon(
                                        Icons.mic,
                                        size: 20.0,
                                      ),
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: 45.0,
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                        iconPadding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              fontFamily: 'Manrope',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        elevation: 0.0,
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                    ),
                                  ),

                                // Replace voice note button (only for lecturers)
                                if (!widget.readOnly &&
                                    _model.hasVoiceNote &&
                                    !_model.showVoiceRecorder)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 12.0, 0.0, 0.0),
                                    child: FFButtonWidget(
                                      onPressed: () async {
                                        setState(() {
                                          _model.showVoiceRecorder = true;
                                        });
                                      },
                                      text: 'Replace Voice Note',
                                      icon: const Icon(
                                        Icons.mic,
                                        size: 20.0,
                                      ),
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: 45.0,
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                        iconPadding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              fontFamily: 'Manrope',
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        elevation: 0.0,
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .alternate,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                    ),
                                  ),

                                // Uploading indicator
                                if (_model.isUploadingVoice)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 12.0, 0.0, 0.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Text(
                                          'Uploading voice note...',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Manrope',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Submit button (only for lecturers)
                          if (!widget.readOnly)
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 24.0, 0.0, 16.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                if (_model.formKey.currentState == null ||
                                    !_model.formKey.currentState!.validate()) {
                                  return;
                                }
                                if (FeedbackGroup.getFeedbackCall
                                        .feedbackExists(
                                      containerGetFeedbackResponse.jsonBody,
                                    ) ==
                                    't') {
                                  _model.update = await FeedbackGroup
                                      .updateFeedbackCall
                                      .call(
                                    feedbackID: FeedbackGroup.getFeedbackCall
                                        .feedbackID(
                                          containerGetFeedbackResponse.jsonBody,
                                        )
                                        ?.toString(),
                                    comment: functions.formatTextForJson(
                                        _model.txtCommentTextController.text),
                                    mark: _model.txtMarkTextController.text,
                                    token: currentAuthenticationToken,
                                  );

                                  if ((_model.update?.succeeded ?? true)) {
                                    await showDialog(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return AlertDialog(
                                          title: const Text('Success'),
                                          content: Text(FeedbackGroup
                                              .updateFeedbackCall
                                              .errorMessage(
                                            (_model.update?.jsonBody ?? ''),
                                          )!),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  alertDialogContext),
                                              child: const Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    await showDialog(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return AlertDialog(
                                          title: const Text('Error'),
                                          content: Text(FeedbackGroup
                                              .updateFeedbackCall
                                              .errorMessage(
                                            (_model.update?.jsonBody ?? ''),
                                          )!),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  alertDialogContext),
                                              child: const Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                } else {
                                  _model.add =
                                      await FeedbackGroup.addFeedbackCall.call(
                                    submissionID: widget.submissionID,
                                    comment: functions.formatTextForJson(
                                        _model.txtCommentTextController.text),
                                    mark: _model.txtMarkTextController.text,
                                    token: currentAuthenticationToken,
                                  );

                                  if ((_model.add?.succeeded ?? true)) {
                                    // Upload voice note if recorded
                                    if (_model.recordedAudioPath != null) {
                                      // Extract feedbackID from response
                                      final newFeedbackID = getJsonField(
                                        _model.add?.jsonBody,
                                        r'''$.feedbackID''',
                                      )?.toString();

                                      if (newFeedbackID != null) {
                                        try {
                                          Uint8List bytes;
                                          String fileName;

                                          if (kIsWeb) {
                                            // For web, path is a blob URL
                                            final response = await http.get(
                                                Uri.parse(_model.recordedAudioPath!));
                                            bytes = Uint8List.fromList(response.bodyBytes);
                                            fileName = 'voice_note.wav';
                                          } else {
                                            // For mobile/desktop, path is a file path
                                            final file = File(_model.recordedAudioPath!);
                                            bytes = await file.readAsBytes();
                                            fileName = 'voice_note.m4a';
                                          }

                                          await FeedbackGroup
                                              .uploadVoiceNoteFeedbackCall
                                              .call(
                                            feedbackID: newFeedbackID,
                                            voiceNote: FFUploadedFile(
                                              name: fileName,
                                              bytes: bytes,
                                            ),
                                            duration:
                                                _model.recordedAudioDuration,
                                            token: currentAuthenticationToken,
                                          );
                                        } catch (e) {
                                          debugPrint(
                                              'Error uploading voice note: $e');
                                        }
                                      }
                                    }

                                    await showDialog(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return AlertDialog(
                                          title: const Text('Success'),
                                          content: Text(FeedbackGroup
                                              .addFeedbackCall
                                              .errorMessage(
                                            (_model.add?.jsonBody ?? ''),
                                          )!),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  alertDialogContext),
                                              child: const Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    Navigator.pop(context);
                                  } else {
                                    await showDialog(
                                      context: context,
                                      builder: (alertDialogContext) {
                                        return AlertDialog(
                                          title: const Text('Error'),
                                          content: Text(FeedbackGroup
                                              .addFeedbackCall
                                              .errorMessage(
                                            (_model.add?.jsonBody ?? ''),
                                          )!),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  alertDialogContext),
                                              child: const Text('Ok'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                }

                                safeSetState(() {});
                              },
                              text: 'Submit',
                              options: FFButtonOptions(
                                width: 400.0,
                                height: 55.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).tertiary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      fontFamily: 'Manrope',
                                      color: Colors.white,
                                      fontSize: 20.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                elevation: 2.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
