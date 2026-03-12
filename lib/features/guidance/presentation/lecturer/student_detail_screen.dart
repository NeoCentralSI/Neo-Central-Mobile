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
  String? _userRole;

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
        _userRole = detailData['userRole']?.toString();
        if (detailData.containsKey('milestones')) {
          final List<dynamic> rawMilestones =
              detailData['milestones'] as List<dynamic>;
          final List<dynamic> inProgress = [];
          final List<dynamic> notStarted = [];
          final List<dynamic> completed = [];

          for (var c in rawMilestones) {
            final rawStatus = (c['status'] ?? '').toString().toLowerCase();
            final completedAt = c['completedAt'];
            final validated = c['validatedBySupervisor'] == true;

            String status;
            if (rawStatus == 'completed' || validated) {
              status = 'completed';
            } else if (rawStatus == 'pending_review') {
              status = 'pending_review';
            } else if (rawStatus == 'in_progress' || completedAt != null) {
              status = 'in_progress';
            } else if (rawStatus == 'revision_needed') {
              status = 'revision_needed';
            } else {
              status = 'not_started';
            }

            // Update status in the component object for UI consistency
            final Map<String, dynamic> updatedC = Map<String, dynamic>.from(c);
            updatedC['calculatedStatus'] = status;

            if (status == 'in_progress' || status == 'pending_review' || status == 'revision_needed') {
              inProgress.add(updatedC);
            } else if (status == 'not_started') {
              notStarted.add(updatedC);
            } else {
              completed.add(updatedC);
            }
          }

          _milestoneComponents = [
            ...inProgress,
            ...notStarted,
            ...completed.reversed,
          ];
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
        (widget.student['completedGuidanceCount'] ??
                widget.student['guidance'] ??
                0)
            is int
        ? (widget.student['completedGuidanceCount'] ??
                  widget.student['guidance'] ??
                  0)
              as int
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
                colors: [AppColors.primaryLight, AppColors.primary],
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: AppColors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Detail Mahasiswa',
                      style: AppTextStyles.h2.copyWith(color: AppColors.white),
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
                        _MilestoneSection(
                          isLoading: _isLoadingMilestones,
                          components: _milestoneComponents,
                          userRole: _userRole,
                          onRefresh: _loadData,
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
          if (student['thesisRating'] == 'SLOW' || student['thesisRating'] == 'AT_RISK') ...[
            const SizedBox(height: 20),
            _ReminderButton(student: student),
          ],
        ],
      ),
    );
  }
}

class _ReminderButton extends StatefulWidget {
  final Map<String, dynamic> student;
  const _ReminderButton({required this.student});

  @override
  State<_ReminderButton> createState() => _ReminderButtonState();
}

class _ReminderButtonState extends State<_ReminderButton> {
  final _api = LecturerApiService();
  bool _isSending = false;

  Future<void> _sendReminder() async {
    final thesisId = (widget.student['thesisId'] ?? '').toString();
    if (thesisId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Pengingat'),
        content: Text(
          'Kirim notifikasi pengingat bimbingan kepada ${widget.student['fullName'] ?? widget.student['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSending = true);
      try {
        await _api.sendWarningNotification(thesisId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengingat berhasil dikirim'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim pengingat: $e'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: 'Kirim Pengingat',
        icon: Icons.notifications_active_outlined,
        isLoading: _isSending,
        onPressed: _sendReminder,
        color: widget.student['thesisRating'] == 'AT_RISK'
            ? AppColors.destructive
            : AppColors.primary,
      ),
    );
  }
}

// ─── Milestone Section ────────────────────────────────────────
class _MilestoneSection extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> components;
  final String? userRole;
  final VoidCallback onRefresh;
  const _MilestoneSection({
    required this.isLoading,
    required this.components,
    this.userRole,
    required this.onRefresh,
  });

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
              final status = (c['calculatedStatus'] ?? 'not_started').toString();
              return _MilestoneTile(
                title: (c['name'] ?? c['title'] ?? '-').toString(),
                status: status,
                milestoneId: (c['id'] ?? '').toString(),
                userRole: userRole,
                onRefresh: onRefresh,
              );
            }),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatefulWidget {
  final String title;
  final String status;
  final String milestoneId;
  final String? userRole;
  final VoidCallback onRefresh;

  const _MilestoneTile({
    required this.title,
    required this.status,
    required this.milestoneId,
    this.userRole,
    required this.onRefresh,
  });

  @override
  State<_MilestoneTile> createState() => _MilestoneTileState();
}

