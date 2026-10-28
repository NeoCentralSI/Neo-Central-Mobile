/// Models for the Pengumuman screens (Seminar Hasil and Yudisium) and the
/// Seminar Hasil detail opened from them.
///
/// Parsing is lenient on purpose: a missing or renamed optional field falls
/// back to a default instead of failing the whole list, so one odd row cannot
/// empty the announcement board.
library;

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<dynamic> _list(Object? value) => value is List ? value : const [];

String _str(Object? value, [String fallback = '-']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _optStr(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _bool(Object? value) => value == true;

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _date(Object? value) {
  final text = _optStr(value);
  return text == null ? null : DateTime.tryParse(text);
}

/// Offset of Waktu Indonesia Barat, the timezone the backend schedules in.
const Duration wibOffset = Duration(hours: 7);

/// Calendar day of a seminar or yudisium date in WIB.
DateTime? wibDay(DateTime? value) {
  if (value == null) return null;
  final local = value.toUtc().add(wibOffset);
  return DateTime.utc(local.year, local.month, local.day);
}

/// "HH:mm" of a time-of-day column. The backend stores times as
/// `1970-01-01THH:mm:00Z`, so the UTC hour is the wall-clock hour (as on web).
String? clockOf(DateTime? value) {
  if (value == null) return null;
  final utc = value.toUtc();
  return '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}';
}

// ─── Seminar status ─────────────────────────────────────────

/// Indonesian label of a seminar status, as on the web announcement page.
String seminarStatusLabel(String? status) => switch (status) {
  'registered' => 'Terdaftar',
  'verified' => 'Terverifikasi',
  'examiner_assigned' => 'Penguji Ditetapkan',
  'scheduled' => 'Dijadwalkan',
  'ongoing' => 'Sedang Berlangsung',
  'passed' => 'Lulus',
  'passed_with_revision' => 'Lulus dengan Revisi',
  'failed' => 'Tidak Lulus',
  'cancelled' => 'Dibatalkan',
  _ => '-',
};

/// The seminar result is final: passed, passed with revision, or failed.
bool isSeminarResultFinal(String? status) =>
    status == 'passed' ||
    status == 'passed_with_revision' ||
    status == 'failed';

// ─── Seminar announcement ───────────────────────────────────

class SeminarPerson {
  final String name;
  final String role;

  const SeminarPerson({required this.name, required this.role});
}

class SeminarAnnouncement {
  final String id;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final DateTime? resultFinalizedAt;
  final String? roomName;
  final String thesisTitle;
  final String presenterName;
  final List<SeminarPerson> supervisors;
  final List<SeminarPerson> examiners;
  final bool isOwn;
  final bool isPast;
  final bool isRegistered;
  final bool isPresent;

  const SeminarAnnouncement({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.resultFinalizedAt,
    required this.roomName,
    required this.thesisTitle,
    required this.presenterName,
    required this.supervisors,
    required this.examiners,
    required this.isOwn,
    required this.isPast,
    required this.isRegistered,
    required this.isPresent,
  });

  static SeminarAnnouncement? tryParse(Object? value) {
    final json = _map(value);
    final id = _optStr(json['id']);
    if (id == null) return null;
    final examiners = _list(json['examiners']).map(_map).toList()
      ..sort(
        (a, b) => (_int(a['order']) ?? 99).compareTo(_int(b['order']) ?? 99),
      );
    return SeminarAnnouncement(
      id: id,
      date: _date(json['date']),
      startTime: _date(json['startTime']),
      endTime: _date(json['endTime']),
      status: _str(json['status'], ''),
      resultFinalizedAt: _date(json['resultFinalizedAt']),
      roomName: _optStr(_map(json['room'])['name']),
      thesisTitle: _str(json['thesisTitle']),
      presenterName: _str(json['presenterName']),
      supervisors: [
        for (final item in _list(json['supervisors']).map(_map))
          SeminarPerson(name: _str(item['name']), role: _str(item['role'])),
      ],
      examiners: [
        for (final item in examiners)
          SeminarPerson(
            name: _str(item['name']),
            role: 'Penguji ${_int(item['order']) ?? ''}'.trim(),
          ),
      ],
      isOwn: _bool(json['isOwn']),
      isPast: _bool(json['isPast']),
      isRegistered: _bool(json['isRegistered']),
      isPresent: _bool(json['isPresent']),
    );
  }

  /// Start of the seminar, for sorting (newest first, as on web).
  DateTime get sortKey {
    final day = wibDay(date) ?? DateTime.utc(1970);
    final start = startTime?.toUtc();
    return day.add(
      Duration(hours: start?.hour ?? 0, minutes: start?.minute ?? 0),
    );
  }

  SeminarPerson? get mainSupervisor {
    for (final person in supervisors) {
      if (person.role == 'Pembimbing 1') return person;
    }
    return null;
  }

  bool get isUpcoming => status == 'scheduled' && !isPast;

  bool get _isFinalizedResult =>
      isSeminarResultFinal(status) || resultFinalizedAt != null;

  /// A student may register: scheduled, not their own, not past, not yet in.
  bool get canRegister =>
      status == 'scheduled' && !isOwn && !isPast && !isRegistered;

  /// A student may cancel their registration before the seminar day.
  bool get canUnregister =>
      status == 'scheduled' && !isOwn && !isPast && isRegistered;

  /// Attendance chip for students, as on web; null when it is hidden.
  AudienceState? get audienceState {
    if (isOwn && !isPast && !isRegistered) return null;
    if (isRegistered) {
      if (isPresent) return AudienceState.present;
      if (_isFinalizedResult) return AudienceState.absent;
      return AudienceState.registered;
    }
    return isPast ? AudienceState.finished : AudienceState.notRegistered;
  }
}

enum AudienceState {
  present('Hadir'),
  absent('Tidak Hadir'),
  registered('Terdaftar'),
  finished('Selesai'),
  notRegistered('Belum Daftar');

  final String label;
  const AudienceState(this.label);
}

// ─── Seminar detail ─────────────────────────────────────────

class SeminarSupervisor {
  final String? lecturerId;
  final String name;
  final String role;

  const SeminarSupervisor({
    required this.lecturerId,
    required this.name,
    required this.role,
  });
}

class SeminarDetail {
  final String id;
  final String status;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? meetingLink;
  final String? roomName;
  final String thesisTitle;
  final String studentName;
  final String studentNim;
  final List<SeminarSupervisor> supervisors;
  final List<SeminarPerson> examiners;

  /// Set by the backend: true for the presenter, a registered audience
  /// member, lecturers and Admin. Read as false when missing.
  final bool canViewDocuments;

  /// One row per seminar requirement, with its uploaded file if any.
  final List<SeminarDocument> documents;

  const SeminarDetail({
    required this.id,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.meetingLink,
    required this.roomName,
    required this.thesisTitle,
    required this.studentName,
    required this.studentNim,
    required this.supervisors,
    required this.examiners,
    this.canViewDocuments = false,
    this.documents = const [],
  });

  /// Reads both shapes of `GET /thesis-seminars/:id`: the student shape keeps
  /// supervisors under `thesis.supervisors` (with `lecturerName`), the other
  /// roles get top-level `supervisors` (with `lecturerId` and `name`).
  factory SeminarDetail.fromJson(Object? value) {
    final json = _map(value);
    final thesis = _map(json['thesis']);
    final student = _map(json['student']);
    final rawSupervisors = json['supervisors'] is List
        ? _list(json['supervisors'])
        : _list(thesis['supervisors']);
    final rawExaminers = _list(json['examiners']).map(_map).toList()
      ..sort(
        (a, b) => (_int(a['order']) ?? 99).compareTo(_int(b['order']) ?? 99),
      );
    final supervisors = [
      for (final item in rawSupervisors.map(_map))
        SeminarSupervisor(
          lecturerId: _optStr(item['lecturerId']),
          name: _str(item['name'] ?? item['lecturerName']),
          role: _str(item['role']),
        ),
    ]..sort((a, b) => a.role.compareTo(b.role));
    return SeminarDetail(
      id: _str(json['id'], ''),
      status: _str(json['status'], ''),
      date: _date(json['date']),
      startTime: _date(json['startTime']),
      endTime: _date(json['endTime']),
      meetingLink: _optStr(json['meetingLink']),
      roomName: _optStr(_map(json['room'])['name']),
      thesisTitle: _str(thesis['title']),
      studentName: _str(student['name']),
      studentNim: _str(student['nim']),
      supervisors: supervisors,
      examiners: [
        for (final item in rawExaminers)
          SeminarPerson(
            name: _str(item['lecturerName'] ?? item['name']),
            role: 'Penguji ${_int(item['order']) ?? ''}'.trim(),
          ),
      ],
      canViewDocuments: json['canViewDocuments'] == true,
      documents: json['canViewDocuments'] == true
          ? SeminarDocument.listFrom(json)
          : const [],
    );
  }

  /// The attendance list is open for confirmation once the seminar has
  /// started or its result is final (same rule as the web audience panel).
  bool isAttendanceOpen({DateTime? now}) {
    if (status == 'ongoing' || isSeminarResultFinal(status)) return true;
    if (status != 'scheduled') return false;
    final day = wibDay(date);
    final start = startTime?.toUtc();
    if (day == null || start == null) return false;
    final startWib = day.add(
      Duration(hours: start.hour, minutes: start.minute),
    );
    final nowWib = (now ?? DateTime.now()).toUtc().add(wibOffset);
    final nowAsUtc = DateTime.utc(
      nowWib.year,
      nowWib.month,
      nowWib.day,
      nowWib.hour,
      nowWib.minute,
    );
    return !nowAsUtc.isBefore(startWib);
  }

  /// True when [lecturerId] is one of this seminar's supervisors.
  bool isSupervisedBy(String? lecturerId) =>
      lecturerId != null &&
      supervisors.any((item) => item.lecturerId == lecturerId);
}

class SeminarAudience {
  final String? studentId;
  final String name;
  final String nim;
  final bool isPresent;
  final String? approvedByName;
  final DateTime? registeredAt;

  const SeminarAudience({
    required this.studentId,
    required this.name,
    required this.nim,
    required this.isPresent,
    required this.approvedByName,
    required this.registeredAt,
  });

  factory SeminarAudience.fromJson(Object? value) {
    final json = _map(value);
    final approvedBy = _optStr(json['approvedByName']);
    return SeminarAudience(
      studentId: _optStr(json['studentId']),
      name: _str(json['fullName'] ?? json['studentName']),
      nim: _str(json['nim']),
      isPresent: json['approvedAt'] != null,
      approvedByName: approvedBy == '-' ? null : approvedBy,
      registeredAt: _date(json['registeredAt']),
    );
  }
}

// ─── Yudisium announcement ──────────────────────────────────

class YudisiumParticipant {
  final String id;
  final String studentName;
  final String studentNim;
  final String thesisTitle;
  final DateTime? registeredAt;

  const YudisiumParticipant({
    required this.id,
    required this.studentName,
    required this.studentNim,
    required this.thesisTitle,
    required this.registeredAt,
  });
}

class YudisiumAnnouncement {
  final String id;
  final String name;
  final DateTime? eventDate;
  final String? roomName;
  final String? notes;
  final List<YudisiumParticipant> participants;

  const YudisiumAnnouncement({
    required this.id,
    required this.name,
    required this.eventDate,
    required this.roomName,
    required this.notes,
    required this.participants,
  });

  static YudisiumAnnouncement? tryParse(Object? value) {
    final json = _map(value);
    final id = _optStr(json['id']);
    if (id == null) return null;
    final participants = [
      for (final item in _list(json['participants']).map(_map))
        YudisiumParticipant(
          id: _str(item['id'], ''),
          studentName: _str(item['studentName']),
          studentNim: _str(item['studentNim']),
          thesisTitle: _str(item['thesisTitle']),
          registeredAt: _date(item['registeredAt']),
        ),
    ];
    // Registration order, then name (as on web).
    participants.sort((a, b) {
      final aTime = a.registeredAt?.millisecondsSinceEpoch ?? 1 << 62;
      final bTime = b.registeredAt?.millisecondsSinceEpoch ?? 1 << 62;
      if (aTime != bTime) return aTime.compareTo(bTime);
      return a.studentName.compareTo(b.studentName);
    });
    return YudisiumAnnouncement(
      id: id,
      name: _str(json['name']),
      eventDate: _date(json['eventDate']),
      roomName: _optStr(_map(json['room'])['name']),
      notes: _optStr(json['notes']),
      participants: participants,
    );
  }
}

// ─── Seminar documents ──────────────────────────────────────

/// A seminar requirement and its uploaded file (view only).
class SeminarDocument {
  final String requirementId;
  final String name;
  final String? fileName;
  final String? filePath;

  /// `submitted`, `approved` or `declined`; null when nothing is uploaded.
  final String? status;

  const SeminarDocument({
    required this.requirementId,
    required this.name,
    this.fileName,
    this.filePath,
    this.status,
  });

  bool get isUploaded => filePath != null;

  /// Rows as on the web detail page: the requirement list comes from
  /// `documentTypes` (lecturers and Admin) or from the documents themselves
  /// (`requirementName`, students); each row takes its uploaded file.
  static List<SeminarDocument> listFrom(Map<String, dynamic> detail) {
    final docs = _list(detail['documents']).map(_map).toList();
    String? idOf(Map<String, dynamic> d) =>
        _optStr(d['requirementId'] ?? d['documentTypeId']);

    final requirements = <String, String>{};
    for (final type in _list(detail['documentTypes']).map(_map)) {
      final id = _optStr(type['id']);
      if (id != null) requirements[id] = _str(type['name'], 'Dokumen');
    }
    if (requirements.isEmpty) {
      for (final d in docs) {
        final id = idOf(d);
        if (id == null) continue;
        requirements[id] = _str(
          d['requirementName'] ?? d['documentTypeName'],
          'Dokumen',
        );
      }
    }

    return [
      for (final entry in requirements.entries)
        () {
          final doc = docs.firstWhere(
            (d) => idOf(d) == entry.key,
            orElse: () => const {},
          );
          return SeminarDocument(
            requirementId: entry.key,
            name: entry.value,
            fileName: _optStr(doc['fileName']),
            filePath: _optStr(doc['filePath']),
            status: _optStr(doc['status']),
          );
        }(),
    ];
  }
}
