import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'example_videos_section_model.dart';
export 'example_videos_section_model.dart';

class ExampleVideosSectionWidget extends StatefulWidget {
  const ExampleVideosSectionWidget({
    super.key,
    this.assignmentID,
  });

  final String? assignmentID;

  @override
  State<ExampleVideosSectionWidget> createState() =>
      _ExampleVideosSectionWidgetState();
}

class _ExampleVideosSectionWidgetState extends State<ExampleVideosSectionWidget> {
  late ExampleVideosSectionModel _model;

  bool get _canUpload => currentUserData?.userType != 'Student';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExampleVideosSectionModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  int? get _assignmentId => int.tryParse(widget.assignmentID ?? '');

  Future<void> _loadVideos() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) {
      return;
    }
    safeSetState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });
    try {
      final response = await ExampleVideoGroup.listExampleVideosCall.call(
        assignmentID: assignmentId,
        token: currentAuthenticationToken,
      );
      if (response.succeeded) {
        final videos = response.jsonBody['videos'] as List<dynamic>? ?? [];
        safeSetState(() {
          _model.videos = videos
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList();
        });
      } else {
        safeSetState(() {
          _model.errorMessage = response.jsonBody['message'] ??
              'Failed to load example videos';
        });
      }
    } catch (e) {
      safeSetState(() {
        _model.errorMessage = 'Failed to load example videos';
      });
    } finally {
      safeSetState(() {
        _model.isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) {
      return;
    }

    final title = _model.titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for the video'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'webm'],
    );
    if (result == null) {
      return;
    }

    safeSetState(() {
      _model.isUploading = true;
      _model.errorMessage = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/v1/assignments/$assignmentId/example-videos'),
      );
      request.headers['Authorization'] =
          'Bearer ${currentAuthenticationToken}';
      request.fields['title'] = title;
      if (_model.descriptionController.text.trim().isNotEmpty) {
        request.fields['description'] = _model.descriptionController.text.trim();
      }

      final file = result.files.single;
      final ext = file.extension?.toLowerCase() ?? 'mp4';
      final mediaType = MediaType('video', ext);

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'video',
            file.bytes!,
            filename: file.name,
            contentType: mediaType,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'video',
            file.path!,
            contentType: mediaType,
          ),
        );
      } else {
        throw 'Unable to read the selected file';
      }

      final streamed = await request.send();
      final body = await streamed.response.bytesToString();
      final jsonResponse = json.decode(body);

      safeSetState(() {
        _model.isUploading = false;
      });

      if (streamed.statusCode == 201 || streamed.statusCode == 200) {
        _model.titleController.clear();
        _model.descriptionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonResponse['message'] ?? 'Example video uploaded',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadVideos();
      } else {
        safeSetState(() {
          _model.errorMessage = jsonResponse['message'] ??
              'Upload failed (${streamed.statusCode})';
        });
      }
    } catch (e) {
      safeSetState(() {
        _model.isUploading = false;
        _model.errorMessage = 'Error uploading video: ${e.toString()}';
      });
    }
  }

  Future<void> _playVideo(Map<String, dynamic> video) async {
    final videoId = video['id'] as int?;
    if (videoId == null) {
      return;
    }
    final response = await ExampleVideoGroup.getExampleVideoUrlCall.call(
      videoID: videoId,
      token: currentAuthenticationToken,
    );
    if (response.succeeded && context.mounted) {
      final url = castToType<String>(
        getJsonField(response.jsonBody, r'''$.url'''),
      );
      if (url != null && url.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: FlutterFlowVideoPlayer(
              path: url,
              videoType: VideoType.network,
              autoPlay: true,
              showControls: true,
              allowFullScreen: true,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video URL unavailable'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(Map<String, dynamic> video) async {
    final videoId = video['id'] as int?;
    if (videoId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete video?'),
        content: Text('Are you sure you want to delete "${video['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final response = await ExampleVideoGroup.deleteExampleVideoCall.call(
      videoID: videoId,
      token: currentAuthenticationToken,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.jsonBody['message'] ??
              (response.succeeded ? 'Video deleted' : 'Failed to delete video')),
          backgroundColor: response.succeeded ? Colors.green : Colors.red,
        ),
      );
    }
    _loadVideos();
  }

  String _formatFileSize(dynamic fileSize) {
    final bytes = castToType<int>(fileSize) ?? 0;
    if (bytes <= 0) {
      return '';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 1200.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.video_library_outlined,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Example Videos',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'Urbanist',
                        fontSize: 20.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (_model.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SpinKitFadingCircle(color: Colors.blue, size: 32.0),
                ),
              )
            else ...[
              if (_canUpload) ...[
                // Upload form
                Card(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Upload a video for students to view as an example.',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                        const SizedBox(height: 12.0),
                        TextFormField(
                          controller: _model.titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g. Classic baseball slide into home',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _model.descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Optional',
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        FFButtonWidget(
                          onPressed:
                              _model.isUploading ? null : _pickAndUpload,
                          text: _model.isUploading
                              ? 'Uploading...'
                              : 'Select & Upload Video (mp4/mov/avi/webm)',
                          icon: _model.isUploading
                              ? const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: SpinKitFadingCircle(
                                    color: Colors.white,
                                    size: 20.0,
                                  ),
                                )
                              : const Icon(Icons.upload_file, size: 20.0),
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 48.0,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                            elevation: 2.0,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Max file size 500 MB. Large uploads may take '
                          'time depending on your connection.',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Manrope',
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                        if (_model.errorMessage != null) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            _model.errorMessage!,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Manrope',
                                      color: const Color(0xFFC62828),
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
              ],
              Text(
                _model.videos.isEmpty
                    ? 'No example videos uploaded for this assignment yet.'
                    : '${_model.videos.length} example video(s)',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Manrope',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 8.0),
              if (_model.videos.isNotEmpty)
                ..._model.videos.map((video) {
                  final size = _formatFileSize(video['fileSize']);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video['title'] as String? ?? 'Untitled',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if ((video['description'] as String?) !=
                                            null &&
                                        (video['description'] as String)
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 4.0),
                                      Text(
                                        video['description'] as String,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                            ),
                                      ),
                                    ],
                                    if (size.isNotEmpty ||
                                        (video['uploadedBy'] as String?) !=
                                            null) ...[
                                      const SizedBox(height: 4.0),
                                      Text(
                                        [
                                          if (size.isNotEmpty) size,
                                          if ((video['uploadedBy'] as String?) !=
                                              null)
                                            'Uploaded by ${video['uploadedBy']}',
                                        ].join(' • '),
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Manrope',
                                              fontSize: 12.0,
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_canUpload)
                                FlutterFlowIconButton(
                                  borderColor: Colors.transparent,
                                  borderRadius: 20.0,
                                  borderWidth: 1.0,
                                  buttonSize: 40.0,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFEF5350),
                                    size: 22.0,
                                  ),
                                  onPressed: () => _deleteVideo(video),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          FFButtonWidget(
                            onPressed: () => _playVideo(video),
                            text: 'Play Video',
                            icon: const Icon(
                              Icons.play_circle_outline,
                              size: 20.0,
                            ),
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 40.0,
                              color:
                                  FlutterFlowTheme.of(context).secondary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Manrope',
                                    color: Colors.white,
                                  ),
                              elevation: 2.0,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}