import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'download_helper_mobile.dart'
    if (dart.library.html) 'download_helper_web.dart';
import 'bulk_upload_users_model.dart';
export 'bulk_upload_users_model.dart';

class BulkUploadUsersWidget extends StatefulWidget {
  const BulkUploadUsersWidget({super.key});

  @override
  State<BulkUploadUsersWidget> createState() => _BulkUploadUsersWidgetState();
}

class _BulkUploadUsersWidgetState extends State<BulkUploadUsersWidget> {
  late BulkUploadUsersModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BulkUploadUsersModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _downloadTemplate() async {
    try {
      final url = Uri.parse('$baseUrl/v1/admin/bulk-upload/template');

      // Make authenticated request to download template
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${currentAuthenticationToken}',
        },
      );

      if (response.statusCode == 200) {
        final fileName = 'student_bulk_upload_template.xlsx';

        if (kIsWeb) {
          // Web-specific download with proper filename
          downloadFile(response.bodyBytes, fileName);
        } else {
          // Mobile/Desktop: use url_launcher fallback
          final base64Data = base64Encode(response.bodyBytes);
          final dataUrl = Uri.parse(
            'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data',
          );
          await launchUrl(dataUrl);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Template download started. Please check your downloads folder.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw 'Failed to download template: ${response.statusCode}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading template: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickAndPreviewFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        safeSetState(() {
          _model.isLoading = true;
          _model.errorMessage = null;
          _model.validationErrors = null;
          _model.uploadedFileName = result.files.single.name;
          _model.resetPreview();
        });

