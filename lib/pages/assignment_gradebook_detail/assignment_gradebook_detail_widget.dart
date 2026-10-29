import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/components/empty_lists/empty_gradebook/empty_gradebook_widget.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'assignment_gradebook_detail_model.dart';
export 'assignment_gradebook_detail_model.dart';

class AssignmentGradebookDetailWidget extends StatefulWidget {
  const AssignmentGradebookDetailWidget({
    super.key,
    required this.assignmentID,
    this.assignmentName,
  });

  final int? assignmentID;
  final String? assignmentName;

  @override
  State<AssignmentGradebookDetailWidget> createState() =>
      _AssignmentGradebookDetailWidgetState();
}

class _AssignmentGradebookDetailWidgetState
    extends State<AssignmentGradebookDetailWidget> {
  late AssignmentGradebookDetailModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AssignmentGradebookDetailModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiCallResponse>(
      future: FeedbackGroup.getAssignmentGradebookForStaffCall.call(
        token: currentAuthenticationToken,
        assignmentID: widget.assignmentID,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitFadingCube(
                  color: FlutterFlowTheme.of(context).tertiary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }
        final gradebookResponse = snapshot.data!;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).tertiary,
              automaticallyImplyLeading: false,
              leading: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 60.0,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 30.0,
                ),
                onPressed: () async {
                  context.pop();
                },
              ),
              title: Text(
                widget.assignmentName ?? 'Assignment Gradebook',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Urbanist',
                      color: Colors.white,
                      fontSize: 22.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              actions: [
                FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 30.0,
                  borderWidth: 1.0,
                  buttonSize: 60.0,
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 30.0,
                  ),
                  onPressed: () async {
                    await _model.exportToExcel(context, widget.assignmentID);
                  },
                ),
              ],
              centerTitle: true,
              elevation: 2.0,
            ),
            body: SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    10.0, 10.0, 10.0, 10.0),
                child: Builder(
                  builder: (context) {
                    final rows = FeedbackGroup
                            .getAssignmentGradebookForStaffCall
                            .rows(
                              gradebookResponse.jsonBody,
                            )
                            ?.toList() ??
                        [];
                    if (rows.isEmpty) {
                      return const EmptyGradebookWidget();
                    }

                    return FlutterFlowDataTable<dynamic>(
                              controller: _model.paginatedDataTableController,
                              data: rows,
                              columnsBuilder: (onSortChanged) => [
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Viewed',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'First name',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Last name',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Student no.',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Comment',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Mark',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Total marks',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn2(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Percentage',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              fontFamily: 'Manrope',
                                              color: FlutterFlowTheme.of(context)
                                                  .info,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              dataRowBuilder:
                                  (row, index, selected, onSelectChanged) =>
                                      DataRow(
                                color: WidgetStateProperty.all(
                                  index % 2 == 0
                                      ? FlutterFlowTheme.of(context)
                                          .secondaryBackground
                                      : FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                ),
                                cells: [
                                  DataCell(
                                    Icon(
                                      getJsonField(row, r'$.feedbackViewed') == 1
                                          ? Icons.check_circle
                                          : Icons.access_time,
                                      color:
                                          getJsonField(row, r'$.feedbackViewed') ==
                                                  1
                                              ? FlutterFlowTheme.of(context)
                                                  .success
                                              : FlutterFlowTheme.of(context)
                                                  .warning,
                                      size: 24.0,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      getJsonField(row, r'$.firstName')
                                          .toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      getJsonField(row, r'$.lastName').toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      getJsonField(row, r'$.username').toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      getJsonField(row, r'$.comment').toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      getJsonField(row, r'$.mark').toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      getJsonField(row, r'$.totalMarks')
                                          .toString(),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${getJsonField(row, r'$.percentage').toString()}%',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Manrope',
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              paginated: true,
                              selectable: false,
                              hidePaginator: false,
                              showFirstLastButtons: true,
                              width: MediaQuery.sizeOf(context).width * 1.0,
                              headingRowHeight: 56.0,
                              dataRowHeight: 48.0,
                              columnSpacing: 20.0,
                              headingRowColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              borderRadius: BorderRadius.circular(8.0),
                              addHorizontalDivider: true,
                              addTopAndBottomDivider: true,
                              hideDefaultHorizontalDivider: false,
                              addVerticalDivider: false,
                            );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
