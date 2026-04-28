import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_client/serverpod_client.dart';

class AppErrorDialog {
  static final RegExp _minifiedPrefixPattern = RegExp(
    r'^minified:Class\d+:\s*',
    caseSensitive: false,
  );
  static final RegExp _serverpodPrefixPattern = RegExp(
    r'^ServerpodClientException:\s*',
    caseSensitive: false,
  );
  static final RegExp _statusCodeSuffixPattern = RegExp(
    r',?\s*statusCode\s*=\s*\d+\s*$',
    caseSensitive: false,
  );

  static String _cleanMessage(String message) {
    return message
        .trim()
        .replaceFirst(_minifiedPrefixPattern, '')
        .replaceFirst(_serverpodPrefixPattern, '')
        .replaceFirst(_statusCodeSuffixPattern, '')
        .trim();
  }

  static String _friendlyMessage(dynamic error) {
    if (error is ServerpodClientException) {
      final cleaned = _cleanMessage(error.message);
      if (cleaned.isNotEmpty &&
          cleaned.toLowerCase() != 'internal server error') {
        return cleaned;
      }

      switch (error.statusCode) {
        case 400:
          return 'The request is invalid. Please review the form and try again.';
        case 401:
          return 'Your session has expired. Please sign in again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested record could not be found.';
        case 500:
          return 'The server encountered an internal error while processing your request.';
      }
    }

    final raw = error?.toString().trim().isNotEmpty == true
        ? error.toString().trim()
        : 'Unknown error';
    return _cleanMessage(raw);
  }

  static void show(
    BuildContext context,
    dynamic error, {
    String title = 'Action Failed',
    String? actionLabel,
  }) {
    if (!context.mounted) return;

    final friendlyMessage = _friendlyMessage(error);
    final message = actionLabel == null || actionLabel.trim().isEmpty
        ? friendlyMessage
        : 'Action: $actionLabel\nDetails: $friendlyMessage';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
//testing