        // Create multipart request to preview endpoint
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/v1/admin/bulk-upload/preview'),
        );

        // Add authorization header
        request.headers['Authorization'] =
            'Bearer ${currentAuthenticationToken}';

        // Add file to request
        if (result.files.single.bytes != null) {
          // Web platform
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              result.files.single.bytes!,
              filename: result.files.single.name,
              contentType: MediaType('application',
                  'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
            ),
          );
        } else if (result.files.single.path != null) {
          // Mobile/Desktop platform
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              result.files.single.path!,
              contentType: MediaType('application',
                  'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
            ),
          );
        }

        // Send request
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseBody);

        safeSetState(() {
          _model.isLoading = false;
        });

        if (response.statusCode == 200) {
          safeSetState(() {
            _model.sessionToken = jsonResponse['sessionToken'] as String?;
            _model.previewValidRows =
                (jsonResponse['validRows'] as List<dynamic>? ?? [])
                    .map((r) => Map<String, dynamic>.from(r as Map))
                    .toList();
            _model.previewErrorRows =
                (jsonResponse['errorRows'] as List<dynamic>? ?? [])
                    .map((r) => Map<String, dynamic>.from(r as Map))
                    .toList();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Preview ready: ${_model.previewValidRows?.length ?? 0} valid, '
                '${_model.previewErrorRows?.length ?? 0} invalid. Review then confirm.',
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (response.statusCode == 400) {
          safeSetState(() {
            _model.errorMessage = jsonResponse['error'] ?? 'Upload failed';
          });
        } else {
          safeSetState(() {
            _model.errorMessage =
                jsonResponse['error'] ?? 'Upload failed (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      safeSetState(() {
        _model.isLoading = false;
        _model.errorMessage = 'Error uploading file: ${e.toString()}';
      });
    }
  }

  Future<void> _confirmUpload() async {
    final sessionToken = _model.sessionToken;
    if (sessionToken == null) {
      return;
    }

    safeSetState(() {
      _model.isConfirming = true;
      _model.errorMessage = null;
    });

    try {
      final response = await AdminGroup.bulkUploadConfirmCall.call(
        sessionToken: sessionToken,
        overwriteDuplicates: _model.overwriteDuplicates,
        token: currentAuthenticationToken,
      );

      safeSetState(() {
        _model.isConfirming = false;
      });

      if (response.succeeded) {
        final summary = response.jsonBody['summary'];
        if (summary is Map<String, dynamic>) {
          safeSetState(() {
            _model.importResult = summary;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.jsonBody['message'] ?? 'Import completed!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after successful import
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            context.safePop();
          }
        });
      } else {
        safeSetState(() {
          _model.errorMessage = response.bodyText.isNotEmpty
              ? (response.jsonBody['error'] ?? response.bodyText)
              : 'Could not confirm import';
        });
      }
    } catch (e) {
      safeSetState(() {
        _model.isConfirming = false;
        _model.errorMessage = 'Error confirming import: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).tertiary,
          automaticallyImplyLeading: true,
          leading: FlutterFlowIconButton(
            borderRadius: 20.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).info,
              size: 30.0,
            ),
            onPressed: () async {
              context.safePop();
            },
          ),
          title: Text(
            'Bulk Upload Students',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Manrope',
                  color: FlutterFlowTheme.of(context).info,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: const [],
          centerTitle: true,
          elevation: 4.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions Card
                  Card(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 24.0,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'Instructions',
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      fontFamily: 'Urbanist',
                                      fontSize: 20.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Follow these steps to upload students in bulk:',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12.0),
                          _buildInstructionItem(
                            '1',
                            'Download the Excel template below',
                          ),
                          _buildInstructionItem(
                            '2',
                            'Row 1 contains the headers - do not modify',
                          ),
                          _buildInstructionItem(
                            '3',
                            'Row 2 contains an example - you can delete or keep it',
                          ),
                          _buildInstructionItem(
                            '4',
                            'Add student data starting from Row 3',
                          ),
                          _buildInstructionItem(
                            '5',
                            'Save the file and upload it below',
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Required Fields:',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '• First Name\n• Last Name\n• Student Number (must be unique)\n• Email (must be valid and unique)',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                ),
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            'Optional Fields:',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '• Phone Number (10 digits starting with 0)\n• Module Code (students will be auto-enrolled)',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                ),
                          ),
                          const SizedBox(height: 12.0),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).accent1,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 16.0,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    'All students will be assigned the role "student" and their password will be automatically set to {studentNumber}@Nwu',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'Manrope',
                                          fontSize: 12.0,
                                          letterSpacing: 0.0,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Download Template Button
                  FFButtonWidget(
                    onPressed: _downloadTemplate,
                    text: 'Download Excel Template',
                    icon: const Icon(
                      Icons.download,
                      size: 20.0,
                    ),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 50.0,
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
                  const SizedBox(height: 32.0),

                  // Upload Section
                  Text(
                    'Upload Completed File',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Urbanist',
                          fontSize: 20.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16.0),

                  // Upload Completed File Button
                  FFButtonWidget(
                    onPressed: _model.isLoading ? null : _pickAndPreviewFile,
                    text: _model.isLoading
                        ? 'Processing...'
                        : (_model.uploadedFileName ?? 'Select and Upload File'),
                    icon: Icon(
                      _model.isLoading
                          ? Icons.hourglass_empty
                          : Icons.upload_file,
                      size: 20.0,
                    ),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 50.0,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 0.0, 0.0, 0.0),
                      iconPadding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).secondary,
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

                  // Error Message
                  if (_model.errorMessage != null) ...[
                    const SizedBox(height: 16.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: const Color(0xFFEF5350),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFEF5350),
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              _model.errorMessage!,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Manrope',
                                    color: const Color(0xFFC62828),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Validation Errors (from preview)
                  if (_model.previewErrorRows != null &&
                      _model.previewErrorRows!.isNotEmpty) ...[
                    const SizedBox(height: 16.0),
                    Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: const Color(0xFFFFF3E0),
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Color(0xFFF57C00),
                                  size: 20.0,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  '${_model.previewErrorRows!.length} row(s) with errors',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFE65100),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            ...(_model.previewErrorRows!.map((errorRow) {
                              final errors =
                                  (errorRow['errors'] as List<dynamic> ?? [])
                                      .join(', ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Row ${errorRow['row']}: ${errorRow['studentNum'] ?? 'N/A'} — $errors',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontSize: 13.0,
                                        letterSpacing: 0.0,
                                        color: const Color(0xFFE65100),
                                      ),
                                ),
                              );
                            }).toList()),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Preview valid rows + Confirm
                  if (_model.previewValidRows != null &&
                      _model.previewValidRows!.isNotEmpty) ...[
                    const SizedBox(height: 16.0),
                    Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: const Color(0xFFE8F5E9),
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF2E7D32),
                                  size: 20.0,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  '${_model.previewValidRows!.length} row(s) ready to import',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'A preview will be shown below. Duplicate student '
                              'numbers will be skipped unless you check the box.',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Manrope',
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    color: const Color(0xFF2E7D32),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Overwrite duplicates toggle
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Checkbox(
                          value: _model.overwriteDuplicates,
                          onChanged: (val) {
                            safeSetState(() {
                              _model.overwriteDuplicates = val ?? false;
                            });
                          },
                          activeColor: FlutterFlowTheme.of(context).primary,
                        ),
                        Expanded(
                          child: Text(
                            'Overwrite existing student numbers',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Manrope',
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ),
                      ],
                    ),

                    // Confirm button
                    const SizedBox(height: 16.0),
                    FFButtonWidget(
                      onPressed: _model.isConfirming ? null : _confirmUpload,
                      text: _model.isConfirming
                          ? 'Importing...'
                          : 'Confirm Import (${_model.previewValidRows!.length} students)',
                      icon: Icon(
                        _model.isConfirming
                            ? Icons.hourglass_empty
                            : Icons.check_circle,
                        size: 20.0,
                      ),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50.0,
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
                              fontSize: 16.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                            ),
                        elevation: 2.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],

                  // Import result summary
                  if (_model.importResult != null) ...[
                    const SizedBox(height: 16.0),
                    Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Complete',
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: 'Urbanist',
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              'Total rows: ${_model.importResult!['totalRows'] ?? 0}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Manrope',
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            Text(
                              'Created: ${_model.importResult!['created'] ?? 0}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Manrope',
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            Text(
                              'Skipped: ${_model.importResult!['skipped'] ?? 0}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Manrope',
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            Text(
                              'Failed: ${_model.importResult!['failed'] ?? 0}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Manrope',
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    color:
                                        (_model.importResult!['failed'] ?? 0) > 0
                                            ? const Color(0xFFEF5350)
                                            : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                text,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Manrope',
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
