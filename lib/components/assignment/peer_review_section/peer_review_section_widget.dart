import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'peer_review_section_model.dart';
export 'peer_review_section_model.dart';

class PeerReviewSectionWidget extends StatefulWidget {
  const PeerReviewSectionWidget({
    super.key,
    this.assignmentID,
  });

  final String? assignmentID;

  @override
  State<PeerReviewSectionWidget> createState() => _PeerReviewSectionWidgetState();
}

class _PeerReviewSectionWidgetState extends State<PeerReviewSectionWidget> {
  late PeerReviewSectionModel _model;
  final _formKey = GlobalKey<FormState>();

  bool get _isStudent => currentUserData?.userType == 'Student';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PeerReviewSectionModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
      if (_isStudent) {
        _loadMyReviews();
        _loadMyResults();
      } else {
        _loadAllReviews();
      }
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  int? get _assignmentId => int.tryParse(widget.assignmentID ?? '');

  Future<void> _loadConfig() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) {
      return;
    }
    safeSetState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });
    try {
      final response = await PeerReviewGroup.getPeerReviewConfigCall.call(
        assignmentID: assignmentId,
        token: currentAuthenticationToken,
      );
      if (response.succeeded) {
        final config = response.jsonBody['config'];
        if (config is Map<String, dynamic>) {
          safeSetState(() {
            _model.configEnabled = config['enabled'] == true;
            _model.numPeers = castToType<int>(config['numPeers']) ?? 2;
            _model.peersController.text = _model.numPeers.toString();
            final deadline = castToType<String>(config['deadline']);
            _model.deadlineDate = deadline != null
                ? DateTime.tryParse(deadline.replaceFirst(' ', 'T'))
                : null;
          });
        }
        final rubric = response.jsonBody['rubric'];
        if (rubric is Map<String, dynamic>) {
          final name = rubric['name'] as String?;
          final criteria = rubric['criteria'] as List<dynamic>? ?? [];
          safeSetState(() {
            if (name != null) {
              _model.rubricNameController.text = name;
            }
            _model.rubricCriteria = criteria
                .map((c) => Map<String, dynamic>.from(c as Map))
                .toList();
          });
        }
      }
    } catch (e) {
      safeSetState(() {
        _model.errorMessage = 'Failed to load peer review config';
      });
    } finally {
      safeSetState(() {
        _model.isLoading = false;
      });
    }
  }

  Future<void> _loadMyReviews() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) {
      return;
    }
    try {
      final response = await PeerReviewGroup.getAssignedReviewsCall.call(
        assignmentID: assignmentId,
        token: currentAuthenticationToken,
      );
      if (response.succeeded) {
        final reviews = response.jsonBody['reviews'] as List<dynamic>? ?? [];
        final parsed = reviews.map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          m['revieweeSubmissionId'] =
              castToType<int>(m['revieweeSubmissionId']);
          return m;
        }).toList();
        safeSetState(() {
          _model.myReviews = parsed;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadMyResults() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) {
      return;
    }
    try {
      final response = await PeerReviewGroup.getPeerReviewResultsCall.call(
        assignmentID: assignmentId,
        token: currentAuthenticationToken,
      );
      if (response.succeeded) {
        safeSetState(() {
          _model.myResults = Map<String, dynamic>.from(response.jsonBody);
        });
      }
    } catch (e) {
      // results may not be visible yet (before deadline) -> ignore
    }
  }

  Future<void> _loadAllReviews() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) {
      return;
    }
    try {
      final response = await PeerReviewGroup.getAllPeerReviewsCall.call(
        assignmentID: assignmentId,
        token: currentAuthenticationToken,
      );
      if (response.succeeded) {
        final reviews = response.jsonBody['reviews'] as List<dynamic>? ?? [];
        safeSetState(() {
          _model.allReviews = reviews
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveConfig() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null) {
      return;
    }
    safeSetState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });
    try {
      final hasCriteria = _model.rubricCriteria.isNotEmpty;
      final criteriaJson =
          hasCriteria ? jsonEncode(_model.rubricCriteria) : null;
      final response = await PeerReviewGroup.configurePeerReviewCall.call(
        assignmentID: assignmentId,
        enabled: _model.configEnabled,
        numPeers: _model.numPeers,
        deadline: _model.deadlineDate?.toIso8601String(),
        rubricName:
            hasCriteria ? _model.rubricNameController.text : null,
        rubricCriteriaJson: criteriaJson,
        token: currentAuthenticationToken,
      );
      safeSetState(() {
        _model.isLoading = false;
      });
      if (response.succeeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.jsonBody['message'] ?? 'Peer review configuration saved',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.jsonBody['message'] ?? 'Failed to save configuration',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      safeSetState(() {
        _model.isLoading = false;
        _model.errorMessage = 'Failed to save config';
      });
    }
  }

  void _addCriterion() {
    safeSetState(() {
      _model.rubricCriteria.add({'name': '', 'description': '', 'weight': 0});
    });
  }

  void _removeCriterion(int index) {
    safeSetState(() {
      _model.rubricCriteria.removeAt(index);
    });
  }

  void _openSubmitForm(Map<String, dynamic> review) {
    final submissionId = review['revieweeSubmissionId'] as int?;
    safeSetState(() {
      _model.activeRevieweeSubmissionId = submissionId;
      _model.commentsController.clear();
      _model.draftScores[submissionId ?? 0] = {
        for (final c in _model.rubricCriteria)
          if (c['name'] != null && (c['name'] as String).isNotEmpty)
            c['name'] as String: 0,
      };
    });
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      useSafeArea: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: MediaQuery.viewInsetsOf(context),
          child: _buildSubmitForm(review),
        );
      },
    ).then((_) => safeSetState(() {}));
  }

  Widget _buildSubmitForm(Map<String, dynamic> review) {
    final submissionId = review['revieweeSubmissionId'] as int?;
    final draft = _model.draftScores[submissionId ?? 0] ?? {};
    final criteria = _model.rubricCriteria;

    return Container(
      width: 1200.0,
      constraints: const BoxConstraints(maxWidth: 1200.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review_outlined,
                    color: FlutterFlowTheme.of(context).primary),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Peer Review',
                    style:
                        FlutterFlowTheme.of(context).headlineSmall.override(
                              fontFamily: 'Urbanist',
                              fontSize: 22.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ),
                FlutterFlowIconButton(
                  borderRadius: 20.0,
                  borderWidth: 1.0,
                  buttonSize: 40.0,
                  icon: Icon(
                    Icons.close_rounded,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 24.0,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(
              thickness: 2.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
            if (criteria.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No rubric criteria configured for this assignment yet.',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              )
            else
              ...criteria.asMap().entries.map((entry) {
                final idx = entry.key;
                final name =
                    castToType<String>(entry.value['name']) ?? 'Criteria ${idx + 1}';
                final weight = castToType<double>(entry.value['weight']) ?? 0;
                final score = draft[name] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$name (${weight.toStringAsFixed(0)}%)',
                              style:
                                  FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            score.toStringAsFixed(0),
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                          ),
                        ],
                      ),
                      Slider(
                        value: score.clamp(0.0, weight).toDouble(),
                        min: 0.0,
                        max: weight > 0 ? weight : 1.0,
                        divisions: 20,
                        label: score.toStringAsFixed(0),
                        onChanged: (val) {
                          safeSetState(() {
                            _model.draftScores[submissionId ?? 0]?[name] = val;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _model.commentsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            FFButtonWidget(
              onPressed: () async {
                final scores = _model.draftScores[submissionId ?? 0] ?? {};
                final scoresJson = jsonEncode(scores.entries
                    .map((e) => {'name': e.key, 'score': e.value})
                    .toList());
                final response = await PeerReviewGroup.submitPeerReviewCall.call(
                  assignmentID: _assignmentId,
                  revieweeSubmissionId: submissionId,
                  rubricScoresJson: scoresJson,
                  comments: _model.commentsController.text,
                  token: currentAuthenticationToken,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
                safeSetState(() {});
                if (response.succeeded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.jsonBody['message'] ??
                          'Peer review submitted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadMyReviews();
                  _loadMyResults();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.jsonBody['message'] ??
                          'Failed to submit review'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              text: 'Submit Review',
              icon: const Icon(Icons.send, size: 20.0),
              options: FFButtonOptions(
                width: double.infinity,
                height: 50.0,
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                iconPadding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                color: FlutterFlowTheme.of(context).primary,
                textStyle:
                    FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                elevation: 2.0,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOverride(Map<String, dynamic> review) async {
    final reviewId = review['reviewId'] as int?;
    if (reviewId == null) {
      return;
    }
    final scoreController = TextEditingController(
      text: (review['totalScore'] ?? 0).toString(),
    );
    final commentController = TextEditingController(
      text: review['comments'] as String? ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Override Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Score'),
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Comment'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Override'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final response = await PeerReviewGroup.overridePeerReviewCall.call(
        reviewID: reviewId,
        overrideScore: double.tryParse(scoreController.text),
        overrideComment: commentController.text,
        token: currentAuthenticationToken,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.jsonBody['message'] ??
                (response.succeeded
                    ? 'Override saved'
                    : 'Failed to override')),
            backgroundColor:
                response.succeeded ? Colors.green : Colors.red,
          ),
        );
      }
      _loadAllReviews();
    }
    scoreController.dispose();
    commentController.dispose();
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
                  Icons.groups_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Peer Review',
                  style:
                      FlutterFlowTheme.of(context).headlineSmall.override(
                            fontFamily: 'Urbanist',
                            fontSize: 20.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (_model.isLoading && !_isStudent && _model.allReviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SpinKitFadingCircle(color: Colors.blue, size: 32.0),
                ),
              )
            else
              _isStudent
                  ? _buildStudentView()
                  : _buildLecturerView(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // My assigned reviews
        Text(
          'Reviews to complete',
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8.0),
        if (_model.myReviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'You have no pending peer reviews for this assignment.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Manrope',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          )
        else
          ..._model.myReviews.asMap().entries.map((entry) {
            final review = entry.value;
            final completed = review['completed'] == true;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Submission ${entry.key + 1}',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (completed)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20.0,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    FFButtonWidget(
                      onPressed: () async {
                        final url = castToType<String>(review['videoUrl']);
                        if (url != null && url.isNotEmpty && context.mounted) {
                          await showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              contentPadding: EdgeInsets.zero,
                              content: FlutterFlowVideoPlayer(
                                path: url,
                                videoType: VideoType.network,
                                autoPlay: true,
                                showControls: true,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video not available'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      text: 'Watch Video',
                      icon: const Icon(Icons.play_circle_outline, size: 20.0),
                      options: FFButtonOptions(
                        height: 40.0,
                        color: FlutterFlowTheme.of(context).secondary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Manrope',
                                  color: Colors.white,
                                ),
                        elevation: 2.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    if (!completed) ...[
                      const SizedBox(height: 8.0),
                      FFButtonWidget(
                        onPressed: () => _openSubmitForm(review),
                        text: 'Submit Review',
                        icon: const Icon(Icons.rate_review_outlined, size: 20.0),
                        options: FFButtonOptions(
                          height: 40.0,
                          color: FlutterFlowTheme.of(context).primary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Manrope',
                                    color: Colors.white,
                                  ),
                          elevation: 2.0,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        Divider(height: 24.0, color: FlutterFlowTheme.of(context).alternate),
        // My results (visible after deadline)
        Text(
          'My Results',
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8.0),
        if (_model.myResults == null)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Results will be visible after the peer review deadline.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Manrope',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          )
        else ...[
          Card(
            color: FlutterFlowTheme.of(context).primaryBackground,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Average score',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  ),
                  Text(
                    _model.myResults!['aggregateScore'].toString(),
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.bold,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          ...((_model.myResults!['reviews'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()).map((r) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['reviewerName'] as String? ?? 'Anonymous',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Score: ${r['totalScore']}',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    if (r['comments'] != null &&
                        (r['comments'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        r['comments'] as String,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Manrope',
                              color: FlutterFlowTheme.of(context)
                                  .secondaryText,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLecturerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Config card
        Card(
          color: FlutterFlowTheme.of(context).primaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Enable peer review',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _model.configEnabled,
                        onChanged: (val) {
                          safeSetState(() {
                            _model.configEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Number of peers to assign (1-5)',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  const SizedBox(height: 4.0),
                  TextFormField(
                    controller: _model.peersController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _model.numPeers = int.tryParse(val) ?? 2;
                    },
                    decoration: const InputDecoration(hintText: '2'),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Peer review deadline',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  const SizedBox(height: 4.0),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _model.deadlineDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        safeSetState(() {
                          _model.deadlineDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            _model.deadlineDate == null
                                ? 'Select date'
                                : dateTimeFormat('d MMM y', _model.deadlineDate!),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Rubric name',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  const SizedBox(height: 4.0),
                  TextFormField(
                    controller: _model.rubricNameController,
                    decoration: const InputDecoration(
                      hintText: 'Peer Review Rubric',
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rubric criteria',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      FFButtonWidget(
                        onPressed: _addCriterion,
                        text: 'Add',
                        icon: const Icon(Icons.add, size: 18.0),
                        options: FFButtonOptions(
                          height: 36.0,
                          color: FlutterFlowTheme.of(context).secondary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Manrope',
                                    color: Colors.white,
                                    fontSize: 13.0,
                                  ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  if (_model.rubricCriteria.isEmpty)
                    Text(
                      'No criteria added. Weights must total 100%.',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Manrope',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    )
                  else
                    ..._model.rubricCriteria.asMap().entries.map((entry) {
                      final idx = entry.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue:
                                    castToType<String>(entry.value['name']) ?? '',
                                decoration: const InputDecoration(
                                  hintText: 'Criterion name',
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  entry.value['name'] = val;
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    castToType<double>(entry.value['weight']) == null
                                        ? ''
                                        : castToType<double>(entry.value['weight'])
                                            .toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Weight %',
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  entry.value['weight'] =
                                      double.tryParse(val) ?? 0;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeCriterion(idx),
                              icon: const Icon(Icons.delete_outline),
                              color: const Color(0xFFEF5350),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16.0),
                  FFButtonWidget(
                    onPressed: _model.isLoading ? null : _saveConfig,
                    text: _model.isLoading ? 'Saving...' : 'Save Configuration',
                    icon: const Icon(Icons.save_outlined, size: 20.0),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48.0,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 0.0, 0.0, 0.0),
                      iconPadding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleMedium.override(
                                fontFamily: 'Manrope',
                                color: Colors.white,
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  if (_model.errorMessage != null) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      _model.errorMessage!,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Manrope',
                            color: const Color(0xFFC62828),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        // All submissions
        Text(
          'Submitted peer reviews (${_model.allReviews.length})',
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8.0),
        if (_model.allReviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'No peer reviews submitted yet.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Manrope',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          )
        else
          ..._model.allReviews.map((review) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${review['reviewer']} → ${review['reviewee']}',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Score: ${review['totalScore']}',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    if (review['comments'] != null &&
                        (review['comments'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        review['comments'] as String,
                        style:
                            FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Manrope',
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                ),
                      ),
                    ],
                    const SizedBox(height: 8.0),
                    FFButtonWidget(
                      onPressed: () => _openOverride(review),
                      text: 'Override Score',
                      icon: const Icon(Icons.edit_outlined, size: 18.0),
                      options: FFButtonOptions(
                        height: 36.0,
                        color: const Color(0xFFEF6C00),
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Manrope',
                                  color: Colors.white,
                                  fontSize: 13.0,
                                ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}