import '/auth/custom_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_data_table.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'assignment_gradebook_detail_widget.dart'
    show AssignmentGradebookDetailWidget;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'download_helper_mobile.dart'
    if (dart.library.html) 'download_helper_web.dart';

class AssignmentGradebookDetailModel
    extends FlutterFlowModel<AssignmentGradebookDetailWidget> {
  /// State fields for this page.

  // Data table controller
  final paginatedDataTableController =
      FlutterFlowDataTableController<dynamic>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    paginatedDataTableController.dispose();
  }

  /// Export the gradebook data to Excel
  Future<void> exportToExcel(BuildContext context, int? assignmentID) async {
    if (assignmentID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment ID is missing'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Make authenticated request to download Excel file
      final url = Uri.parse('$baseUrl/v1/download-marks/$assignmentID/xlsx');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $currentAuthenticationToken',
        },
      );

      if (response.statusCode == 200) {
        // Extract filename from Content-Disposition header
        String fileName = 'assignment_marks.xlsx';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null) {
          // Parse filename from Content-Disposition header
          // Format: attachment; filename="Assignment_Name_marks.xlsx"
          final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition);
          if (filenameMatch != null && filenameMatch.group(1) != null) {
            fileName = filenameMatch.group(1)!;
          }
        }

        if (kIsWeb) {
          // Web-specific download with proper filename
          downloadFile(response.bodyBytes, fileName);
        } else {
          // Mobile/Desktop: use url_launcher fallback
          final base64Data = base64Encode(response.bodyBytes);
          final dataUrl = Uri.parse(
            'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data',
          );
          await launchURL(dataUrl.toString());
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Excel file download started. Please check your downloads folder.',
              ),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (response.statusCode == 404) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No marks found for this assignment'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw 'Failed to download file: ${response.statusCode}';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
