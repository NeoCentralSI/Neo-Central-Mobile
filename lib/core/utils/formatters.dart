import 'package:flutter/material.dart';

/// Pure formatting utilities extracted from screens for testability.

/// Formats a role string like "pembimbing1" → "Pembimbing 1".
String formatRoleName(String role) {
  return role
      .replaceAllMapped(
        RegExp(r'(pembimbing|penguji)(\d+)', caseSensitive: false),
        (m) => '${m[1]} ${m[2]}',
      )
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
      .join(' ');
}

/// Converts a name to title case: "john doe" → "John Doe".
String toTitleCase(String name) {
  return name
      .toLowerCase()
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
      .join(' ');
}

/// Formats a [DateTime] to Indonesian locale: "Senin, 3 Maret 2026".
String formatDateIndonesian(DateTime date) {
  const days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  final dayName = days[date.weekday - 1];
  final monthName = months[date.month - 1];
  return '$dayName, ${date.day} $monthName ${date.year}';
}

/// Formats a [TimeOfDay] to "HH:mm".
String formatTime(TimeOfDay t) {
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Returns a human-readable relative time string in Indonesian.
String relativeTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} mgg lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '';
  }
}

/// Checks if a requested time slot overlaps with any busy slots.
///
/// [requestDate] and [requestTime] define the start.
/// [durationMinutes] defines the length.
/// [busySlots] is a list of maps with 'start' and 'end' ISO strings.
bool hasTimeConflict({
  required DateTime requestDate,
  required TimeOfDay requestTime,
  required int durationMinutes,
  required List<Map<String, dynamic>> busySlots,
}) {
  final requestStart = DateTime(
    requestDate.year,
    requestDate.month,
    requestDate.day,
    requestTime.hour,
    requestTime.minute,
  );
  final requestEnd = requestStart.add(Duration(minutes: durationMinutes));

  for (final slot in busySlots) {
    final slotStart = DateTime.tryParse(slot['start'] ?? '');
    final slotEnd = DateTime.tryParse(slot['end'] ?? '');
    if (slotStart == null || slotEnd == null) continue;

    final localStart = slotStart.toLocal();
    final localEnd = slotEnd.toLocal();

    // Overlap check
    if (requestStart.isBefore(localEnd) && requestEnd.isAfter(localStart)) {
      return true;
    }
  }
  return false;
}
