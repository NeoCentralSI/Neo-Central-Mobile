import 'package:flutter/material.dart';

import '../enums/user_role.dart';

/// Where tapping a notification leads on mobile.
///
/// The backend still sends pushes for every module (Seminar, Sidang, Yudisium,
/// Proposal, ...). Only modules that exist on mobile get their own screen;
/// everything else, including unknown or missing types, opens the
/// notification list so a tap can never point at a removed screen.
enum NotificationDestination {
  /// The Notifikasi list (fallback).
  notificationList,

  /// Pengumuman (Seminar Hasil board).
  announcements,

  /// Student: Riwayat Bimbingan.
  studentGuidance,

  /// Student: Milestone.
  studentMilestones,

  /// Lecturer: Approval Bimbingan ▸ Permintaan.
  lecturerGuidanceRequests,

  /// Lecturer: Approval Bimbingan ▸ Catatan (session summaries).
  lecturerGuidanceSummaries,

  /// Lecturer: Approval Bimbingan ▸ Milestone.
  lecturerMilestones,

  /// Kerja Praktik.
  internship,
}

/// Guidance notifications a lecturer acts on in the request list.
const _lecturerRequestTypes = {
  'thesis-guidance:requested',
  'thesis-guidance:rescheduled',
  'thesis-guidance:cancelled',
  'thesis-guidance:notes-updated',
};

/// Thesis notifications a student reads in the guidance history.
const _studentGuidanceTypes = {
  'guidance_reminder',
  'daily_thesis_reminder',
  'thesis_warning',
};

/// Reads the notification type from an FCM payload or an in-app item, where
/// it may sit at the top level or inside `data`.
String? notificationTypeOf(Map<String, dynamic>? payload) {
  if (payload == null) return null;
  final direct = payload['type'];
  if (direct is String && direct.trim().isNotEmpty) return direct.trim();
  final data = payload['data'];
  if (data is Map) {
    final nested = data['type'];
    if (nested is String && nested.trim().isNotEmpty) return nested.trim();
  }
  return null;
}

/// Resolves a notification type into a mobile destination for [role].
NotificationDestination resolveNotificationDestination({
  required String? type,
  required UserRole role,
}) {
  final value = type?.trim() ?? '';
  if (value.isEmpty) return NotificationDestination.notificationList;

  // The announcement board is open to every role.
  if (value == 'seminar_scheduled') {
    return NotificationDestination.announcements;
  }

  switch (role) {
    case UserRole.admin:
      // Admin on mobile has only Pengumuman and Notifikasi.
      return NotificationDestination.notificationList;

    case UserRole.student:
      if (value.startsWith('thesis-guidance:') ||
          _studentGuidanceTypes.contains(value)) {
        return NotificationDestination.studentGuidance;
      }
      if (value.startsWith('milestone')) {
        return NotificationDestination.studentMilestones;
      }
      if (_isInternship(value)) return NotificationDestination.internship;
      return NotificationDestination.notificationList;

    case UserRole.lecturer:
      if (_lecturerRequestTypes.contains(value)) {
        return NotificationDestination.lecturerGuidanceRequests;
      }
      if (value == 'thesis-guidance:summary-submitted') {
        return NotificationDestination.lecturerGuidanceSummaries;
      }
      if (value.startsWith('milestone')) {
        return NotificationDestination.lecturerMilestones;
      }
      if (_isInternship(value)) return NotificationDestination.internship;
      return NotificationDestination.notificationList;
  }
}

bool _isInternship(String type) => type.startsWith('internship_');

/// Maps a notification type to a Material icon.
IconData notificationIconData(String? type) {
  final value = type ?? '';
  if (value.startsWith('thesis-guidance:') ||
      value == 'guidance_reminder' ||
      value == 'daily_thesis_reminder') {
    return Icons.calendar_today_outlined;
  }
  if (value.startsWith('milestone')) return Icons.flag_outlined;
  if (value == 'thesis_warning') return Icons.warning_amber_outlined;
  if (value.startsWith('internship_')) return Icons.work_outline;
  if (value == 'seminar_scheduled') return Icons.campaign_outlined;
  if (value.startsWith('seminar') ||
      value.startsWith('thesis_seminar') ||
      value.startsWith('defence') ||
      value.startsWith('thesis_defence')) {
    return Icons.event_available_outlined;
  }
  if (value.startsWith('yudisium')) return Icons.emoji_events_outlined;
  if (value.startsWith('supervisor') ||
      value.startsWith('proposal') ||
      value.startsWith('final_proposal')) {
    return Icons.person_add_outlined;
  }
  return Icons.notifications_outlined;
}
