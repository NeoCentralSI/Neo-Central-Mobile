part of 'seminar_models.dart';

class SeminarAnnouncement {
  final String id;
  final String date;
  final String? startTime;
  final String? endTime;
  final SeminarStatus status;
  final DateTime? resultFinalizedAt;
  final String? meetingLink;
  final RoomSummary? room;
  final String thesisTitle;
  final String presenterName;
  final String? presenterStudentId;
  final List<SeminarSupervisor> supervisors;
  final List<AnnouncementExaminer> examiners;
  final bool isOwn;
  final bool isPast;
  final bool isRegistered;
  final bool isPresent;
  final DateTime? registeredAt;

  const SeminarAnnouncement({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.resultFinalizedAt,
    required this.meetingLink,
    required this.room,
    required this.thesisTitle,
    required this.presenterName,
    required this.presenterStudentId,
    required this.supervisors,
    required this.examiners,
    required this.isOwn,
    required this.isPast,
    required this.isRegistered,
    required this.isPresent,
    required this.registeredAt,
  });

  bool get canRegister =>
      status == SeminarStatus.scheduled && !isOwn && !isPast && !isRegistered;

  bool get canUnregister =>
      status == SeminarStatus.scheduled && !isOwn && !isPast && isRegistered;

  factory SeminarAnnouncement.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'announcement');
    return SeminarAnnouncement(
      id: json.requireString('id', context: 'announcement'),
      date: json.requireString('date', context: 'announcement'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      status: SeminarStatus.fromJson(json['status']),
      resultFinalizedAt: json.optionalDateTime('resultFinalizedAt'),
      meetingLink: json.optionalString('meetingLink'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      thesisTitle: json.requireString('thesisTitle', context: 'announcement'),
      presenterName: json.requireString(
        'presenterName',
        context: 'announcement',
      ),
      presenterStudentId: json.optionalString('presenterStudentId'),
      supervisors: json
          .requireList('supervisors', context: 'announcement')
          .map(SeminarSupervisor.fromJson)
          .toList(growable: false),
      examiners: json
          .requireList('examiners', context: 'announcement')
          .map(AnnouncementExaminer.fromJson)
          .toList(growable: false),
      isOwn: json.requireBool('isOwn', context: 'announcement'),
      isPast: json.requireBool('isPast', context: 'announcement'),
      isRegistered: json.requireBool('isRegistered', context: 'announcement'),
      isPresent: json.requireBool('isPresent', context: 'announcement'),
      registeredAt: json.optionalDateTime('registeredAt'),
    );
  }
}

class AnnouncementExaminer {
  final int order;
  final String name;

  const AnnouncementExaminer({required this.order, required this.name});

  factory AnnouncementExaminer.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'announcement.examiner');
    return AnnouncementExaminer(
      order: json.requireInt('order', context: 'announcement.examiner'),
      name: json.requireString('name', context: 'announcement.examiner'),
    );
  }
}
