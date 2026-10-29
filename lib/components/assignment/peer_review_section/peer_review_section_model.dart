import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'peer_review_section_widget.dart' show PeerReviewSectionWidget;

class PeerReviewSectionModel extends FlutterFlowModel<PeerReviewSectionWidget> {
  bool isLoading = false;
  String? errorMessage;

  /// Config (lecturer view + student submit form)
  bool configEnabled = false;
  int numPeers = 2;
  DateTime? deadlineDate;
  final TextEditingController rubricNameController = TextEditingController();
  final TextEditingController peersController = TextEditingController();
  List<Map<String, dynamic>> rubricCriteria = [];

  /// Student: assigned reviews
  List<Map<String, dynamic>> myReviews = [];

  /// Student: my results
  Map<String, dynamic>? myResults;

  /// Lecturer/Admin: all review submissions
  List<Map<String, dynamic>> allReviews = [];

  /// Store rubric criteria per-criterion score while filling a review
  final Map<int, Map<String, double>> draftScores = {};

  /// Comments text controller for a review form
  final TextEditingController commentsController = TextEditingController();
  int? activeRevieweeSubmissionId;

  @override
  void initState(BuildContext context) {
    rubricNameController.text = 'Peer Review Rubric';
    peersController.text = '2';
  }

  @override
  void dispose() {
    rubricNameController.dispose();
    peersController.dispose();
    commentsController.dispose();
  }
}