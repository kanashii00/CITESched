import 'package:test/test.dart';
import 'package:citesched_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given auto-assign with a selected room', (
    sessionBuilder,
    endpoints,
  ) {
    Future<Faculty> createFaculty(String facultyId, int userInfoId) async {
      return endpoints.admin.createFaculty(
        sessionBuilder,
        Faculty(
          facultyId: facultyId,
          userInfoId: userInfoId,
          name: 'Faculty $facultyId',
          email: '$facultyId@test.com',
          program: Program.it,
          maxLoad: 24,
          employmentStatus: EmploymentStatus.fullTime,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    Future<void> setAvailability(
      int facultyId,
      DayOfWeek day,
      String startTime,
      String endTime,
    ) async {
      await endpoints.admin.setFacultyAvailability(sessionBuilder, facultyId, [
        FacultyAvailability(
          facultyId: facultyId,
          dayOfWeek: day,
          startTime: startTime,
          endTime: endTime,
          isPreferred: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
    }

    Future<Room> createRoom({
      required String name,
      required RoomType type,
    }) async {
      return endpoints.admin.createRoom(
        sessionBuilder,
        Room(
          name: name,
          capacity: 40,
          type: type,
          program: Program.it,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    Future<Subject> createSubject({
      required String code,
      required List<SubjectType> types,
      required double hours,
    }) async {
      return endpoints.admin.createSubject(
        sessionBuilder,
        Subject(
          code: code,
          name: code,
          hours: hours,
          units: 3,
          types: types,
          program: Program.it,
          studentsCount: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    Future<Timeslot> createTimeslot({
      required DayOfWeek day,
      required String startTime,
      required String endTime,
      required String label,
    }) async {
      return endpoints.admin.createTimeslot(
        sessionBuilder,
        Timeslot(
          day: day,
          startTime: startTime,
          endTime: endTime,
          label: label,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    test('createSchedule keeps the selected room during auto-assign', () async {
      final faculty = await createFaculty('F201', 201);
      await setAvailability(faculty.id!, DayOfWeek.mon, '08:00', '12:00');

      final preferredRoom = await createRoom(
        name: 'Preferred Lecture Room',
        type: RoomType.lecture,
      );
      await createRoom(
        name: 'Fallback Lecture Room',
        type: RoomType.lecture,
      );

      final subject = await createSubject(
        code: 'CS-AUTO-1',
        types: [SubjectType.lecture],
        hours: 2,
      );

      final firstSlot = await createTimeslot(
        day: DayOfWeek.mon,
        startTime: '08:00',
        endTime: '10:00',
        label: 'Morning Block',
      );
      await createTimeslot(
        day: DayOfWeek.mon,
        startTime: '10:00',
        endTime: '12:00',
        label: 'Late Morning Block',
      );

      final assigned = await endpoints.admin.createSchedule(
        sessionBuilder,
        Schedule(
          subjectId: subject.id!,
          facultyId: faculty.id!,
          roomId: preferredRoom.id!,
          timeslotId: firstSlot.id!,
          section: 'BSIT-2A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final autoAssigned = await endpoints.admin.createSchedule(
        sessionBuilder,
        Schedule(
          subjectId: subject.id!,
          facultyId: faculty.id!,
          roomId: preferredRoom.id!,
          timeslotId: null,
          section: 'BSIT-2B',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(assigned.roomId, preferredRoom.id);
      expect(autoAssigned.roomId, preferredRoom.id);
      expect(autoAssigned.timeslotId, isNotNull);
      expect(autoAssigned.timeslotId, isNot(firstSlot.id));
    });

    test('updateSchedule keeps the selected room during auto-assign', () async {
      final faculty = await createFaculty('F202', 202);
      await setAvailability(faculty.id!, DayOfWeek.tue, '08:00', '12:00');

      final preferredRoom = await createRoom(
        name: 'Pinned Lecture Room',
        type: RoomType.lecture,
      );
      final alternateRoom = await createRoom(
        name: 'Alternate Lecture Room',
        type: RoomType.lecture,
      );

      final subject = await createSubject(
        code: 'CS-AUTO-2',
        types: [SubjectType.lecture],
        hours: 2,
      );

      final firstSlot = await createTimeslot(
        day: DayOfWeek.tue,
        startTime: '08:00',
        endTime: '10:00',
        label: 'Block 1',
      );
      final secondSlot = await createTimeslot(
        day: DayOfWeek.tue,
        startTime: '10:00',
        endTime: '12:00',
        label: 'Block 2',
      );

      await endpoints.admin.createSchedule(
        sessionBuilder,
        Schedule(
          subjectId: subject.id!,
          facultyId: faculty.id!,
          roomId: preferredRoom.id!,
          timeslotId: firstSlot.id!,
          section: 'BSIT-3A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final existing = await endpoints.admin.createSchedule(
        sessionBuilder,
        Schedule(
          subjectId: subject.id!,
          facultyId: faculty.id!,
          roomId: alternateRoom.id!,
          timeslotId: secondSlot.id!,
          section: 'BSIT-3B',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final updated = await endpoints.admin.updateSchedule(
        sessionBuilder,
        existing.copyWith(
          roomId: preferredRoom.id,
          timeslotId: null,
          updatedAt: DateTime.now(),
        ),
      );

      expect(updated.roomId, preferredRoom.id);
      expect(updated.timeslotId, isNotNull);
      expect(updated.timeslotId, isNot(firstSlot.id));
    });
  });
}
