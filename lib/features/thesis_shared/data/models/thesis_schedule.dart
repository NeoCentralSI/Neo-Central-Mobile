import '../../../../core/utils/api_contract_parser.dart';
import 'thesis_people_models.dart';

class ThesisSchedule {
  final String? date;
  final String? startTime;
  final String? endTime;
  final RoomSummary? room;
  final String? meetingLink;
  final DateTime? scheduledAt;
  final String? invitationLetterNo;

  const ThesisSchedule({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.meetingLink,
    required this.scheduledAt,
    required this.invitationLetterNo,
  });

  bool get isOnline => meetingLink != null && meetingLink!.isNotEmpty;

  bool get isComplete =>
      date != null &&
      startTime != null &&
      endTime != null &&
      (room != null || isOnline);

  factory ThesisSchedule.fromJson(dynamic value) {
    final json = requireJsonMap(value, context: 'schedule');
    return ThesisSchedule(
      date: json.optionalString('date'),
      startTime: json.optionalString('startTime'),
      endTime: json.optionalString('endTime'),
      room: json['room'] == null ? null : RoomSummary.fromJson(json['room']),
      meetingLink: json.optionalString('meetingLink'),
      scheduledAt: json.optionalDateTime('scheduledAt'),
      invitationLetterNo: json.optionalString('invitationLetterNo'),
    );
  }
}
