import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_client/serverpod_client.dart';

class AppErrorDialog {
  static final RegExp _minifiedPrefixPattern = RegExp(
    r'^minified:Class\d+:\s*',
    caseSensitive: false,
  );
  static final RegExp _exceptionPrefixPattern = RegExp(
    r'^Exception:\s*',
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
        .replaceFirst(_exceptionPrefixPattern, '')
        .replaceFirst(_serverpodPrefixPattern, '')
        .replaceFirst(_statusCodeSuffixPattern, '')
        .trim();
  }

  static String _mapKnownMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return 'Something went wrong. Please try again.';

    var normalized = trimmed;
    const scheduleValidationPrefix = 'Schedule validation failed:';
    if (normalized.startsWith(scheduleValidationPrefix)) {
      normalized = normalized.substring(scheduleValidationPrefix.length).trim();
    }

    if (normalized.contains(';')) {
      final firstPart = normalized
          .split(';')
          .map((part) => part.trim())
          .firstWhere((part) => part.isNotEmpty, orElse: () => normalized);
      normalized = firstPart;
    }

    final lower = normalized.toLowerCase();

    if (lower == 'internal server error') {
      return 'The server encountered an internal error while processing your request.';
    }
    if (lower.contains('your session has expired') ||
        lower.contains('authentication required') ||
        lower == 'unauthorized' ||
        lower.contains('unauthorized:')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (lower.contains('you do not have permission') ||
        lower.contains('you are not allowed') ||
        lower.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }
    if (lower.contains('subject code') && lower.contains('already exists')) {
      return normalized;
    }
    if (lower.contains('faculty with email') && lower.contains('already exists')) {
      return 'That faculty email is already in use.';
    }
    if (lower.contains('faculty with id') && lower.contains('already exists')) {
      return 'That faculty ID already exists.';
    }
    if (lower.contains('student with email') && lower.contains('already exists')) {
      return 'That student email is already in use.';
    }
    if (lower.contains('student with number') && lower.contains('already exists')) {
      return 'That student number already exists.';
    }
    if (lower.contains('room ') && lower.contains('already exists')) {
      return normalized;
    }
    if (lower.contains('instructor already has a class during this time')) {
      return 'The selected instructor is already assigned during that time.';
    }
    if (lower.contains('faculty is already assigned at this timeslot')) {
      return 'The selected instructor is already assigned during that time.';
    }
    if (lower.contains('room is already booked during this time') ||
        lower.contains('room is already booked for this timeslot')) {
      return 'The selected room is already booked during that time.';
    }
    if (lower.contains('section already has a class during this time') ||
        lower.contains('section is already in another class at this timeslot')) {
      return 'The selected section already has a class during that time.';
    }
    if (lower.contains('timeslot is outside faculty preferred availability')) {
      return 'The selected timeslot is outside the faculty availability.';
    }
    if (lower.contains('timeslot is outside section availability')) {
      return 'The selected timeslot is outside the section availability.';
    }
    if (lower.contains('laboratory classes must start at 9:00 am or later')) {
      return 'Laboratory classes must start at 9:00 AM or later.';
    }
    if (lower.contains('scheduled classes cannot overlap lunch time')) {
      return 'The selected timeslot overlaps the lunch break.';
    }
    if (lower.contains('lecture-only subjects can only be assigned to lecture rooms')) {
      return 'Lecture-only subjects can only be assigned to lecture rooms.';
    }
    if (lower.contains('laboratory or blended subjects can only be assigned to laboratory rooms')) {
      return 'Laboratory or blended subjects can only be assigned to laboratory rooms.';
    }
    if (lower.contains('no eligible room found for auto-assignment')) {
      return 'No eligible room is available for this assignment.';
    }
    if (lower.contains('no timeslots available for auto-assignment')) {
      return 'No timeslots are available for auto-assignment.';
    }
    if (lower.contains('max load must be greater than 0')) {
      return 'Max load must be greater than 0.';
    }
    if (lower.contains('room capacity must be greater than 0')) {
      return 'Room capacity must be greater than 0.';
    }
    if (lower.contains('subject units must be greater than 0')) {
      return 'Subject units must be greater than 0.';
    }
    if (lower.contains('student count cannot be negative')) {
      return 'Student count cannot be negative.';
    }
    if (lower.contains('start time must be before end time')) {
      return 'Start time must be earlier than end time.';
    }
    if (lower.contains('invalid time format')) {
      return 'One of the time values is invalid.';
    }
    if (lower.contains('not found with id')) {
      return normalized;
    }
    if (lower.contains('profile not found')) {
      return normalized;
    }

    return normalized;
  }

  static String _friendlyMessage(dynamic error) {
    if (error is ServerpodClientException) {
      final cleaned = _cleanMessage(error.message);
      if (cleaned.isNotEmpty &&
          cleaned.toLowerCase() != 'internal server error') {
        return _mapKnownMessage(cleaned);
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
    return _mapKnownMessage(_cleanMessage(raw));
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
