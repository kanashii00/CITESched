import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

import '../generated/protocol.dart';

/// Student endpoint for viewing schedules and managing the logged-in user's
/// linked student profile.
class StudentEndpoint extends Endpoint {
  Future<Student?> _findCurrentStudent(
    Session session,
    dynamic authInfo,
  ) async {
    final userIdentifier = authInfo.userIdentifier.toString();
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Student.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userInfoId) & t.isActive.equals(true),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    final linkedUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(userIdentifier),
    );
    if (linkedUserInfo?.id != null) {
      final resolvedLinkedUserInfo = linkedUserInfo!;
      final byLinkedUserInfo = await Student.db.findFirstRow(
        session,
        where: (t) =>
            t.userInfoId.equals(resolvedLinkedUserInfo.id!) &
            t.isActive.equals(true),
      );
      if (byLinkedUserInfo != null) return byLinkedUserInfo;

      final linkedEmail =
          (resolvedLinkedUserInfo.email ?? '').trim().toLowerCase();
      if (linkedEmail.isNotEmpty) {
        final byLinkedEmail = await Student.db.findFirstRow(
          session,
          where: (t) => t.email.equals(linkedEmail) & t.isActive.equals(true),
        );
        if (byLinkedEmail != null) return byLinkedEmail;
      }
    }

    return await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier) & t.isActive.equals(true),
    );
  }

  @override
  bool get requireLogin => true;

  // ─── Schedule Viewing ────────────────────────────────────────────────

  /// Get all available schedules (read-only for students).
  Future<List<Schedule>> getSchedules(Session session) async {
    return await Schedule.db.find(session);
  }

  /// Get a specific schedule by ID.
  Future<Schedule?> getScheduleById(Session session, int id) async {
    return await Schedule.db.findById(session, id);
  }

  // ─── Student Profile ─────────────────────────────────────────────────

  /// Get the current student's profile by their auth user ID.
  Future<Student?> getMyProfile(Session session) async {
    var authInfo = session.authenticated;
    if (authInfo == null) return null;
    return await _findCurrentStudent(session, authInfo);
  }

  /// Update the current student's profile.
  Future<Student?> updateMyProfile(
    Session session,
    Student updatedProfile,
  ) async {
    var authInfo = session.authenticated;
    if (authInfo == null) return null;

    // Only allow updating own profile
    var existing = await _findCurrentStudent(session, authInfo);

    if (existing == null) return null;

    // Preserve the ID and email; only update editable fields.
    existing.name = updatedProfile.name;
    existing.course = updatedProfile.course;
    existing.yearLevel = updatedProfile.yearLevel;
    existing.section = updatedProfile.section;
    existing.studentNumber = updatedProfile.studentNumber;
    existing.updatedAt = DateTime.now();

    return await Student.db.updateRow(session, existing);
  }

  // ─── Read-Only Data ──────────────────────────────────────────────────

  /// Get all faculty members (read-only).
  Future<List<Faculty>> getFaculty(Session session) async {
    return await Faculty.db.find(session);
  }

  /// Get all rooms (read-only).
  Future<List<Room>> getRooms(Session session) async {
    return await Room.db.find(session);
  }

  /// Get all subjects (read-only).
  Future<List<Subject>> getSubjects(Session session) async {
    return await Subject.db.find(session);
  }

  /// Get all timeslots (read-only).
  Future<List<Timeslot>> getTimeslots(Session session) async {
    return await Timeslot.db.find(session);
  }
}
