import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/lecturer_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import 'guidance_session_detail_screen.dart';

/// Tabbed screen for all lecturer approval actions:
/// 0. Permintaan Bimbingan (guidance requests – approve/reject)
/// 1. Catatan Bimbingan (session summaries – approve only)
/// 2. Milestone (pending review milestones – approve / request revision)
/// 3. Perubahan Topik (topic change requests – approve/reject)
class GuidanceRequestsScreen extends StatefulWidget {
  final int initialTab;
  final bool isTab;
  const GuidanceRequestsScreen({
    super.key,
    this.initialTab = 0,
    this.isTab = false,
  });

  @override
  State<GuidanceRequestsScreen> createState() => _GuidanceRequestsScreenState();
}

class _GuidanceRequestsScreenState extends State<GuidanceRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: Column(
        children: [
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
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!widget.isTab)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                size: 20, color: AppColors.white),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        Text(
                          'Approval Bimbingan',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.white,
                      unselectedLabelColor:
                          AppColors.white.withValues(alpha: 0.6),
                      indicatorColor: AppColors.white,
                      indicatorWeight: 3,
                      labelStyle:
                          AppTextStyles.label.copyWith(fontSize: 13),
                      unselectedLabelStyle:
                          AppTextStyles.body.copyWith(fontSize: 13),
                      tabs: const [
                        Tab(text: 'Permintaan'),
                        Tab(text: 'Catatan'),
                        Tab(text: 'Milestone'),
                        Tab(text: 'Topik'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _GuidanceRequestsTab(),
                _SessionSummaryTab(),
                _MilestoneApprovalTab(),
                _TopicChangeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Guidance Requests ─────────────────────────────────
class _GuidanceRequestsTab extends StatefulWidget {
  const _GuidanceRequestsTab();

  @override
  State<_GuidanceRequestsTab> createState() => _GuidanceRequestsTabState();
}

class _GuidanceRequestsTabState extends State<_GuidanceRequestsTab> {
  final _api = LecturerApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _requests = [];

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
      _requests = await _api.getRequests();
      if (!mounted) return;
      setState(() => _isLoading = false);
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gagal memuat data', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            AppButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text('Tidak ada permintaan baru', style: AppTextStyles.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              itemCount: _requests.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final req = _requests[index];
                final name = (req['studentName'] ?? req['name'] ?? '-')
                    .toString();
                final nim = (req['studentNim'] ?? req['nim'] ?? '').toString();
                final topic = (req['studentNotes'] ?? req['topic'] ?? '-')
                    .toString();
                final dateStr =
                    (req['requestedDateFormatted'] ?? req['date'] ?? '-')
                        .toString();
                final supervisorRole =
                    (req['supervisorRole'] ?? req['supervisor'] ?? '')
                        .toString();

                // Build session map for detail screen
                final sessionMap = <String, String>{
                  'name': name,
                  'nim': nim,
                  'topic': topic,
                  'date': dateStr,
                  'supervisor': supervisorRole,
                  if (req['id'] != null) 'id': req['id'].toString(),
                };

                return AppCard(
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GuidanceSessionDetailScreen(session: sessionMap),
                      ),
                    );
                    // Reload when approved/rejected
                    if (result == true) _loadData();
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: AppTextStyles.label),
                                if (nim.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  AppBadge(
                                    label: nim,
                                    variant: BadgeVariant.outline,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topic,
                              style: AppTextStyles.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(dateStr, style: AppTextStyles.caption),
                                if (supervisorRole.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.person_outline,
                                    size: 13,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    supervisorRole,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─── Tab 2: Session Summary Approval ─────────────────────────
class _SessionSummaryTab extends StatefulWidget {
  const _SessionSummaryTab();

  @override
  State<_SessionSummaryTab> createState() => _SessionSummaryTabState();
}

class _SessionSummaryTabState extends State<_SessionSummaryTab> {
  final _api = LecturerApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _summaries = [];
  final Set<String> _approvingIds = {};

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
      _summaries = await _api.getPendingApproval();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleApprove(String guidanceId) async {
    setState(() => _approvingIds.add(guidanceId));
    try {
      await _api.approveSessionSummary(guidanceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan bimbingan disetujui'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _approvingIds.remove(guidanceId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gagal memuat data', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            AppButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }
    if (_summaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada catatan menunggu approval',
              style: AppTextStyles.body,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _summaries.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final s = _summaries[index];
          final id = (s['id'] ?? '').toString();
          final name = (s['studentName'] ?? s['name'] ?? '-').toString();
          final dateStr = (s['approvedDateFormatted'] ??
                  s['summarySubmittedAtFormatted'] ??
                  s['date'] ??
                  '-')
              .toString();
          final summary =
              (s['sessionSummary'] ?? s['summary'] ?? '-').toString();
          final actionItems = (s['actionItems'] ?? '').toString();
          final milestone = (s['milestoneName'] ?? '').toString();
          final isApproving = _approvingIds.contains(id);

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.label),
                          Text(dateStr, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const AppBadge(
                      label: 'Perlu Approval',
                      variant: BadgeVariant.warning,
                    ),
                  ],
                ),
                const AppDivider(),
                if (milestone.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          milestone,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text('Ringkasan:', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: AppTextStyles.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (actionItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Action Items:', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    actionItems,
                    style: AppTextStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: isApproving ? 'Menyetujui...' : 'Setujui Catatan',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    isLoading: isApproving,
                    onPressed: isApproving
                        ? null
                        : () => _handleApprove(id),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab 3: Milestone Approval ───────────────────────────────
class _MilestoneApprovalTab extends StatefulWidget {
  const _MilestoneApprovalTab();

  @override
  State<_MilestoneApprovalTab> createState() => _MilestoneApprovalTabState();
}

class _MilestoneApprovalTabState extends State<_MilestoneApprovalTab> {
  final _api = LecturerApiService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _milestones = [];
  final Set<String> _processingIds = {};

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
      _milestones = await _api.getPendingReviewMilestones();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleValidate(String milestoneId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Milestone'),
        content: const Text(
          'Apakah Anda yakin ingin menyetujui milestone ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(milestoneId));
    try {
      await _api.validateMilestone(milestoneId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Milestone berhasil disetujui'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(milestoneId));
    }
  }

  Future<void> _handleRevision(String milestoneId) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minta Revisi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan catatan revisi untuk mahasiswa:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Catatan revisi...',
                border: OutlineInputBorder(),
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
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('Minta Revisi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notes = notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan revisi wajib diisi'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _processingIds.add(milestoneId));
    try {
      await _api.requestMilestoneRevision(milestoneId, notes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisi milestone diminta'),
          backgroundColor: AppColors.info,
        ),
      );
      _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(milestoneId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gagal memuat data', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            AppButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }
    if (_milestones.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada milestone menunggu review',
              style: AppTextStyles.body,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _milestones.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final m = _milestones[index];
          final milestoneId = (m['id'] ?? '').toString();
          final title = (m['title'] ?? '-').toString();
          final studentName = (m['studentName'] ?? '-').toString();
          final studentNim = (m['studentNim'] ?? '').toString();
          final progress = (m['progressPercentage'] ?? 0);
          final studentNotes = (m['studentNotes'] ?? '').toString();
          final isProcessing = _processingIds.contains(milestoneId);

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0] : '?',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName, style: AppTextStyles.label),
                          if (studentNim.isNotEmpty)
                            Text(studentNim, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const AppBadge(
                      label: 'Pending Review',
                      variant: BadgeVariant.warning,
                    ),
                  ],
                ),
                const AppDivider(),
                Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Progress: $progress%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: progress >= 100
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (studentNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Catatan Mahasiswa:', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    studentNotes,
                    style: AppTextStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Setujui',
                        icon: Icons.check,
                        color: AppColors.success,
                        isLoading: isProcessing,
                        onPressed: isProcessing
                            ? null
                            : () => _handleValidate(milestoneId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Revisi',
                        icon: Icons.edit_note,
                        isOutline: true,
                        color: AppColors.destructive,
                        isLoading: isProcessing,
                        onPressed: isProcessing
                            ? null
                            : () => _handleRevision(milestoneId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab 4: Topic Change Approval ────────────────────────────
class _TopicChangeTab extends StatefulWidget {
  const _TopicChangeTab();

  @override
  State<_TopicChangeTab> createState() => _TopicChangeTabState();
}

class _TopicChangeTabState extends State<_TopicChangeTab> {
  final _api = LecturerApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _requests = [];
  final Set<String> _processingIds = {};

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
      _requests = await _api.getPendingTopicChanges();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleApprove(String id, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Perubahan Topik'),
        content: Text(
          'Setujui perubahan topik/judul TA untuk $studentName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(id));
    try {
      await _api.approveTopicChange(id, 'Disetujui oleh pembimbing');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan topik disetujui'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _handleReject(String id) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Perubahan Topik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan alasan penolakan:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Alasan penolakan...',
                border: OutlineInputBorder(),
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
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notes = notesController.text.trim();
    setState(() => _processingIds.add(id));
    try {
      await _api.rejectTopicChange(
        id,
        notes.isNotEmpty ? notes : 'Ditolak oleh pembimbing',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan topik ditolak'),
          backgroundColor: AppColors.destructive,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gagal memuat data', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            AppButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_note_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada permintaan perubahan topik',
              style: AppTextStyles.body,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final r = _requests[index];
          final id = (r['id'] ?? '').toString();
          final currentThesis = r['thesis'] ?? {};
          final student = currentThesis['student'] ?? {};
          final name = (student['user']?['fullName'] ?? '-').toString();
          final currentTitle = (currentThesis['title'] ?? '-').toString();
          final proposedTitle =
              (r['proposedThesis']?['title'] ?? r['proposedTitle'] ?? '-')
                  .toString();
          final reason = (r['reason'] ?? '').toString();
          final isProcessing = _processingIds.contains(id);

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.label),
                          Text(
                            'Perubahan Judul/Topik',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppBadge(
                      label: 'Menunggu',
                      variant: BadgeVariant.warning,
                    ),
                  ],
                ),
                const AppDivider(),
                Text('Judul Lama:', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  currentTitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Judul Baru:', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  proposedTitle,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Alasan:', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(reason, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Setujui',
                        icon: Icons.check,
                        color: AppColors.success,
                        isLoading: isProcessing,
                        onPressed: isProcessing
                            ? null
                            : () => _handleApprove(id, name),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Tolak',
                        icon: Icons.close,
                        isOutline: true,
                        color: AppColors.destructive,
                        isLoading: isProcessing,
                        onPressed: isProcessing
                            ? null
                            : () => _handleReject(id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
