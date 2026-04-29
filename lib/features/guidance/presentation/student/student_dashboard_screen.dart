import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/student_api_service.dart';
import '../../../../core/services/notification_api_service.dart';
import '../../../notifications/presentation/notification_screen.dart'
    show NotificationScreen;
import '../../../../core/widgets/app_drawer.dart';
import 'milestone_progress_screen.dart';

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
  final _fcm = FcmService();

  bool _isLoading = true;
  String? _error;

  int _unreadCount = 0;

  // Data from API
  Map<String, dynamic>? _thesis;
  List<dynamic> _milestones = [];
  int _completedGuidanceCount = 0;
  int _milestoneProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fcm.addListener(_onFcmMessage);
  }

  @override
  void dispose() {
    _fcm.removeListener(_onFcmMessage);
    super.dispose();
  }

  /// Silently refresh when an FCM notification arrives (e.g. daily reminder).
  void _onFcmMessage(Map<String, dynamic> data) {
    _loadData(silent: true);
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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

        final List<dynamic> rawMilestones =
            (progressData['components'] as List<dynamic>?) ?? [];
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
          } else if (rawStatus == 'in_progress' || completedAt != null) {
            status = 'in_progress';
          } else {
            status = 'not_started';
          }

          if (status == 'in_progress') {
            inProgress.add(c);
          } else if (status == 'not_started') {
            notStarted.add(c);
          } else {
            completed.add(c);
          }
        }

        _milestones = [...inProgress, ...notStarted, ...completed.reversed];

        // Count completed guidances from thesis stats
        final stats = _thesis?['stats'] as Map<String, dynamic>?;
        _milestoneProgress = (stats?['milestoneProgress'] as int?) ?? 0;

        _completedGuidanceCount = (stats?['completedGuidances'] as int?) ?? 0;
        _isLoading = false;
      });

      _notifApi.getUnreadCount().then((count) {
        if (mounted) {
          setState(() => _unreadCount = count);
        }
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
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'tugas_akhir'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Builder(
                      builder: (innerContext) => Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () => Scaffold.of(innerContext).openDrawer(),
                        ),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        child: _error!.contains('Active thesis not found')
                            ? _buildRequirementsNotMet()
                            : _buildErrorState(),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildHeaderBackground(context, firstName),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 280,
                        left: AppSpacing.pagePadding,
                        right: AppSpacing.pagePadding,
                        bottom: 100, // padding for FAB
                      ),
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: _error == null && _thesis != null
          ? FloatingActionButton(
              onPressed: () {
                widget.onSwitchTab?.call(1);
              },
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.white,
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Column(
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
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Lagi'),
          onPressed: _loadData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsNotMet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Syarat Mata Kuliah Belum Terpenuhi',
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Anda belum memenuhi persyaratan untuk mengambil mata kuliah Tugas Akhir. Anda harus tercatat mengambil mata kuliah Tugas Akhir (proposal disetujui).',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Muat Ulang'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBackground(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        60,
        AppSpacing.pagePadding,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ], // Vibrant Orange gradient
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (BuildContext innerContext) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        Scaffold.of(innerContext).openDrawer();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Tugas Akhir',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hi, $name',
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                );
                                final count = await _notifApi.getUnreadCount();
                                if (mounted) {
                                  setState(() => _unreadCount = count);
                                }
                              },
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          const SizedBox(height: 32),
          // OVERALL PROGRESS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRES KESELURUHAN',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_milestoneProgress%',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontSize: 36,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'selesai',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final title = _thesis?['title'] ?? 'Belum ada tugas akhir';
    final status = _thesis?['status'] ?? '-';
    final supervisors = List<dynamic>.from(
      (_thesis?['supervisors'] as List<dynamic>?) ?? [],
    );
    // Sort supervisors so Pembimbing 1 is first
    supervisors.sort((a, b) {
      final roleA = (a['role'] ?? '').toString().toLowerCase();
      final roleB = (b['role'] ?? '').toString().toLowerCase();
      return roleA.compareTo(roleB);
    });
    final deadlineDate = _thesis?['deadlineDate'];

    String deadlineStr = '-';
    int remainingDays = 0;
    if (deadlineDate != null) {
      try {
        final dt = DateTime.parse(deadlineDate.toString());
        // format: Jan 8, 2026
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        deadlineStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
        remainingDays = dt.difference(DateTime.now()).inDays;
      } catch (_) {
        deadlineStr = deadlineDate.toString();
      }
    }

    final isActive =
        status.toString().toLowerCase().contains('aktif') ||
        status.toString().toLowerCase().contains('berlangsung');

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title.toString(),
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 20,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Text(
                        isActive ? 'AKTIF' : status.toString().toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pantau perjalanan tugas akhirmu, kelola tenggat waktu, dan koordinasi dengan dosen pembimbing.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Supervisors mapped dynamically
                if (supervisors.isNotEmpty)
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: supervisors.length,
                    itemBuilder: (context, index) {
                      final sup = supervisors[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (sup['role'] ?? 'PEMBIMBING')
                                      .toString()
                                      .toUpperCase(),
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (sup['name'] ?? '-').toString(),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
                // Submission Deadline
                if (deadlineDate != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primaryDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TENGGAT WAKTU',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                deadlineStr,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Sisa',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${remainingDays > 0 ? remainingDays : 0} Hari',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: AppColors.surfaceSecondary, thickness: 8, height: 8),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Milestones',
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Text(
                        _milestoneProgress == 100
                            ? 'Selesai Semua'
                            : 'Sedang Berjalan',
                        style: AppTextStyles.label.copyWith(
                          color: const Color(0xFFEA580C),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                if (_milestones.isEmpty)
                  Text('Belum ada milestone', style: AppTextStyles.bodySmall)
                else
                  ...List.generate(_milestones.length, (index) {
                    final m = _milestones[index];
                    final isLast = index == _milestones.length - 1;
                    final isCompleted = m['status'] == 'completed';
                    return _TimelineItem(
                      title: (m['name'] ?? m['title'] ?? '').toString(),
                      isCompleted: isCompleted,
                      isLast: isLast,
                    );
                  }),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final thesisId =
                          (_thesis?['id'] ?? _thesis?['thesisId'] ?? '')
                              .toString();
                      if (thesisId.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MilestoneProgressScreen(thesisId: thesisId),
                        ),
                      ).then((_) => _loadData(silent: true));
                    },
                    icon: const Icon(Icons.trending_up_rounded, size: 18),
                    label: const Text('Kelola Milestone'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.surfaceSecondary, thickness: 8, height: 8),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progres Bimbingan',
                  style: AppTextStyles.h4.copyWith(
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: (_completedGuidanceCount / 8).clamp(
                                0.0,
                                1.0,
                              ),
                              backgroundColor: Colors.grey[200],
                              color: const Color(0xFFEA580C),
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_completedGuidanceCount',
                                  style: AppTextStyles.h3.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                TextSpan(
                                  text: '/8',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Kamu sudah menyelesaikan ",
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text: "$_completedGuidanceCount sesi.",
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (_completedGuidanceCount < 8 || _milestoneProgress < 100)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _completedGuidanceCount < 8 && _milestoneProgress < 100
                                        ? 'Selesaikan ${8 - _completedGuidanceCount} sesi lagi dan 100% milestone untuk siap seminar.'
                                        : (_completedGuidanceCount < 8
                                            ? '${8 - _completedGuidanceCount} sesi bimbingan lagi untuk kesiapan seminar.'
                                            : 'Selesaikan milestone hingga 100% untuk siap seminar.'),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF22C55E),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Syarat kesiapan seminar telah terpenuhi.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: const Color(0xFF22C55E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 16),
                _buildSeminarReadinessRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeminarReadinessRow() {
    final seminar = _thesis?['seminarApproval'] as Map<String, dynamic>?;
    final isFullyApproved = seminar?['isFullyApproved'] == true;
    final guidanceMet = _completedGuidanceCount >= 8;
    final isReady = isFullyApproved && guidanceMet && _milestoneProgress >= 100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Kesiapan Seminar',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isReady ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isReady ? 'Sudah diApprove' : 'Belum diApprove',
            style: AppTextStyles.label.copyWith(
              color: isReady
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFEA580C),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.isCompleted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFFF97316) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFFFFEDD5)
                          : Colors.grey[300]!,
                      width: isCompleted ? 4 : 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[200])),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(Icons.check, size: 16, color: Color(0xFFF97316)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
