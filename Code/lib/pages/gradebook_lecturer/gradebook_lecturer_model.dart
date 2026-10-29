import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'gradebook_lecturer_widget.dart' show GradebookLecturerWidget;
import 'package:flutter/material.dart';

class GradebookLecturerModel extends FlutterFlowModel<GradebookLecturerWidget> {
  /// State fields for this page.

  // Module dropdown
  int? dropDownValue;
  FormFieldController<int>? dropDownValueController;

  // Data table controller
  final paginatedDataTableController =
      FlutterFlowDataTableController<dynamic>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    paginatedDataTableController.dispose();
  }
}
