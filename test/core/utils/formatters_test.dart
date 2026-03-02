import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/utils/formatters.dart';

void main() {
  // ─── formatRoleName ───────────────────────────────────────

  group('formatRoleName', () {
    test('converts "pembimbing1" → "Pembimbing 1"', () {
      expect(formatRoleName('pembimbing1'), 'Pembimbing 1');
    });

    test('converts "pembimbing2" → "Pembimbing 2"', () {
      expect(formatRoleName('pembimbing2'), 'Pembimbing 2');
    });

    test('converts "penguji1" → "Penguji 1"', () {
      expect(formatRoleName('penguji1'), 'Penguji 1');
    });

    test('handles already-spaced "pembimbing 1"', () {
      // Should at least capitalize
      expect(formatRoleName('pembimbing 1'), 'Pembimbing 1');
    });

    test('handles unknown role name', () {
      expect(formatRoleName('admin'), 'Admin');
    });

    test('handles empty string', () {
      expect(formatRoleName(''), '');
    });
  });

  // ─── toTitleCase ──────────────────────────────────────────

  group('toTitleCase', () {
    test('capitalizes each word', () {
      expect(toTitleCase('john doe'), 'John Doe');
    });

    test('handles already capitalized', () {
      expect(toTitleCase('John Doe'), 'John Doe');
    });

    test('handles all uppercase', () {
      expect(toTitleCase('JOHN DOE'), 'John Doe');
    });

    test('handles single word', () {
      expect(toTitleCase('john'), 'John');
    });

    test('handles empty string', () {
      expect(toTitleCase(''), '');
    });

    test('handles multiple spaces', () {
      // split(' ') produces empty strings which are preserved
      final result = toTitleCase('john  doe');
      expect(result.contains('John'), true);
      expect(result.contains('Doe'), true);
    });
  });

  // ─── formatDateIndonesian ─────────────────────────────────

  group('formatDateIndonesian', () {
    test('formats Monday correctly', () {
      // 2026-03-02 is a Monday
      final date = DateTime(2026, 3, 2);
      expect(formatDateIndonesian(date), 'Senin, 2 Maret 2026');
    });

    test('formats Sunday correctly', () {
      // 2026-03-01 is a Sunday
      final date = DateTime(2026, 3, 1);
      expect(formatDateIndonesian(date), 'Minggu, 1 Maret 2026');
    });

    test('formats January 1st', () {
      final date = DateTime(2026, 1, 1);
      expect(formatDateIndonesian(date), 'Kamis, 1 Januari 2026');
    });

    test('formats December 31st', () {
      final date = DateTime(2025, 12, 31);
      expect(formatDateIndonesian(date), 'Rabu, 31 Desember 2025');
    });

    test('formats all months correctly', () {
      const expectedMonths = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      for (int m = 1; m <= 12; m++) {
        final date = DateTime(2026, m, 15);
        expect(
          formatDateIndonesian(date),
          contains(expectedMonths[m - 1]),
          reason: 'Month $m should be ${expectedMonths[m - 1]}',
        );
      }
    });
  });

  // ─── formatTime ───────────────────────────────────────────

  group('formatTime', () {
    test('formats single digit hour and minute', () {
      expect(formatTime(const TimeOfDay(hour: 9, minute: 5)), '09:05');
    });

    test('formats midnight', () {
      expect(formatTime(const TimeOfDay(hour: 0, minute: 0)), '00:00');
    });

    test('formats noon', () {
      expect(formatTime(const TimeOfDay(hour: 12, minute: 0)), '12:00');
    });

    test('formats end of day', () {
      expect(formatTime(const TimeOfDay(hour: 23, minute: 59)), '23:59');
    });
  });

  // ─── relativeTime ─────────────────────────────────────────

  group('relativeTime', () {
    test('returns "Baru saja" for recent time (< 60s)', () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      expect(relativeTime(now.toUtc().toIso8601String()), 'Baru saja');
    });

    test('returns minutes for 1–59 min ago', () {
      final time = DateTime.now().subtract(const Duration(minutes: 5));
      expect(relativeTime(time.toUtc().toIso8601String()), '5 mnt lalu');
    });

    test('returns hours for 1–23 hours ago', () {
      final time = DateTime.now().subtract(const Duration(hours: 3));
      expect(relativeTime(time.toUtc().toIso8601String()), '3 jam lalu');
    });

    test('returns days for 1–6 days ago', () {
      final time = DateTime.now().subtract(const Duration(days: 2));
      expect(relativeTime(time.toUtc().toIso8601String()), '2 hari lalu');
    });

    test('returns weeks for 7–29 days ago', () {
      final time = DateTime.now().subtract(const Duration(days: 14));
      expect(relativeTime(time.toUtc().toIso8601String()), '2 mgg lalu');
    });

    test('returns date for 30+ days ago', () {
      final time = DateTime.now().subtract(const Duration(days: 60));
      final result = relativeTime(time.toUtc().toIso8601String());
      // Should be in d/m/yyyy format
      expect(result, matches(RegExp(r'\d+/\d+/\d+')));
    });

    test('returns empty string for invalid ISO string', () {
      expect(relativeTime('not-a-date'), '');
    });

    test('returns empty string for empty string', () {
      expect(relativeTime(''), '');
    });
  });

  // ─── hasTimeConflict ──────────────────────────────────────

  group('hasTimeConflict', () {
    test('returns false when no busy slots', () {
      expect(
        hasTimeConflict(
          requestDate: DateTime(2026, 3, 2),
          requestTime: const TimeOfDay(hour: 10, minute: 0),
          durationMinutes: 60,
          busySlots: [],
        ),
        false,
      );
    });

    test('returns true when request overlaps with busy slot', () {
      // Busy slot: 10:00–11:00 UTC, request: 10:30–11:30 local
      // We need to be careful with UTC/local conversions
      final slotStart = DateTime(2026, 3, 2, 10, 0).toUtc();
      final slotEnd = DateTime(2026, 3, 2, 11, 0).toUtc();

      expect(
        hasTimeConflict(
          requestDate: DateTime(2026, 3, 2),
          requestTime: const TimeOfDay(hour: 10, minute: 30),
          durationMinutes: 60,
          busySlots: [
            {
              'start': slotStart.toIso8601String(),
              'end': slotEnd.toIso8601String(),
            },
          ],
        ),
        true,
      );
    });

    test('returns false when request is before busy slot', () {
      final slotStart = DateTime(2026, 3, 2, 14, 0).toUtc();
      final slotEnd = DateTime(2026, 3, 2, 15, 0).toUtc();

      expect(
        hasTimeConflict(
          requestDate: DateTime(2026, 3, 2),
          requestTime: const TimeOfDay(hour: 8, minute: 0),
          durationMinutes: 60,
          busySlots: [
            {
              'start': slotStart.toIso8601String(),
              'end': slotEnd.toIso8601String(),
            },
          ],
        ),
        false,
      );
    });

    test('returns false when request is after busy slot', () {
      final slotStart = DateTime(2026, 3, 2, 8, 0).toUtc();
      final slotEnd = DateTime(2026, 3, 2, 9, 0).toUtc();

      expect(
        hasTimeConflict(
          requestDate: DateTime(2026, 3, 2),
          requestTime: const TimeOfDay(hour: 10, minute: 0),
          durationMinutes: 60,
          busySlots: [
            {
              'start': slotStart.toIso8601String(),
              'end': slotEnd.toIso8601String(),
            },
          ],
        ),
        false,
      );
    });

    test('returns true for exact overlap', () {
      final slotStart = DateTime(2026, 3, 2, 10, 0).toUtc();
      final slotEnd = DateTime(2026, 3, 2, 11, 0).toUtc();

      expect(
        hasTimeConflict(
          requestDate: DateTime(2026, 3, 2),
          requestTime: const TimeOfDay(hour: 10, minute: 0),
          durationMinutes: 60,
          busySlots: [
            {
              'start': slotStart.toIso8601String(),
              'end': slotEnd.toIso8601String(),
            },
          ],
        ),
        true,
      );
    });

    test('handles invalid slot data gracefully', () {
      expect(
        hasTimeConflict(
          requestDate: DateTime(2026, 3, 2),
          requestTime: const TimeOfDay(hour: 10, minute: 0),
          durationMinutes: 60,
          busySlots: [
            {'start': 'invalid', 'end': 'invalid'},
            {'start': null, 'end': null},
          ],
        ),
        false,
      );
    });

    test('detects conflict with second slot in list', () {
      final slot1Start = DateTime(2026, 3, 2, 8, 0).toUtc();
      final slot1End = DateTime(2026, 3, 2, 9, 0).toUtc();
      final slot2Start = DateTime(2026, 3, 2, 10, 0).toUtc();
      final slot2End = DateTime(2026, 3, 2, 11, 0).toUtc();

      expect(
        hasTimeConflict(
          requestDate: DateTime(2026, 3, 2),
          requestTime: const TimeOfDay(hour: 10, minute: 30),
          durationMinutes: 30,
          busySlots: [
            {
              'start': slot1Start.toIso8601String(),
              'end': slot1End.toIso8601String(),
            },
            {
              'start': slot2Start.toIso8601String(),
              'end': slot2End.toIso8601String(),
            },
          ],
        ),
        true,
      );
    });
  });
}