class _MilestoneTileState extends State<_MilestoneTile> {
  final _api = LecturerApiService();
  bool _isProcessing = false;

  void _showValidationDialog() async {
    final notesController = TextEditingController();
    int selectedAction = 0; // 0: Approve, 1: Revision

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Validasi Milestone', style: AppTextStyles.h4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tentukan hasil validasi untuk milestone "${widget.title}"',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              RadioListTile<int>(
                title: const Text('Setujui (Selesai)'),
                value: 0,
                groupValue: selectedAction,
                onChanged: (v) => setState(() => selectedAction = v!),
              ),
              RadioListTile<int>(
                title: const Text('Perlu Revisi'),
                value: 1,
                groupValue: selectedAction,
                onChanged: (v) => setState(() => selectedAction = v!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: selectedAction == 0
                      ? 'Catatan opsional'
                      : 'Catatan revisi (wajib)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedAction == 1 && notesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catatan revisi wajib diisi')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedAction == 0 ? AppColors.success : AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text(selectedAction == 0 ? 'Setujui' : 'Minta Revisi'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        if (selectedAction == 0) {
          await _api.validateMilestone(widget.milestoneId,
              notes: notesController.text.trim());
        } else {
          await _api.requestMilestoneRevision(
              widget.milestoneId, notesController.text.trim());
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(selectedAction == 0
                  ? 'Milestone disetujui'
                  : 'Revisi diminta'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onRefresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final title = widget.title;
    final isDone = status == 'completed';
    final isCurrent = status == 'in_progress' ||
        status == 'pending_review' ||
        status == 'revision_needed';
    final isPending = status == 'pending_review';
    final isRevision = status == 'revision_needed';
    final bool isPembimbing1 = widget.userRole == 'Pembimbing 1';

    final BadgeVariant variant = isDone
        ? BadgeVariant.success
        : (isPending
            ? BadgeVariant.warning
            : (isRevision
                ? BadgeVariant.destructive
                : (isCurrent ? BadgeVariant.primary : BadgeVariant.outline)));

    final String label = isDone
        ? 'Selesai'
        : (isPending
            ? 'Review'
            : (isRevision
                ? 'Revisi'
                : (isCurrent ? 'Progress' : 'Belum')));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : (isPending
                    ? Icons.pending_actions
                    : (isCurrent
                        ? Icons.radio_button_on
                        : Icons.circle_outlined)),
            size: 18,
            color: isDone
                ? AppColors.success
                : (isPending
                    ? AppColors.warning
                    : (isCurrent ? AppColors.primary : AppColors.textTertiary)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTextStyles.body)),
          if (_isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            AppBadge(label: label, variant: variant),
            const SizedBox(width: 8),
            if ((isPending || isCurrent) && isPembimbing1)
              InkWell(
                onTap: _showValidationDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.warningLight
                        : AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending ? 'Review' : 'Validasi',
                    style: AppTextStyles.caption.copyWith(
                      color: isPending
                          ? AppColors.warningDark
                          : AppColors.successDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if ((isPending || isCurrent) && !isPembimbing1)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
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
          SectionHeader(title: 'Riwayat Bimbingan'),
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
              final isPending =
                  status == 'summary_pending' || status == 'requested';
              final isCompleted = status == 'completed';
              final topic = (s['studentNotes'] ?? s['topic'] ?? 'Bimbingan')
                  .toString();
              final dateStr =
                  s['requestedDateFormatted'] ??
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
                          Text(
                            dateStr.toString(),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      AppBadge(label: 'Selesai', variant: BadgeVariant.success),
                    if (isPending)
                      AppBadge(
                        label: 'Menunggu',
                        variant: BadgeVariant.warning,
                      ),
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
