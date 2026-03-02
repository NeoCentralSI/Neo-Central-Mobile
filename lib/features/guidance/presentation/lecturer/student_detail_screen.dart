import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/lecturer_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Per-student detail screen for lecturers
class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _api = LecturerApiService();

  bool _isLoadingMilestones = true;
  bool _isLoadingHistory = true;
  List<dynamic> _milestoneComponents = [];
  List<dynamic> _guidanceHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final thesisId = (widget.student['thesisId'] ?? '').toString();
    if (thesisId.isEmpty) return;

    // Fetch detail (milestones + guidanceHistory) via single call to my-students/:thesisId
    try {
      final detailData = await _api.getStudentDetail(thesisId);
      if (!mounted) return;
      setState(() {
        if (detailData.containsKey('milestones')) {
          _milestoneComponents = detailData['milestones'] as List<dynamic>;
        }
        // Extract guidance history from the same response
        if (detailData.containsKey('guidanceHistory')) {
          final gh = detailData['guidanceHistory'];
          if (gh is Map && gh.containsKey('items') && gh['items'] is List) {
            _guidanceHistory = gh['items'] as List<dynamic>;
          } else if (gh is List) {
            _guidanceHistory = gh;
          }
        }
              _isLoadingMilestones = false;
        _isLoadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMilestones = false;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final milestoneRaw =
        widget.student['milestoneProgress'] ?? widget.student['milestone'] ?? 0;
    final double milestone = milestoneRaw is int
        ? milestoneRaw / 100
        : (milestoneRaw is double ? milestoneRaw : 0.0);
    final int guidance =
        (widget.student['completedGuidanceCount'] ?? widget.student['guidance'] ?? 0) is int
        ? (widget.student['completedGuidanceCount'] ?? widget.student['guidance'] ?? 0) as int
        : 0;

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: Column(
        children: [
          // ── Orange gradient header ──────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight,
                  AppColors.primary,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 20, color: AppColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Detail Mahasiswa',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Content ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryCard(
                          student: widget.student,
                          milestone: milestone,
                          guidance: guidance,
                        ),
                        const Divider(
                          color: AppColors.surfaceSecondary,
                          thickness: 8,
                          height: 8,
                        ),
                        _SeminarReadinessCard(
                          milestone: milestone,
                          guidance: guidance,
                        ),
                        const Divider(
                          color: AppColors.surfaceSecondary,
                          thickness: 8,
                          height: 8,
                        ),
                        _MilestoneSection(
                          isLoading: _isLoadingMilestones,
                          components: _milestoneComponents,
                        ),
                        const Divider(
                          color: AppColors.surfaceSecondary,
                          thickness: 8,
                          height: 8,
                        ),
                        _GuidanceHistorySection(
                          isLoading: _isLoadingHistory,
                          sessions: _guidanceHistory,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final double milestone;
  final int guidance;

  const _SummaryCard({
    required this.student,
    required this.milestone,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  ((student['fullName'] ?? student['name'] ?? '?') as String)
                      .substring(0, 1),
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (student['fullName'] ?? student['name'] ?? '-')
                          .toString(),
                      style: AppTextStyles.h4,
                    ),
                    Text(
                      (student['identityNumber'] ?? student['nim'] ?? '-')
                          .toString(),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              AppBadge(label: 'Aktif', variant: BadgeVariant.success),
            ],
          ),
          const AppDivider(),
          Text(
            (student['thesisTitle'] ?? student['thesis'] ?? '-').toString(),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Milestone', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    AppProgressBar(value: milestone, height: 8),
                    const SizedBox(height: 4),
                    Text(
                      '${(milestone * 100).round()}%',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Bimbingan', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    '$guidance / 8',
                    style: AppTextStyles.h3.copyWith(
                      color: guidance >= 8
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  Text('sesi selesai', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Seminar Readiness Card ───────────────────────────────────
class _SeminarReadinessCard extends StatelessWidget {
  final double milestone;
  final int guidance;

  const _SeminarReadinessCard({
    required this.milestone,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = milestone >= 1.0 && guidance >= 8;
    final isMilestoneOnly = milestone >= 1.0 && guidance < 8;

    final Color backColor = isReady
        ? AppColors.successLight
        : (isMilestoneOnly ? AppColors.warningLight : Colors.white);
    final Color iconColor = isReady
        ? AppColors.success
        : (isMilestoneOnly ? AppColors.warning : AppColors.textSecondary);
    final String statusText = isReady
        ? 'Semua syarat terpenuhi – dapat approval seminar'
        : isMilestoneOnly
        ? 'Milestone selesai, namun bimbingan belum cukup ($guidance/8)'
        : 'Belum memenuhi syarat kesiapan seminar';

    return Container(
      color: backColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text('Kesiapan Seminar', style: AppTextStyles.label),
              const Spacer(),
              if (isReady)
                AppButton(
                  label: 'Setujui',
                  icon: Icons.check,
                  width: 110,
                  color: AppColors.success,
                  onPressed: () => _showApproveDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusText,
            style: AppTextStyles.bodySmall.copyWith(color: iconColor),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReadinessCheckRow(
            icon: Icons.task_alt,
            label: 'Milestone 100%',
            isDone: milestone >= 1.0,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReadinessCheckRow(
            icon: Icons.chat,
            label: 'Bimbingan ≥ 8 sesi ($guidance/8)',
            isDone: guidance >= 8,
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Kesiapan Seminar'),
        content: const Text(
          'Anda akan menyetujui kesiapan seminar mahasiswa ini. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kesiapan seminar berhasil disetujui!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCheckRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;

  const _ReadinessCheckRow({
    required this.icon,
    required this.label,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.cancel_outlined,
          size: 16,
          color: isDone ? AppColors.success : AppColors.destructive,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Milestone Section ────────────────────────────────────────
class _MilestoneSection extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> components;
  const _MilestoneSection({required this.isLoading, required this.components});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Milestone'),
          const SizedBox(height: AppSpacing.sm),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (components.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada data milestone',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...components.map((c) {
              final name = (c['name'] ?? c['title'] ?? '-').toString();
              final rawStatus = (c['status'] ?? '').toString().toLowerCase();
              final completedAt = c['completedAt'];
              final validated = c['validatedBySupervisor'] == true;
              final String status;
              // Handle both response formats:
              // - my-students/:thesisId returns {title, status: 'COMPLETED'/'IN_PROGRESS'/'NOT_STARTED'}
              // - progress/:studentId returns {name, completedAt, validatedBySupervisor}
              if (rawStatus == 'completed' || validated) {
                status = 'completed';
              } else if (rawStatus == 'in_progress' || completedAt != null) {
                status = 'in_progress';
              } else {
                status = 'not_started';
              }
              return _MilestoneTile(
                title: name,
                status: status,
                componentId: (c['componentId'] ?? c['id'] ?? '').toString(),
              );
            }),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final String title;
  final String status;
  final String componentId;
  const _MilestoneTile({
    required this.title,
    required this.status,
    this.componentId = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'completed';
    final isCurrent = status == 'in_progress';
    final BadgeVariant variant = isDone
        ? BadgeVariant.success
        : (isCurrent ? BadgeVariant.primary : BadgeVariant.outline);
    final String label = isDone
        ? 'Selesai'
        : (isCurrent ? 'Progress' : 'Belum');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : (isCurrent ? Icons.radio_button_on : Icons.circle_outlined),
            size: 18,
            color: isDone
                ? AppColors.success
                : (isCurrent ? AppColors.primary : AppColors.textTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTextStyles.body)),
          AppBadge(label: label, variant: variant),
          const SizedBox(width: 8),
          if (isCurrent)
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Validasi',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Guidance History ─────────────────────────────────────────
class _GuidanceHistorySection extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> sessions;
  const _GuidanceHistorySection({
    required this.isLoading,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Riwayat Bimbingan',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada riwayat bimbingan',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...sessions.map((s) {
              final status = (s['status'] ?? '').toString();
              final isPending = status == 'summary_pending' ||
                  status == 'requested';
              final isCompleted = status == 'completed';
              final topic = (s['studentNotes'] ?? s['topic'] ?? 'Bimbingan')
                  .toString();
              final dateStr = s['requestedDateFormatted'] ??
                  s['approvedDateFormatted'] ??
                  _formatDate(s['requestedDate'] ?? s['approvedDate']) ??
                  '-';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.warning
                            : (isCompleted
                                ? AppColors.success
                                : AppColors.textTertiary),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic, style: AppTextStyles.label),
                          Text(dateStr.toString(),
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      AppBadge(
                          label: 'Selesai', variant: BadgeVariant.success),
                    if (isPending)
                      AppBadge(
                          label: 'Menunggu', variant: BadgeVariant.warning),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}
