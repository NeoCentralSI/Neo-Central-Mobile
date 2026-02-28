import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/lecturer_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import 'guidance_session_detail_screen.dart';

/// Tabbed screen for all lecturer approval actions:
/// 1. Permintaan Bimbingan (guidance requests)
/// 2. Catatan Bimbingan (session summaries pending approval)
/// 3. Kesiapan Seminar (seminar readiness)
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
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Approval Bimbingan', style: AppTextStyles.h4),
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.maybePop(context),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: AppTextStyles.label.copyWith(fontSize: 13),
              unselectedLabelStyle: AppTextStyles.body.copyWith(fontSize: 13),
              tabs: const [
                Tab(text: 'Permintaan'),
                Tab(text: 'Catatan'),
                Tab(text: 'Seminar'),
                Tab(text: 'Perpindahan'),
                Tab(text: 'Topik'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GuidanceRequestsTab(),
          _SessionSummaryTab(),
          _SeminarApprovalTab(),
          _TransferTab(),
          _TopicChangeTab(),
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
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Text(
                  '${_requests.length} permintaan',
                  style: AppTextStyles.bodySmall,
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GuidanceSessionDetailScreen(session: sessionMap),
                    ),
                  ),
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
          ),
        ],
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
          final name = (s['studentName'] ?? s['name'] ?? '-').toString();
          final dateStr = (s['approvedDateFormatted'] ?? s['date'] ?? '-')
              .toString();
          final summary = (s['sessionSummary'] ?? s['summary'] ?? '-')
              .toString();
          final topic = (s['studentNotes'] ?? s['topic'] ?? '-').toString();

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                    AppBadge(
                      label: 'Perlu Approval',
                      variant: BadgeVariant.warning,
                    ),
                  ],
                ),
                const AppDivider(),
                Text(topic, style: AppTextStyles.label),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: AppTextStyles.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Setujui',
                        icon: Icons.check,
                        color: AppColors.success,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Catatan bimbingan disetujui'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppButton(
                      label: 'Lihat',
                      isOutline: true,
                      width: 90,
                      onPressed: () {},
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

// ─── Tab 3: Seminar Readiness Approval ───────────────────────
class _SeminarApprovalTab extends StatefulWidget {
  const _SeminarApprovalTab();

  @override
  State<_SeminarApprovalTab> createState() => _SeminarApprovalTabState();
}

class _SeminarApprovalTabState extends State<_SeminarApprovalTab> {
  final _api = LecturerApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _students = [];

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
      final all = await _api.getMyStudents();
      // Filter students who meet both requirements:
      // milestone >= 100% and guidance >= 8
      _students = all.where((s) {
        final milestoneProgressRaw = s['milestoneProgress'];
        final double milestone = milestoneProgressRaw is int
            ? milestoneProgressRaw / 100
            : (milestoneProgressRaw is double ? milestoneProgressRaw : 0.0);
        final int guidance = (s['completedGuidanceCount'] ?? 0) is int
            ? (s['completedGuidanceCount'] ?? 0) as int
            : 0;
        return milestone >= 1.0 && guidance >= 8;
      }).toList();
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
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text('Tidak ada mahasiswa siap seminar', style: AppTextStyles.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _students.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final s = _students[index];
          final name = (s['fullName'] ?? s['studentName'] ?? '-').toString();
          final nim = (s['identityNumber'] ?? s['studentNim'] ?? '').toString();
          final thesis = (s['thesisTitle'] ?? '-').toString();
          final int guidance = (s['completedGuidanceCount'] ?? 0) is int
              ? (s['completedGuidanceCount'] ?? 0) as int
              : 0;

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                          if (nim.isNotEmpty)
                            Text(nim, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const AppBadge(
                      label: 'Siap',
                      variant: BadgeVariant.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(thesis, style: AppTextStyles.body),
                const AppDivider(),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Milestone: 100%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat, size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Bimbingan: $guidance/8',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Setujui Kesiapan Seminar',
                  icon: Icons.school,
                  color: AppColors.primary,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Setujui Kesiapan Seminar'),
                        content: Text('Setujui kesiapan seminar untuk $name?'),
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
                                  content: Text('Kesiapan seminar disetujui!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Setujui'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab 4: Student Transfer Approval ────────────────────────
class _TransferTab extends StatefulWidget {
  const _TransferTab();

  @override
  State<_TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<_TransferTab> {
  final _api = LecturerApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _transfers = [];

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
      _transfers = await _api.getIncomingTransfers();
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

  Future<void> _handleApprove(String id) async {
    try {
      await _api.approveTransfer(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mahasiswa bimbingan berhasil diterima'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Gagal: $_error'));
    if (_transfers.isEmpty) {
      return const Center(child: Text('Tidak ada permintaan perpindahan'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _transfers.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final t = _transfers[index];
          final student = t['student'] ?? {};
          final name = student['fullName'] ?? '-';
          final title = t['title'] ?? '-';
          final message = t['message'] ?? '';

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 20, child: Text(name[0])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.label),
                          Text(
                            'Permintaan Perpindahan',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Judul TA:', style: AppTextStyles.caption),
                Text(title, style: AppTextStyles.body),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Catatan: $message', style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Terima',
                        icon: Icons.check,
                        onPressed: () => _handleApprove(t['id'].toString()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Tolak',
                        icon: Icons.close,
                        isOutline: true,
                        color: Colors.red,
                        onPressed: () {},
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

// ─── Tab 5: Topic Change Approval ────────────────────────────
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

  Future<void> _handleReview(String id, bool approve) async {
    try {
      if (approve) {
        await _api.approveTopicChange(id, 'Disetujui oleh pembimbing');
      } else {
        await _api.rejectTopicChange(id, 'Ditolak oleh pembimbing');
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perubahan topik ${approve ? 'disetujui' : 'ditolak'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Gagal: $_error'));
    if (_requests.isEmpty) {
      return const Center(child: Text('Tidak ada permintaan perubahan topik'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final r = _requests[index];
          final currentThesis = r['thesis'] ?? {};
          final student = currentThesis['student'] ?? {};
          final name = student['user']?['fullName'] ?? '-';
          final currentTitle = currentThesis['title'] ?? '-';
          final proposedTitle =
              r['proposedThesis']?['title'] ?? r['proposedTitle'] ?? '-';

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 20, child: Text(name[0])),
                    const SizedBox(width: 12),
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
                  ],
                ),
                const SizedBox(height: 12),
                Text('Judul Lama:', style: AppTextStyles.caption),
                Text(
                  currentTitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Judul Baru:', style: AppTextStyles.caption),
                Text(
                  proposedTitle,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Setujui',
                        icon: Icons.check,
                        onPressed: () =>
                            _handleReview(r['id'].toString(), true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'Tolak',
                        icon: Icons.close,
                        isOutline: true,
                        color: Colors.red,
                        onPressed: () =>
                            _handleReview(r['id'].toString(), false),
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
