import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class FacultyEndpoint extends Endpoint {
  Future<Faculty?> _findCurrentFaculty(
    Session session,
    dynamic authInfo,
  ) async {
    final userIdentifier = authInfo.userIdentifier.toString();
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Faculty.db.findFirstRow(
        session,
        where: (f) => f.userInfoId.equals(userInfoId) & f.isActive.equals(true),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    final linkedUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(userIdentifier),
    );
    if (linkedUserInfo?.id != null) {
      final resolvedLinkedUserInfo = linkedUserInfo!;
      final byLinkedUserInfo = await Faculty.db.findFirstRow(
        session,
        where: (f) =>
            f.userInfoId.equals(resolvedLinkedUserInfo.id!) &
            f.isActive.equals(true),
      );
      if (byLinkedUserInfo != null) return byLinkedUserInfo;

      final linkedEmail =
          (resolvedLinkedUserInfo.email ?? '').trim().toLowerCase();
      if (linkedEmail.isNotEmpty) {
        final byLinkedEmail = await Faculty.db.findFirstRow(
          session,
          where: (f) => f.email.equals(linkedEmail) & f.isActive.equals(true),
        );
        if (byLinkedEmail != null) return byLinkedEmail;
      }
    }

    return await Faculty.db.findFirstRow(
      session,
      where: (f) => f.email.equals(userIdentifier) & f.isActive.equals(true),
    );
  }

  @override
  bool get requireLogin => true;

  /// Fetches the schedule for the logged-in faculty.
  Future<List<Schedule>> getMySchedule(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception('Unauthorized: You must be logged in.');
    }

    final faculty = await _findCurrentFaculty(session, authInfo);

    if (faculty == null) {
      throw Exception('Faculty profile not found.');
    }

    return await Schedule.db.find(
      session,
      where: (s) => s.facultyId.equals(faculty.id),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Get personal profile
  Future<Faculty?> getMyProfile(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) return null;
    return await _findCurrentFaculty(session, authInfo);
  }

  /// Update the current faculty's profile.
  Future<Faculty?> updateMyProfile(
    Session session,
    Faculty updatedProfile,
  ) async {
    final authInfo = session.authenticated;
    if (authInfo == null) return null;

    final existing = await _findCurrentFaculty(session, authInfo);
    if (existing == null) return null;

    existing.name = updatedProfile.name;
    existing.facultyId = updatedProfile.facultyId;
    existing.maxLoad = updatedProfile.maxLoad;
    existing.employmentStatus = updatedProfile.employmentStatus;
    existing.shiftPreference = updatedProfile.shiftPreference;
    existing.preferredHours = updatedProfile.preferredHours;
    existing.program = updatedProfile.program;
    existing.updatedAt = DateTime.now();

    return await Faculty.db.updateRow(session, existing);
  }
}
