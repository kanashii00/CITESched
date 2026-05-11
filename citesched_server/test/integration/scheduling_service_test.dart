import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'package:citesched_server/src/generated/protocol.dart';

void main() {
  withServerpod('Given SchedulingService', (sessionBuilder, endpoints) {
    group('Conflict Detection -', () {
      test(
        'Faculty availability - allows a shifted two-hour lecture within availability',
        () async {
          final faculty = await endpoints.admin.createFaculty(
            sessionBuilder,
            Faculty(
              facultyId: 'F100',
              userInfoId: 100,
              name: 'Dr. Flexible',
              email: 'flexible@test.com',
              program: Program.it,
              maxLoad: 24,
              employmentStatus: EmploymentStatus.fullTime,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          await endpoints.admin.setFacultyAvailability(
            sessionBuilder,
            faculty.id!,
            [
              FacultyAvailability(
                facultyId: faculty.id!,
                dayOfWeek: DayOfWeek.mon,
                startTime: '08:00',
                endTime: '19:30',
                isPreferred: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ],
          );

          final room = await endpoints.admin.createRoom(
            sessionBuilder,
            Room(
              name: 'ROOM FLEX',
              capacity: 30,
              type: RoomType.lecture,
              program: Program.it,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final subject = await endpoints.admin.createSubject(
            sessionBuilder,
            Subject(
              code: 'CSFLEX',
              name: 'Flexible Scheduling',
              hours: 2,
              units: 3,
              types: [SubjectType.lecture],
              program: Program.it,
              studentsCount: 30,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final originalTimeslot = await endpoints.admin.createTimeslot(
            sessionBuilder,
            Timeslot(
              day: DayOfWeek.mon,
              startTime: '17:00',
              endTime: '19:00',
              label: 'Mon 17:00-19:00',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final shiftedTimeslot = await endpoints.admin.createTimeslot(
            sessionBuilder,
            Timeslot(
              day: DayOfWeek.mon,
              startTime: '17:30',
              endTime: '19:30',
              label: 'Mon 17:30-19:30',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final schedule = await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: subject.id!,
              facultyId: faculty.id!,
              roomId: room.id!,
              timeslotId: originalTimeslot.id!,
              section: 'A',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final updated = await endpoints.admin.updateSchedule(
            sessionBuilder,
            schedule.copyWith(
              timeslotId: shiftedTimeslot.id!,
              updatedAt: DateTime.now(),
            ),
          );

          expect(updated.timeslotId, shiftedTimeslot.id);
        },
      );

      test(
        'SF subjects can be scheduled without section availability',
        () async {
          final faculty = await endpoints.admin.createFaculty(
            sessionBuilder,
            Faculty(
              facultyId: 'F110',
              userInfoId: 110,
              name: 'Dr. SF',
              email: 'sf@test.com',
              program: Program.it,
              maxLoad: 24,
              employmentStatus: EmploymentStatus.fullTime,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          await endpoints.admin.setFacultyAvailability(sessionBuilder, faculty.id!, [
            FacultyAvailability(
              facultyId: faculty.id!,
              dayOfWeek: DayOfWeek.tue,
              startTime: '13:00',
              endTime: '19:30',
              isPreferred: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ]);

          final section = await endpoints.admin.createSection(
            sessionBuilder,
            Section(
              sectionCode: '2A',
              program: Program.it,
              yearLevel: 2,
              academicYear: '2026-2027',
              semester: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final room = await endpoints.admin.createRoom(
            sessionBuilder,
            Room(
              name: 'ROOM SF',
              capacity: 30,
              type: RoomType.lecture,
              program: Program.it,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final subject = await endpoints.admin.createSubject(
            sessionBuilder,
            Subject(
              code: 'SF101',
              name: 'Student Formation',
              hours: 2,
              units: 3,
              types: [SubjectType.lecture],
              program: Program.it,
              studentsCount: 30,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final timeslot = await endpoints.admin.createTimeslot(
            sessionBuilder,
            Timeslot(
              day: DayOfWeek.tue,
              startTime: '17:30',
              endTime: '19:30',
              label: 'Tue 17:30-19:30',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final schedule = await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: subject.id!,
              facultyId: faculty.id!,
              roomId: room.id!,
              timeslotId: timeslot.id!,
              section: section.sectionCode,
              sectionId: section.id!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          expect(schedule.id, isNotNull);
          expect(schedule.timeslotId, timeslot.id);
        },
      );

      test('Room availability - detects double booking', () async {
        // Create test data
        var faculty1 = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            facultyId: 'F101',
            userInfoId: 101,
            name: 'Dr. Smith',
            email: 'smith@test.com',
            program: Program.it,
            maxLoad: 5,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'ROOM 1',
            capacity: 30,
            type: RoomType.lecture,
            program: Program.it,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var subject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'CS101',
            name: 'Intro to CS',
            hours: 1,
            units: 3,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.mon,
            startTime: '08:00',
            endTime: '09:00',
            label: 'Period 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create first schedule
        var schedule1 = await endpoints.admin.createSchedule(
          sessionBuilder,
          Schedule(
            subjectId: subject.id!,
            facultyId: faculty1.id!,
            roomId: room.id!,
            timeslotId: timeslot.id!,
            section: 'A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(schedule1.id, isNotNull);

        // Try to create conflicting schedule (same room, same timeslot)
        expect(
          () async => await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: subject.id!,
              facultyId: faculty1.id!,
              roomId: room.id!, // Same room
              timeslotId: timeslot.id!, // Same timeslot
              section: 'B',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Faculty availability - detects overlapping schedules', () async {
        // Create test data
        var faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            facultyId: 'F102',
            userInfoId: 102,
            name: 'Dr. Jones',
            email: 'jones@test.com',
            program: Program.it,
            maxLoad: 5,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room1 = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'ROOM 1',
            capacity: 30,
            type: RoomType.lecture,
            program: Program.it,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room2 = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'IT LAB',
            capacity: 30,
            type: RoomType.laboratory,
            program: Program.it,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var lectureSubject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'MATH101',
            name: 'Calculus I',
            hours: 1,
            units: 3,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var labSubject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'MATH101L',
            name: 'Calculus I Lab',
            hours: 1,
            units: 3,
            types: [SubjectType.laboratory],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.tue,
            startTime: '10:00',
            endTime: '11:00',
            label: 'Period 3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create first schedule
        await endpoints.admin.createSchedule(
          sessionBuilder,
          Schedule(
            subjectId: lectureSubject.id!,
            facultyId: faculty.id!,
            roomId: room1.id!,
            timeslotId: timeslot.id!,
            section: 'A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Try to assign same faculty to different room at same time
        expect(
          () async => await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: labSubject.id!,
              facultyId: faculty.id!, // Same faculty
              roomId: room2.id!, // Different room
              timeslotId: timeslot.id!, // Same timeslot
              section: 'B',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Faculty max load - prevents exceeding limit', () async {
        // Create faculty with low max load
        var faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            facultyId: 'F103',
            userInfoId: 103,
            name: 'Dr. Limited',
            email: 'limited@test.com',
            program: Program.it,
            maxLoad: 1,
            employmentStatus: EmploymentStatus.partTime,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'ROOM 1',
            capacity: 30,
            type: RoomType.lecture,
            program: Program.it,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var subject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'CS201',
            name: 'Data Structures',
            hours: 1,
            units: 1,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot1 = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.wed,
            startTime: '08:00',
            endTime: '09:00',
            label: 'Period 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot2 = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.wed,
            startTime: '10:00',
            endTime: '11:00',
            label: 'Period 3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create first schedule (should succeed)
        await endpoints.admin.createSchedule(
          sessionBuilder,
          Schedule(
            subjectId: subject.id!,
            facultyId: faculty.id!,
            roomId: room.id!,
            timeslotId: timeslot1.id!,
            section: 'A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Try to create second schedule (should fail - exceeds max load)
        expect(
          () async => await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: subject.id!,
              facultyId: faculty.id!,
              roomId: room.id!,
              timeslotId: timeslot2.id!, // Different timeslot
              section: 'B',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
