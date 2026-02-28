import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/student_api_service.dart';
import '../../../../core/services/notification_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../notifications/presentation/notification_screen.dart';

/// Student dashboard – shows a summary of their active thesis.
class StudentDashboardScreen extends StatefulWidget {
  final UserModel? user;
  final void Function(int)? onSwitchTab;
  const StudentDashboardScreen({super.key, this.user, this.onSwitchTab});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _api = StudentApiService();
  final _notifApi = NotificationApiService();

  bool _isLoading = true;
  String? _error;

  int _unreadCount = 0;

  // Data from API
  Map<String, dynamic>? _thesis;
  List<dynamic> _milestones = [];
  int _completedGuidanceCount = 0;
  int _totalGuidanceCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getMyThesis(),
        _api.getProgress(),
      ]);

      final thesisData = results[0];
      final progressData = results[1];

      if (!mounted) return;
      setState(() {
        _thesis = thesisData['thesis'] as Map<String, dynamic>?;
        _milestones = (progressData['components'] as List<dynamic>?) ?? [];

        // Count completed guidances from thesis stats
        final stats = _thesis?['stats'] as Map<String, dynamic>?;
        _totalGuidanceCount = (stats?['totalGuidances'] as int?) ?? 0;

        _completedGuidanceCount = _totalGuidanceCount;
        _isLoading = false;
      });

      // Fetch unread count separately (non-blocking for UI)
      _notifApi.getUnreadCount().then((count) {
        if (mounted) setState(() => _unreadCount = count);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user?.fullName ?? 'Mahasiswa';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, firstName),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text('Gagal memuat data', style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Coba Lagi',
                          icon: Icons.refresh,
                          onPressed: _loadData,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ThesisSummaryCard(thesis: _thesis),
                    const SizedBox(height: AppSpacing.base),
                    _ProgressSection(milestones: _milestones),
                    const SizedBox(height: AppSpacing.base),
                    _GuidanceProgressCard(
                      completedCount: _completedGuidanceCount,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _SeminarReadinessCard(
                      thesis: _thesis,
                      completedGuidanceCount: _completedGuidanceCount,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Switch to "Jadwalkan" tab (index 1) instead of pushing a new route
          widget.onSwitchTab?.call(1);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Jadwalkan Bimbingan',
          style: AppTextStyles.label.copyWith(color: AppColors.white),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            60,
            AppSpacing.pagePadding,
            AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo,',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          name,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                          // Refresh unread count when returning
                          final count = await _notifApi.getUnreadCount();
                          if (mounted) setState(() => _unreadCount = count);
                        },
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

// ─── Thesis Summary Card ──────────────────────────────────────
class _ThesisSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? thesis;
  const _ThesisSummaryCard({required this.thesis});

  @override
  Widget build(BuildContext context) {
    final title = thesis?['title'] ?? 'Belum ada tugas akhir';
    final status = thesis?['status'] ?? '-';
    final supervisors = (thesis?['supervisors'] as List<dynamic>?) ?? [];
    final deadlineDate = thesis?['deadlineDate'];

    String deadlineStr = '-';
    if (deadlineDate != null) {
      try {
        final dt = DateTime.parse(deadlineDate.toString());
        deadlineStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        deadlineStr = deadlineDate.toString();
      }
    }

    final isActive =
        status.toString().toLowerCase().contains('aktif') ||
        status.toString().toLowerCase().contains('berlangsung');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tugas Akhir',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              AppBadge(
                label: isActive ? 'Aktif' : status.toString(),
                variant: isActive ? BadgeVariant.success : BadgeVariant.outline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title.toString(), style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.sm),
          for (final sup in supervisors) ...[
            InfoRow(
              icon: Icons.person_outline,
              label: (sup['role'] ?? 'Pembimbing').toString(),
              value: (sup['name'] ?? '-').toString(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (deadlineDate != null)
            InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Deadline',
              value: deadlineStr,
              valueColor: AppColors.warning,
            ),
        ],
      ),
    );
  }
}

