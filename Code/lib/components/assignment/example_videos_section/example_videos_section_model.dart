import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'example_videos_section_widget.dart' show ExampleVideosSectionWidget;

class ExampleVideosSectionModel
    extends FlutterFlowModel<ExampleVideosSectionWidget> {
  bool isLoading = false;
  bool isUploading = false;
  String? errorMessage;

  /// List of example videos for this assignment
  List<Map<String, dynamic>> videos = [];

  /// Upload form fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}