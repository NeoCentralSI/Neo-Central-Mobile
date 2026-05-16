import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../seminar_detail_screen.dart' show seminarStatusLabel, seminarStatusVariant;

/// Ringkasan panel for the student Seminar Hasil screen.
///
/// Stacks these cards vertically (mobile-first layout):
///   1. Identity (when a current seminar exists and is past-examiner-assignment)
///   2. Status stepper (5 milestone roadmap)
///   3. Checklist Persyaratan (4 prerequisites)
///   4. Upload Dokumen Seminar (per documentType slot)
///   5. Riwayat Percobaan (failed / cancelled attempts)
class StudentSeminarOverviewPanel extends StatefulWidget {
  final UserModel? user;
  final void Function(String seminarId) onSeminarTap;

  const StudentSeminarOverviewPanel({
    super.key,
    required this.onSeminarTap,
    this.user,
  });

  @override
  State<StudentSeminarOverviewPanel> createState() =>
      _StudentSeminarOverviewPanelState();
}

class _StudentSeminarOverviewPanelState
    extends State<StudentSeminarOverviewPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _overview = const {};
  List<Map<String, dynamic>> _history = const [];
  List<Map<String, dynamic>> _docTypes = const [];

  String? _uploadingDocType;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getStudentOverview(),
        _api.getStudentSeminarHistory(),
        _api.getSeminarDocumentTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _history = results[1] as List<Map<String, dynamic>>;
        _docTypes = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload(Map<String, dynamic> docType) async {
    final docTypeName = (docType['name'] ?? '').toString();
    if (docTypeName.isEmpty) return;
    final accept = ((docType['accept'] as List?) ?? const [])
        .map((e) => e.toString().replaceFirst('.', '').toLowerCase())
        .toList();

    PlatformFile? picked;
    try {
      final result = accept.isNotEmpty
          ? await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: accept,
            )
          : await FilePicker.platform.pickFiles(type: FileType.any);
      picked = result?.files.firstOrNull;
    } catch (_) {
      try {
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        picked = result?.files.firstOrNull;
      } catch (e) {
        if (!mounted) return;
        _toast('Gagal memilih file: $e', isError: true);
        return;
      }
    }

    if (picked == null || picked.path == null) return;

    final seminarId = _overview['seminar']?['id']?.toString();
    if (seminarId == null) {
      _toast('Seminar belum terdaftar.', isError: true);
      return;
    }

    setState(() => _uploadingDocType = docTypeName);
    try {
      await _api.uploadStudentDocument(
        seminarId,
        filePath: picked.path!,
        fileName: picked.name,
        documentTypeName: docTypeName,
      );
      if (!mounted) return;
      _toast('Dokumen berhasil diunggah.');
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal unggah: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingDocType = null);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.destructive : AppColors.successDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }

    final seminar = _overview['seminar'] is Map
        ? Map<String, dynamic>.from(_overview['seminar'] as Map)
        : null;
    final checklist = _overview['checklist'] is Map
        ? Map<String, dynamic>.from(_overview['checklist'] as Map)
        : const <String, dynamic>{};
    final allChecklistMet = _overview['allChecklistMet'] == true;
    final currentId = seminar?['id']?.toString();
    final historyItems =
        _history.where((it) => it['id']?.toString() != currentId).toList();

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (seminar != null && _isIdentityVisible(seminar)) ...[
            _IdentityCard(
              seminar: seminar,
              onTap: () => widget.onSeminarTap(seminar['id'].toString()),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          _StatusStepperCard(
            status: seminar?['status']?.toString(),
            allChecklistMet: allChecklistMet,
          ),
          const SizedBox(height: AppSpacing.base),
          _ChecklistCard(checklist: checklist),
          const SizedBox(height: AppSpacing.base),
          _DocumentsCard(
            allChecklistMet: allChecklistMet,
            seminarStatus: seminar?['status']?.toString(),
            docTypes: _docTypes,
            documents: ((seminar?['documents'] as List?) ?? const [])
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList(),
            uploadingDocType: _uploadingDocType,
            onPickFile: _pickAndUpload,
          ),
          if (historyItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            _HistoryCard(
              items: historyItems,
              onTap: (id) => widget.onSeminarTap(id),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  bool _isIdentityVisible(Map<String, dynamic> seminar) {
    const visibleStatuses = [
      'examiner_assigned',
      'scheduled',
      'ongoing',
      'passed',
      'passed_with_revision',
    ];
    return visibleStatuses.contains((seminar['status'] ?? '').toString());
  }
}

// ════════════════════════════════════════════════════════════════
// Identity card
// ════════════════════════════════════════════════════════════════

class _IdentityCard extends StatelessWidget {
  final Map<String, dynamic> seminar;
  final VoidCallback onTap;
  const _IdentityCard({required this.seminar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = (seminar['status'] ?? '').toString();
    final examiners = ((seminar['examiners'] as List?) ?? const [])
        .whereType<Map>()
        .where((e) => (e['availabilityStatus'] ?? '').toString() == 'available')
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final showSchedule = const [
      'scheduled',
      'ongoing',
      'passed',
      'passed_with_revision',
      'failed',
    ].contains(status);
    final showScore = const ['passed', 'passed_with_revision', 'failed']
            .contains(status) &&
        seminar['finalScore'] != null;
    final room = seminar['room'] is Map
        ? Map<String, dynamic>.from(seminar['room'] as Map)
        : null;
    final isOnline =
        room == null && (seminar['meetingLink'] ?? '').toString().isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Informasi Seminar', style: AppTextStyles.label),
              ),
              AppBadge(
                label: seminarStatusLabel(status),
                variant: seminarStatusVariant(status),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: 12),
          if (examiners.isNotEmpty)
            _InfoBlock(
              icon: Icons.people_outline,
              label: 'Dosen Penguji',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in examiners)
                    Text(
                      (e['lecturerName'] ?? '-').toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          if (showSchedule && (seminar['date'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoBlock(
              icon: Icons.calendar_today_outlined,
              label: 'Jadwal',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(seminar['date']?.toString()) ?? '-',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatTimeRange(
                      seminar['startTime']?.toString(),
                      seminar['endTime']?.toString(),
                    ),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          if (showSchedule && (room != null || isOnline)) ...[
            const SizedBox(height: 10),
            _InfoBlock(
              icon: isOnline ? Icons.videocam_outlined : Icons.place_outlined,
              label: isOnline ? 'Mode Seminar' : 'Ruangan',
              child: isOnline
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Daring',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.infoDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      (room?['name'] ?? '-').toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
          ],
          if (showScore) ...[
            const SizedBox(height: 10),
            _InfoBlock(
              icon: Icons.emoji_events_outlined,
              label: 'Nilai Akhir',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    (seminar['finalScore'] as num).toStringAsFixed(2),
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${seminar['maxWeight'] ?? 100}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if ((seminar['grade'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        seminar['grade'].toString(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return null;
    }
  }

  static String _formatTimeRange(String? startIso, String? endIso) {
    final s = _extract(startIso);
    final e = _extract(endIso);
    if (s == null && e == null) return '';
    if (e == null) return '$s WIB';
    return '$s – $e WIB';
  }

  static String? _extract(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso);
      return '${d.toUtc().hour.toString().padLeft(2, '0')}.'
          '${d.toUtc().minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Status stepper (roadmap)
// ════════════════════════════════════════════════════════════════

class _StatusStepperCard extends StatelessWidget {
  final String? status;
  final bool allChecklistMet;
  const _StatusStepperCard({
    required this.status,
    required this.allChecklistMet,
  });

  static const _steps = [
    'Checklist Persyaratan',
    'Dokumen Seminar Lengkap',
    'Penetapan Dosen Penguji',
    'Penetapan Jadwal Seminar',
    'Pelaksanaan Seminar Hasil',
  ];

  int _activeIndex() {
    final s = status;
    if (s == 'passed' || s == 'passed_with_revision') return 4;
    if (s == 'scheduled' || s == 'ongoing') return 3;
    if (s == 'examiner_assigned') return 2;
    if (s == 'verified') return 1;
    if (s == 'registered') return 0;
    if (allChecklistMet) return 0;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex();
    final completedCount = activeIndex + 1;
    final progress = activeIndex == -1 ? 0 : (activeIndex + 1) * 20;
    final isFinalized = status == 'passed' || status == 'passed_with_revision';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Status Seminar', style: AppTextStyles.label),
              ),
              if (isFinalized)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.celebration_outlined,
                          size: 12, color: AppColors.successDark),
                      const SizedBox(width: 4),
                      Text(
                        'Selesai',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Progres pengajuan seminar hasil',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _steps.length; i++)
            _StepRow(
              label: _steps[i],
              isActive: i <= activeIndex,
              isLast: i == _steps.length - 1,
              isConnectorActive: i < activeIndex,
            ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progres Keseluruhan',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$progress%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.successDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.successDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completedCount > 0
                ? '$completedCount dari ${_steps.length} tahap selesai'
                : 'Checklist persyaratan belum terpenuhi',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLast;
  final bool isConnectorActive;
  const _StepRow({
    required this.label,
    required this.isActive,
    required this.isLast,
    required this.isConnectorActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.successDark : AppColors.textTertiary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.successDark : AppColors.surface,
                    border: Border.all(
                      color:
                          isActive ? AppColors.successDark : AppColors.divider,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.check : Icons.schedule,
                    size: 11,
                    color: isActive ? Colors.white : AppColors.textTertiary,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isConnectorActive
                          ? AppColors.successDark
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive ? 'Terpenuhi' : 'Menunggu',
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Checklist persyaratan
// ════════════════════════════════════════════════════════════════

class _ChecklistCard extends StatelessWidget {
  final Map<String, dynamic> checklist;
  const _ChecklistCard({required this.checklist});

  @override
  Widget build(BuildContext context) {
    final metopen = checklist['metopen'] is Map
        ? Map<String, dynamic>.from(checklist['metopen'] as Map)
        : const <String, dynamic>{};
    final bimbingan = checklist['bimbingan'] is Map
        ? Map<String, dynamic>.from(checklist['bimbingan'] as Map)
        : const <String, dynamic>{};
    final kehadiran = checklist['kehadiran'] is Map
        ? Map<String, dynamic>.from(checklist['kehadiran'] as Map)
        : const <String, dynamic>{};
    final pembimbing = checklist['pembimbing'] is Map
        ? Map<String, dynamic>.from(checklist['pembimbing'] as Map)
        : const <String, dynamic>{};
    final supervisors = ((pembimbing['supervisors'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Checklist Persyaratan', style: AppTextStyles.label),
          const SizedBox(height: 12),
          _ChecklistRow(
            label: (metopen['label'] ?? 'Lulus Mata Kuliah Metode Penelitian')
                .toString(),
            met: metopen['met'] == true,
          ),
          const SizedBox(height: 6),
          _ChecklistRow(
            label: (bimbingan['label'] ?? '-').toString(),
            met: bimbingan['met'] == true,
            current: (bimbingan['current'] as num?)?.toInt(),
            required: (bimbingan['required'] as num?)?.toInt(),
          ),
          const SizedBox(height: 6),
          _ChecklistRow(
            label: (kehadiran['label'] ?? '-').toString(),
            met: kehadiran['met'] == true,
            current: (kehadiran['current'] as num?)?.toInt(),
            required: (kehadiran['required'] as num?)?.toInt(),
          ),
          const SizedBox(height: 6),
          _ChecklistRow(
            label: (pembimbing['label'] ?? '-').toString(),
            met: pembimbing['met'] == true,
            supervisors: supervisors,
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final bool met;
  final int? current;
  final int? required;
  final List<Map<String, dynamic>>? supervisors;

  const _ChecklistRow({
    required this.label,
    required this.met,
    this.current,
    this.required,
    this.supervisors,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = current != null && required != null;
    final inProgress = !met && hasProgress && (current ?? 0) > 0;
    final statusText = met
        ? 'Terpenuhi'
        : inProgress
            ? '$current/$required'
            : 'Menunggu';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: met
            ? AppColors.successLight.withValues(alpha: 0.5)
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: met
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: met ? AppColors.successDark : AppColors.surface,
                  border: Border.all(
                    color: met ? AppColors.successDark : AppColors.divider,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  met ? Icons.check : Icons.schedule,
                  size: 11,
                  color: met ? Colors.white : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: met
                            ? AppColors.successDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (supervisors != null && supervisors!.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final s in supervisors!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      s['ready'] == true
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: s['ready'] == true
                          ? AppColors.successDark
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${s['role'] ?? '-'} · ${s['name'] ?? '-'}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Document upload card
// ════════════════════════════════════════════════════════════════

class _DocumentsCard extends StatelessWidget {
  final bool allChecklistMet;
  final String? seminarStatus;
  final List<Map<String, dynamic>> docTypes;
  final List<Map<String, dynamic>> documents;
  final String? uploadingDocType;
  final Future<void> Function(Map<String, dynamic> docType) onPickFile;

  const _DocumentsCard({
    required this.allChecklistMet,
    required this.seminarStatus,
    required this.docTypes,
    required this.documents,
    required this.uploadingDocType,
    required this.onPickFile,
  });

  bool get _isLocked => !allChecklistMet;

  @override
  Widget build(BuildContext context) {
    final showLockNotice = _isLocked && documents.isEmpty;
    final pastRegistered = seminarStatus != null && seminarStatus != 'registered';

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Upload Dokumen Seminar', style: AppTextStyles.label),
          if (showLockNotice) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: AppColors.warningDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lengkapi checklist persyaratan untuk mengakses fitur upload.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warningDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (pastRegistered) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.infoDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pendaftaran telah diverifikasi; perubahan dokumen tidak diizinkan.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.infoDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (final dt in docTypes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DocumentRow(
                docType: dt,
                doc: _findDoc(dt['id']?.toString()),
                isLocked: _isLocked || pastRegistered,
                isUploading: uploadingDocType == (dt['name'] ?? '').toString(),
                onPickFile: () => onPickFile(dt),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findDoc(String? docTypeId) {
    if (docTypeId == null) return null;
    for (final d in documents) {
      if (d['documentTypeId']?.toString() == docTypeId) return d;
    }
    return null;
  }
}

class _DocumentRow extends StatelessWidget {
  final Map<String, dynamic> docType;
  final Map<String, dynamic>? doc;
  final bool isLocked;
  final bool isUploading;
  final VoidCallback onPickFile;

  const _DocumentRow({
    required this.docType,
    required this.doc,
    required this.isLocked,
    required this.isUploading,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = doc != null;
    final status = (doc?['status'] ?? '').toString();
    final isApproved = status == 'approved';
    final isDeclined = status == 'declined';
    final canUpload = !isLocked && !isApproved && !isUploading;
    final label = (docType['label'] ?? docType['name'] ?? 'Dokumen').toString();

    final (statusText, statusColor) = _statusInfo(isApproved, isDeclined, doc);

    return Opacity(
      opacity: isLocked && !uploaded ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isApproved
                    ? AppColors.successLight
                    : isDeclined
                        ? AppColors.destructiveLight
                        : uploaded
                            ? AppColors.infoLight
                            : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 16,
                color: isApproved
                    ? AppColors.successDark
                    : isDeclined
                        ? AppColors.destructiveDark
                        : uploaded
                            ? AppColors.infoDark
                            : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (uploaded) ...[
                    Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((doc!['fileName'] ?? '').toString().isNotEmpty)
                      Text(
                        doc!['fileName'].toString(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: isUploading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: canUpload ? onPickFile : null,
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: isDeclined
                            ? AppColors.destructiveDark
                            : AppColors.primaryDark,
                        side: BorderSide(
                          color: isDeclined
                              ? AppColors.destructive.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        uploaded
                            ? (isDeclined ? 'Upload Ulang' : 'Ganti')
                            : 'Upload',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(
      bool isApproved, bool isDeclined, Map<String, dynamic>? doc) {
    if (isApproved) return ('✓ Terverifikasi', AppColors.successDark);
    if (isDeclined) {
      final notes = (doc?['notes'] ?? '').toString();
      return (
        notes.isEmpty ? 'Ditolak' : 'Ditolak: $notes',
        AppColors.destructiveDark,
      );
    }
    return ('Menunggu verifikasi', AppColors.warningDark);
  }
}

// ════════════════════════════════════════════════════════════════
// History card (failed/cancelled attempts)
// ════════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String id) onTap;
  const _HistoryCard({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Riwayat Percobaan', style: AppTextStyles.label)),
              Text(
                '${items.length} percobaan sebelumnya',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            _HistoryRow(
              index: i + 1,
              item: items[i],
              onTap: () => onTap(items[i]['id'].toString()),
            ),
            if (i < items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _HistoryRow({
    required this.index,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final examiners = ((item['examiners'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final status = (item['status'] ?? '-').toString();
    final score = item['finalScore'];
    final room = item['room'] is Map
        ? Map<String, dynamic>.from(item['room'] as Map)
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$index',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Percobaan #$index',
                    style: AppTextStyles.label,
                  ),
                ),
                AppBadge(
                  label: seminarStatusLabel(status),
                  variant: seminarStatusVariant(status),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (examiners.isNotEmpty) ...[
              Text(
                'Penguji',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              for (final e in examiners)
                Text(
                  (e['lecturerName'] ?? '-').toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(item['date']?.toString()) ?? '-',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ruangan',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        room?['name']?.toString() ?? '-',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Nilai',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      score is num ? score.toStringAsFixed(2) : '-',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return null;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// Error view
// ════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.destructive),
            const SizedBox(height: 12),
            Text('Gagal memuat data',
                style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
