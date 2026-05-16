import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/yudisium_api_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';

/// Yudisium — student overview.
///
/// Mirrors `website/src/pages/yudisium/StudentYudisium.tsx` collapsed into a
/// single mobile column:
///   1. Identity card (current yudisium period) — or empty state.
///   2. Status stepper (5-step roadmap based on participantStatus).
///   3. Checklist persyaratan (academic + exit survey).
///   4. Upload Dokumen Yudisium (or preview when no active period).
///   5. CPL scores (collapsible).
///   6. Riwayat percobaan (rejected attempts).
class YudisiumOverviewScreen extends StatefulWidget {
  final UserModel? user;

  const YudisiumOverviewScreen({super.key, this.user});

  @override
  State<YudisiumOverviewScreen> createState() => _YudisiumOverviewScreenState();
}

class _YudisiumOverviewScreenState extends State<YudisiumOverviewScreen> {
  final _api = YudisiumApiService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _overview = const {};
  String? _uploadingRequirementId;

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
      final res = await _api.getStudentYudisiumOverview();
      if (!mounted) return;
      setState(() {
        _overview = res;
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

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.destructive : AppColors.successDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndUpload(Map<String, dynamic> req) async {
    final requirementId = req['id']?.toString();
    if (requirementId == null) return;

    PlatformFile? picked;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      picked = result?.files.firstOrNull;
    } catch (_) {
      try {
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        picked = result?.files.firstOrNull;
      } catch (e) {
        _toast('Gagal memilih file: $e', isError: true);
        return;
      }
    }
    if (picked == null || picked.path == null) return;

    setState(() => _uploadingRequirementId = requirementId);
    try {
      await _api.uploadStudentYudisiumDocument(
        filePath: picked.path!,
        fileName: picked.name,
        requirementId: requirementId,
      );
      _toast('Dokumen berhasil diunggah.');
      await _fetch();
    } catch (e) {
      _toast('Gagal unggah: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingRequirementId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'yudisium'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        12,
        AppSpacing.pagePadding,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Yudisium',
              style: AppTextStyles.h1
                  .copyWith(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }

    final yudisium = _overview['yudisium'] is Map
        ? Map<String, dynamic>.from(_overview['yudisium'] as Map)
        : null;
    final checklist = _overview['checklist'] is Map
        ? Map<String, dynamic>.from(_overview['checklist'] as Map)
        : const <String, dynamic>{};
    final allChecklistMet = _overview['allChecklistMet'] == true;
    final participantStatus = _overview['participantStatus']?.toString();
    final requirements = ((_overview['requirements'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final cplScores = ((_overview['cplScores'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final history = ((_overview['history'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    final displayStatus = yudisium != null
        ? _deriveYudisiumDisplayStatus(yudisium)
        : null;
    final isRegistrationOpen = displayStatus == 'open';
    final activeStep = _activeStepIndex(participantStatus, allChecklistMet);

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (yudisium == null)
            _EmptyPeriodBanner(onReload: _fetch)
          else
            _IdentityCard(
              yudisium: yudisium,
              displayStatus: displayStatus ?? 'draft',
              participantStatus: participantStatus,
            ),
          const SizedBox(height: AppSpacing.base),
          _StatusStepperCard(activeStep: activeStep),
          const SizedBox(height: AppSpacing.base),
          _ChecklistCard(checklist: checklist),
          const SizedBox(height: AppSpacing.base),
          if (yudisium != null &&
              (isRegistrationOpen || participantStatus != null))
            _DocumentsCard(
              allChecklistMet: allChecklistMet,
              participantStatus: participantStatus,
              isRegistrationOpen: isRegistrationOpen,
              requirements: requirements,
              uploadingRequirementId: _uploadingRequirementId,
              onPickFile: _pickAndUpload,
            )
          else
            _RequirementsPreviewCard(requirements: requirements),
          if (cplScores.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            _CplScoresCard(scores: cplScores),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            _HistoryCard(items: history),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  // ─── Derived helpers ─────────────────────────────────────────────

  /// Mirrors `deriveDisplayStatus` from the web component.
  String _deriveYudisiumDisplayStatus(Map<String, dynamic> y) {
    final stored = (y['status'] ?? 'draft').toString();
    final now = DateTime.now();
    final eventDate = _tryParse(y['eventDate']?.toString());
    if (stored == 'completed') return 'completed';
    if (stored == 'scheduled') {
      if (eventDate != null) {
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        if (!eventDate.isBefore(today) && eventDate.isBefore(tomorrow)) {
          return 'ongoing';
        }
        if (eventDate.isBefore(today)) return 'completed';
      }
      return 'scheduled';
    }
    final openDate = _tryParse(y['registrationOpenDate']?.toString());
    final closeDate = _tryParse(y['registrationCloseDate']?.toString());
    if (openDate == null || now.isBefore(openDate)) return 'draft';
    if (closeDate != null && now.isAfter(closeDate)) return 'closed';
    return 'open';
  }

  int _activeStepIndex(String? participantStatus, bool allChecklistMet) {
    switch (participantStatus) {
      case 'finalized':
        return 4;
      case 'appointed':
        return 3;
      case 'cpl_validated':
        return 2;
      case 'verified':
        return 1;
    }
    return allChecklistMet ? 0 : -1;
  }

  static DateTime? _tryParse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// Empty period
// ════════════════════════════════════════════════════════════════

class _EmptyPeriodBanner extends StatelessWidget {
  final VoidCallback onReload;
  const _EmptyPeriodBanner({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_busy_outlined,
                size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada periode yudisium yang dibuka',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 2),
                Text(
                  'Persiapkan persyaratan di bawah ini. Upload dokumen dan '
                  'exit survey akan aktif saat periode dibuka.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 30,
            child: OutlinedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Muat Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Identity card
// ════════════════════════════════════════════════════════════════

class _IdentityCard extends StatelessWidget {
  final Map<String, dynamic> yudisium;
  final String displayStatus;
  final String? participantStatus;

  const _IdentityCard({
    required this.yudisium,
    required this.displayStatus,
    required this.participantStatus,
  });

  @override
  Widget build(BuildContext context) {
    final room = yudisium['room'] is Map
        ? Map<String, dynamic>.from(yudisium['room'] as Map)
        : null;
    final (statusLabel, statusVariant) = _statusBadge(displayStatus);
    final (pLabel, pVariant) = _participantBadge(participantStatus);

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Informasi Yudisium', style: AppTextStyles.label),
              ),
              AppBadge(label: statusLabel, variant: statusVariant),
            ],
          ),
          if (pLabel != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: AppBadge(label: pLabel, variant: pVariant),
            ),
          ],
          const SizedBox(height: 12),
          _InfoBlock(
            icon: Icons.menu_book_outlined,
            label: 'Periode',
            value: (yudisium['name'] ?? '-').toString(),
          ),
          const SizedBox(height: 10),
          _InfoBlock(
            icon: Icons.event_outlined,
            label: 'Rentang Pendaftaran',
            value:
                '${_formatDate(yudisium['registrationOpenDate']?.toString()) ?? '-'} – '
                '${_formatDate(yudisium['registrationCloseDate']?.toString()) ?? '-'}',
          ),
          const SizedBox(height: 10),
          _InfoBlock(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Pelaksanaan',
            value: _formatDate(yudisium['eventDate']?.toString()) ?? '-',
          ),
          if (room != null) ...[
            const SizedBox(height: 10),
            _InfoBlock(
              icon: Icons.place_outlined,
              label: 'Ruangan',
              value: (room['name'] ?? '-').toString(),
            ),
          ],
          if (displayStatus == 'draft') ...[
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.info_outline,
              color: AppColors.warningDark,
              background: AppColors.warningLight,
              text:
                  'Periode yudisium ini belum dibuka untuk pendaftaran. Upload '
                  'dokumen akan diaktifkan saat pendaftaran dibuka.',
            ),
          ],
          if (displayStatus == 'closed') ...[
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.info_outline,
              color: AppColors.textSecondary,
              background: AppColors.surfaceSecondary,
              text: 'Pendaftaran sudah ditutup. Jika Anda belum terdaftar, '
                  'silakan hubungi Koordinator Yudisium.',
            ),
          ],
        ],
      ),
    );
  }

  static (String, BadgeVariant) _statusBadge(String s) {
    switch (s) {
      case 'draft':
        return ('Draft', BadgeVariant.secondary);
      case 'open':
        return ('Pendaftaran Dibuka', BadgeVariant.primary);
      case 'closed':
        return ('Pendaftaran Ditutup', BadgeVariant.warning);
      case 'scheduled':
        return ('Terjadwalkan', BadgeVariant.primary);
      case 'ongoing':
        return ('Sedang Berlangsung', BadgeVariant.warning);
      case 'completed':
        return ('Selesai', BadgeVariant.success);
      default:
        return (s, BadgeVariant.secondary);
    }
  }

  static (String?, BadgeVariant) _participantBadge(String? s) {
    switch (s) {
      case 'registered':
        return ('Menunggu Verifikasi Dokumen', BadgeVariant.warning);
      case 'verified':
        return ('Menunggu Validasi CPL', BadgeVariant.primary);
      case 'cpl_validated':
        return ('Calon Peserta Yudisium', BadgeVariant.primary);
      case 'appointed':
        return ('Peserta Yudisium', BadgeVariant.primary);
      case 'finalized':
        return ('Lulus Yudisium', BadgeVariant.success);
      case 'rejected':
        return ('Tidak Memenuhi Persyaratan', BadgeVariant.destructive);
      default:
        return (null, BadgeVariant.secondary);
    }
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

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
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
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  const _Notice({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Status stepper
// ════════════════════════════════════════════════════════════════

class _StatusStepperCard extends StatelessWidget {
  final int activeStep;
  const _StatusStepperCard({required this.activeStep});

  static const _steps = [
    'Checklist Persyaratan',
    'Dokumen Yudisium Lengkap',
    'Nilai CPL Tervalidasi',
    'Ditetapkan sebagai Peserta Yudisium',
    'Yudisium Selesai',
  ];

  @override
  Widget build(BuildContext context) {
    final progress = activeStep == -1 ? 0 : (activeStep + 1) * 20;
    final completedCount = activeStep + 1;
    final isFinalized = activeStep >= 4;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Status Yudisium', style: AppTextStyles.label),
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
            'Progres pengajuan yudisium Anda',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _steps.length; i++)
            _StepRow(
              label: _steps[i],
              isActive: i <= activeStep,
              isLast: i == _steps.length - 1,
              isConnectorActive: i < activeStep,
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
                : 'Checklist Persyaratan belum terpenuhi',
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
// Checklist
// ════════════════════════════════════════════════════════════════

class _ChecklistCard extends StatelessWidget {
  final Map<String, dynamic> checklist;
  const _ChecklistCard({required this.checklist});

  @override
  Widget build(BuildContext context) {
    // Preserve a stable, business-meaningful order.
    const order = [
      'sks',
      'lulusSidang',
      'revisiSidang',
      'mataKuliahWajib',
      'mataKuliahMkwu',
      'mataKuliahKerjaPraktik',
      'mataKuliahKkn',
      'exitSurvey',
    ];
    final rows = <Widget>[];
    for (final key in order) {
      final raw = checklist[key];
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      rows.add(_ChecklistRow(itemKey: key, item: item));
      rows.add(const SizedBox(height: 6));
    }
    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Belum ada checklist yang dapat ditampilkan.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    } else {
      rows.removeLast();
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Checklist Persyaratan', style: AppTextStyles.label),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String itemKey;
  final Map<String, dynamic> item;
  const _ChecklistRow({required this.itemKey, required this.item});

  @override
  Widget build(BuildContext context) {
    final met = item['met'] == true;
    final current = (item['current'] as num?)?.toInt();
    final required = (item['required'] as num?)?.toInt();
    final hasProgress = current != null && required != null;
    final inProgress = !met && hasProgress && current > 0;
    final statusText = met
        ? 'Terpenuhi'
        : inProgress
            ? '$current/$required'
            : 'Menunggu';
    final label = (item['label'] ?? '-').toString();
    final isExitSurvey = itemKey == 'exitSurvey';
    final canAccessExitSurvey = item['isAvailable'] == true;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          if (isExitSurvey && !met) ...[
            const SizedBox(height: 6),
            Text(
              canAccessExitSurvey
                  ? 'Exit survey dapat diisi melalui aplikasi web NeoCentral.'
                  : 'Exit survey aktif saat pendaftaran yudisium dibuka dan '
                      'persyaratan akademik terpenuhi.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Documents
// ════════════════════════════════════════════════════════════════

class _DocumentsCard extends StatelessWidget {
  final bool allChecklistMet;
  final String? participantStatus;
  final bool isRegistrationOpen;
  final List<Map<String, dynamic>> requirements;
  final String? uploadingRequirementId;
  final Future<void> Function(Map<String, dynamic> req) onPickFile;

  const _DocumentsCard({
    required this.allChecklistMet,
    required this.participantStatus,
    required this.isRegistrationOpen,
    required this.requirements,
    required this.uploadingRequirementId,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    final beyondVerification = const {
      'verified', 'cpl_validated', 'appointed', 'finalized'
    }.contains(participantStatus);
    final checklistLocked = !allChecklistMet && isRegistrationOpen;
    final globalLocked = !allChecklistMet || !isRegistrationOpen;

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Upload Dokumen Yudisium', style: AppTextStyles.label),
          if (checklistLocked && !beyondVerification) ...[
            const SizedBox(height: 10),
            _Notice(
              icon: Icons.lock_outline,
              color: AppColors.warningDark,
              background: AppColors.warningLight,
              text:
                  'Lengkapi checklist persyaratan untuk mengakses fitur upload.',
            ),
          ],
          const SizedBox(height: 10),
          if (requirements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada daftar dokumen persyaratan untuk periode ini.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            for (final req in requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DocumentRow(
                  requirement: req,
                  isLocked: globalLocked || beyondVerification,
                  isUploading:
                      uploadingRequirementId == req['id']?.toString(),
                  onPickFile: () => onPickFile(req),
                ),
              ),
        ],
      ),
    );
  }
}

class _RequirementsPreviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> requirements;
  const _RequirementsPreviewCard({required this.requirements});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Upload Dokumen Yudisium', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'Dokumen-dokumen berikut perlu disiapkan saat pendaftaran dibuka.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          if (requirements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada daftar dokumen persyaratan.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            for (final req in requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: 0.55,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description_outlined,
                              size: 16, color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(req['name'] ?? 'Dokumen').toString()} (PDF)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if ((req['description'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  req['description'].toString(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final Map<String, dynamic> requirement;
  final bool isLocked;
  final bool isUploading;
  final VoidCallback onPickFile;

  const _DocumentRow({
    required this.requirement,
    required this.isLocked,
    required this.isUploading,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    final status = (requirement['status'] ?? '').toString();
    final isUploaded = requirement['isUploaded'] == true ||
        const ['submitted', 'approved', 'declined', 'terunggah']
            .contains(status);
    final isApproved = status == 'approved';
    final isDeclined = status == 'declined';
    final canUpload = !isLocked && !isApproved && !isUploading;
    final name = (requirement['name'] ?? 'Dokumen').toString();
    final description = (requirement['description'] ?? '').toString();

    final (statusText, statusColor) =
        _statusInfo(isApproved, isDeclined, isUploaded, requirement);

    return Opacity(
      opacity: isLocked && !isUploaded ? 0.55 : 1,
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isApproved
                    ? AppColors.successLight
                    : isDeclined
                        ? AppColors.destructiveLight
                        : isUploaded
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
                        : isUploaded
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
                    name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (statusText != null)
                    Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: canUpload ? onPickFile : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        isUploaded
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

  (String?, Color) _statusInfo(
    bool isApproved,
    bool isDeclined,
    bool isUploaded,
    Map<String, dynamic> req,
  ) {
    if (isApproved) return ('✓ Terverifikasi', AppColors.successDark);
    if (isDeclined) {
      final notes = (req['validationNotes'] ?? req['notes'] ?? '').toString();
      return (
        notes.isEmpty ? 'Ditolak' : 'Ditolak: $notes',
        AppColors.destructiveDark,
      );
    }
    if (isUploaded) {
      return ('Menunggu verifikasi', AppColors.warningDark);
    }
    return (null, AppColors.textSecondary);
  }
}

// ════════════════════════════════════════════════════════════════
// CPL scores card (collapsible)
// ════════════════════════════════════════════════════════════════

class _CplScoresCard extends StatefulWidget {
  final List<Map<String, dynamic>> scores;
  const _CplScoresCard({required this.scores});

  @override
  State<_CplScoresCard> createState() => _CplScoresCardState();
}

class _CplScoresCardState extends State<_CplScoresCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scores = widget.scores;
    final passed = scores.where((s) => s['passed'] == true).length;
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nilai CPL', style: AppTextStyles.label),
                        const SizedBox(height: 2),
                        Text(
                          '$passed / ${scores.length} CPL tercapai',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: AppColors.divider),
            for (var i = 0; i < scores.length; i++) ...[
              if (i > 0) Container(height: 1, color: AppColors.divider),
              _CplRow(score: scores[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _CplRow extends StatelessWidget {
  final Map<String, dynamic> score;
  const _CplRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final code = (score['code'] ?? '-').toString();
    final description = (score['description'] ?? '-').toString();
    final scoreValue = score['score'];
    final minimal = score['minimalScore'];
    final passed = score['passed'] == true;
    final validatedBy =
        (score['validatedBy'] ?? score['verifiedBy'] ?? '').toString();
    final validatedAt =
        (score['validatedAt'] ?? score['verifiedAt'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  code,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              AppBadge(
                label: passed ? 'Tercapai' : 'Belum Tercapai',
                variant:
                    passed ? BadgeVariant.success : BadgeVariant.destructive,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Nilai: ',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                scoreValue == null ? '-' : scoreValue.toString(),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Min: ${minimal ?? '-'}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          if (validatedBy.isNotEmpty || validatedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined,
                    size: 13, color: AppColors.successDark),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    validatedBy.isNotEmpty
                        ? '$validatedBy${validatedAt.isNotEmpty ? ' • ${_formatDate(validatedAt)}' : ''}'
                        : 'Terverifikasi${validatedAt.isNotEmpty ? ' • ${_formatDate(validatedAt)}' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.successDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// History card (rejected attempts)
// ════════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _HistoryCard({required this.items});

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
                '${items.length} pendaftaran sebelumnya',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _HistoryRow(index: i + 1, item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  const _HistoryRow({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  (item['yudisiumName'] ?? '-').toString(),
                  style: AppTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const AppBadge(
                label: 'Tidak Memenuhi',
                variant: BadgeVariant.destructive,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _KvRow(
            label: 'Pendaftaran',
            value:
                '${_formatDate(item['registrationOpenDate']?.toString()) ?? '-'} – '
                '${_formatDate(item['registrationCloseDate']?.toString()) ?? '-'}',
          ),
          _KvRow(
            label: 'Pelaksanaan',
            value: _formatDate(item['eventDate']?.toString()) ?? '-',
          ),
          _KvRow(
            label: 'Tgl. Daftar',
            value: _formatDate(item['createdAt']?.toString()) ?? '-',
          ),
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
}

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  const _KvRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
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
            Text('Gagal memuat yudisium',
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