// ─── Progress Section ─────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final List<dynamic> milestones;
  const _ProgressSection({required this.milestones});

  @override
  Widget build(BuildContext context) {
    final total = milestones.length;
    final completed = milestones
        .where((m) => m['status'] == 'completed')
        .length;
    final progress = total > 0 ? completed / total : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Progress Milestone'),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: progress),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% selesai',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$completed dari $total milestone',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          if (milestones.isNotEmpty) const AppDivider(),
          for (final m in milestones)
            _MilestoneRow(
              title: (m['name'] ?? m['title'] ?? '').toString(),
              status: _statusLabel(m['status']?.toString() ?? ''),
              isDone: m['status'] == 'completed',
              isCurrent: m['status'] == 'in_progress',
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Selesai';
      case 'in_progress':
        return 'Sedang Dikerjakan';
      default:
        return 'Belum Dimulai';
    }
  }
}

class _MilestoneRow extends StatelessWidget {
  final String title;
  final String status;
  final bool isDone;
  final bool isCurrent;

  const _MilestoneRow({
    required this.title,
    required this.status,
    required this.isDone,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : (isCurrent
                      ? Icons.radio_button_unchecked
                      : Icons.circle_outlined),
            color: isDone
                ? AppColors.success
                : (isCurrent ? AppColors.primary : AppColors.textTertiary),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          AppBadge(
            label: status,
            variant: isDone
                ? BadgeVariant.success
                : (isCurrent ? BadgeVariant.primary : BadgeVariant.outline),
          ),
        ],
      ),
    );
  }
}

// ─── Guidance Progress Card ───────────────────────────────────
class _GuidanceProgressCard extends StatelessWidget {
  final int completedCount;
  const _GuidanceProgressCard({required this.completedCount});

  @override
  Widget build(BuildContext context) {
    const required = 8;
    final remaining = (required - completedCount).clamp(0, required);
    final progress = completedCount / required;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Progress Bimbingan'),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(
            value: progress.clamp(0.0, 1.0),
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$completedCount',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    ' / $required sesi',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (remaining > 0)
                Text(
                  'Perlu $remaining sesi lagi',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                )
              else
                Text(
                  'Syarat terpenuhi ✓',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          const AppDivider(),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Minimal 8 sesi bimbingan diperlukan sebelum approval seminar',
                  style: AppTextStyles.bodySmall,
                ),
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
  final Map<String, dynamic>? thesis;
  final int completedGuidanceCount;
  const _SeminarReadinessCard({
    required this.thesis,
    required this.completedGuidanceCount,
  });

  @override
  Widget build(BuildContext context) {
    final seminar = thesis?['seminarApproval'] as Map<String, dynamic>?;
    final isFullyApproved = seminar?['isFullyApproved'] == true;
    final guidanceMet = completedGuidanceCount >= 8;
    final isReady = isFullyApproved && guidanceMet;

    final stats = thesis?['stats'] as Map<String, dynamic>?;
    final milestoneProgress = (stats?['milestoneProgress'] as int?) ?? 0;
    final milestoneMet = milestoneProgress >= 100;

    String statusText;
    if (isReady) {
      statusText = 'Semua syarat terpenuhi!';
    } else if (milestoneMet && !guidanceMet) {
      statusText =
          'Belum memenuhi syarat – ${8 - completedGuidanceCount} sesi bimbingan lagi';
    } else if (!milestoneMet && guidanceMet) {
      statusText = 'Belum memenuhi syarat – milestone belum 100%';
    } else {
      statusText = 'Belum memenuhi syarat';
    }

    return AppCard(
      backgroundColor: isReady
          ? AppColors.successLight
          : AppColors.warningLight,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isReady ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              color: isReady ? AppColors.successDark : AppColors.warningDark,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Kesiapan Seminar', style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isReady
                        ? AppColors.successDark
                        : AppColors.warningDark,
                  ),
                ),
              ],
            ),
          ),
          AppBadge(
            label: isReady ? 'Siap' : 'Belum',
            variant: isReady ? BadgeVariant.success : BadgeVariant.warning,
          ),
        ],
      ),
    );
  }
}
