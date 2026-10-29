import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'feedback_widget.dart' show FeedbackWidget;
import 'package:flutter/material.dart';

class FeedbackModel extends FlutterFlowModel<FeedbackWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // Stores action output result for [Backend Call - API (Delete Feedback)] action in IconButton widget.
  ApiCallResponse? delete;
  // State field(s) for txtMark widget.
  FocusNode? txtMarkFocusNode;
  TextEditingController? txtMarkTextController;
  String? Function(BuildContext, String?)? txtMarkTextControllerValidator;
  String? _txtMarkTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Enter the mark';
    }

    return null;
  }

  // State field(s) for txtComment widget.
  FocusNode? txtCommentFocusNode;
  TextEditingController? txtCommentTextController;
  String? Function(BuildContext, String?)? txtCommentTextControllerValidator;
  String? _txtCommentTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Enter a comment';
    }

    return null;
  }

  // Stores action output result for [Backend Call - API (Update Feedback)] action in Button widget.
  ApiCallResponse? update;
  // Stores action output result for [Backend Call - API (Add Feedback)] action in Button widget.
  ApiCallResponse? add;
  // Voice note state
  String? voiceNotePath;
  String? voiceNoteFileName;
  int? voiceNoteDuration;
  bool hasVoiceNote = false;
  bool showVoiceRecorder = false;
  String? recordedAudioPath;
  int? recordedAudioDuration;
  bool isUploadingVoice = false;
  bool voiceNoteDeleted = false; // Track if voice note was intentionally deleted
  bool voiceNoteInitialized = false; // Track if voice note data has been initialized
  // Stores action output result for [Backend Call - API (Upload Voice Note Feedback)] action
  ApiCallResponse? uploadVoiceNote;
  // Stores action output result for [Backend Call - API (Delete Voice Note Feedback)] action
  ApiCallResponse? deleteVoiceNote;

  @override
  void initState(BuildContext context) {
    txtMarkTextControllerValidator = _txtMarkTextControllerValidator;
    txtCommentTextControllerValidator = _txtCommentTextControllerValidator;
  }

  @override
  void dispose() {
    txtMarkFocusNode?.dispose();
    txtMarkTextController?.dispose();

    txtCommentFocusNode?.dispose();
    txtCommentTextController?.dispose();
  }
}
