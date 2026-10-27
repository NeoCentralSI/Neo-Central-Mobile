/// Indonesian labels for thesis enum values sent by the backend.
///
/// The API sends enum values; the app labels them here, following the web app
/// (`website/src/lib/thesisLabels.ts`). Unknown values show "-" rather than the
/// raw enum.
library;

/// Thesis status (`proposal`, `research`, `completed`, `failed`).
const Map<String, String> thesisStatusLabels = {
  'proposal': 'Proposal',
  'research': 'Penelitian',
  'completed': 'Selesai',
  'failed': 'Gagal',
};

/// Phase of a guidance session or milestone, shown as the "Jenis" badge.
const Map<String, String> thesisPhaseLabels = {
  'proposal': 'Proposal',
  'research': 'Tugas Akhir',
};

/// Guidance session status (`GuidanceStatus`).
const Map<String, String> guidanceStatusLabels = {
  'requested': 'Menunggu Persetujuan',
  'accepted': 'Terjadwal',
  'rescheduled': 'Terjadwal',
  'rejected': 'Ditolak',
  'summary_pending': 'Menunggu Persetujuan Ringkasan',
  'summary_rejected': 'Ringkasan Perlu Diperbaiki',
  'completed': 'Selesai',
  'cancelled': 'Dibatalkan',
  'deleted': 'Dihapus',
};

/// Milestone status (`MilestoneStatus`).
const Map<String, String> milestoneStatusLabels = {
  'not_started': 'Belum Dimulai',
  'in_progress': 'Sedang Dikerjakan',
  'pending_review': 'Menunggu Review',
  'revision_needed': 'Perlu Revisi',
  'completed': 'Selesai',
  'deleted': 'Dihapus',
};

String _labelOf(Map<String, String> labels, Object? value) {
  final key = value?.toString();
  if (key == null || key.isEmpty) return '-';
  return labels[key] ?? '-';
}

String thesisStatusLabel(Object? value) => _labelOf(thesisStatusLabels, value);

String thesisPhaseLabel(Object? value) => _labelOf(thesisPhaseLabels, value);

String guidanceStatusLabel(Object? value) =>
    _labelOf(guidanceStatusLabels, value);

String milestoneStatusLabel(Object? value) =>
    _labelOf(milestoneStatusLabels, value);

/// True for a phase value the app knows how to label.
bool isKnownThesisPhase(Object? value) =>
    thesisPhaseLabels.containsKey(value?.toString());
