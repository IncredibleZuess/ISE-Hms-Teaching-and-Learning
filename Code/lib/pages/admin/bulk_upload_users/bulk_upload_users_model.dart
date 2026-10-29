import '/flutter_flow/flutter_flow_util.dart';
import 'bulk_upload_users_widget.dart' show BulkUploadUsersWidget;
import 'package:flutter/material.dart';

class BulkUploadUsersModel extends FlutterFlowModel<BulkUploadUsersWidget> {
  bool isLoading = false;
  String? uploadedFileName;
  String? errorMessage;
  List<Map<String, dynamic>>? validationErrors;

  /// Preview/confirm state
  String? sessionToken;
  List<Map<String, dynamic>>? previewValidRows;
  List<Map<String, dynamic>>? previewErrorRows;
  bool overwriteDuplicates = false;
  bool isConfirming = false;
  Map<String, dynamic>? importResult;

  void resetPreview() {
    sessionToken = null;
    previewValidRows = null;
    previewErrorRows = null;
    overwriteDuplicates = false;
    importResult = null;
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}