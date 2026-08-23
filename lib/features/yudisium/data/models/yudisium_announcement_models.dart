part of 'yudisium_models.dart';

class YudisiumAnnouncementParticipant {
  final String id;
  final String studentName;
  final String studentNim;
  final String thesisTitle;
  final YudisiumParticipantStatus status;
  final DateTime? registeredAt;

  const YudisiumAnnouncementParticipant({
    required this.id,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
    required this.status,
    required this.registeredAt,
  });

  factory YudisiumAnnouncementParticipant.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.announcement.person');
    return YudisiumAnnouncementParticipant(
      id: json.requireString('id', context: 'yudisium.announcement.person'),
      studentName: json.requireString(
        'studentName',
        context: 'yudisium.announcement.person',
      ),
      studentNim: json.requireString(
        'studentNim',
        context: 'yudisium.announcement.person',
      ),
      thesisTitle: json.requireString(
        'thesisTitle',
        context: 'yudisium.announcement.person',
      ),
      status: YudisiumParticipantStatus.fromJson(json['status']),
      registeredAt: json.optionalDateTime('registeredAt'),
    );
  }
}

class YudisiumAnnouncement {
  final String id;
  final String name;
  final YudisiumDisplayStatus status;
  final DateTime? eventDate;
  final RoomSummary? room;
  final String? notes;
  final List<YudisiumAnnouncementParticipant> participants;

  const YudisiumAnnouncement({
    required this.id,
    required this.name,
    required this.status,
    required this.eventDate,
    required this.room,
    required this.notes,
    required this.participants,
  });

  factory YudisiumAnnouncement.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'yudisium.announcement');
    return YudisiumAnnouncement(
      id: json.requireString('id', context: 'yudisium.announcement'),
      name: json.requireString('name', context: 'yudisium.announcement'),
      status: YudisiumDisplayStatus.fromJson(json['status']),
      eventDate: json.optionalDateTime('eventDate'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      notes: json.optionalString('notes'),
      participants: json
          .requireList('participants', context: 'yudisium.announcement')
          .map(YudisiumAnnouncementParticipant.fromJson)
          .toList(growable: false),
    );
  }
}
