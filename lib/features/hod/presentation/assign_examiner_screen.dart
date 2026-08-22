import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/examiner_assignment_api_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../defence/presentation/defence_detail_screen.dart';
import '../../seminar/presentation/seminar_detail_screen.dart';
import 'assign_examiner_form_screen.dart';

/// Tetapkan Penguji — Head of Department screen.
///
/// Two tabs (Seminar Hasil / Sidang TA). Each tab lists every seminar/defence
/// awaiting examiner assignment or reassignment, with a status badge and a
/// tap-to-assign action that pushes [AssignExaminerFormScreen] full-screen.
class AssignExaminerScreen extends StatefulWidget {
  final UserModel? user;

  /// Either 'seminar_hasil' or 'sidang_ta'. Used by deep-link from FCM tap.
  final String initialTab;

  const AssignExaminerScreen({
    super.key,
    this.user,
    this.initialTab = 'seminar_hasil',
  });

  @override
  State<AssignExaminerScreen> createState() => _AssignExaminerScreenState();
}

class _AssignExaminerScreenState extends State<AssignExaminerScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'sidang_ta' ? 1 : 0,
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
      drawer: AppDrawer(user: widget.user, activeRoute: 'assign_examiner'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AssignmentListTab(kind: 'seminar', user: widget.user),
                  _AssignmentListTab(kind: 'defence', user: widget.user),
                ],
              ),
            ),
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
        4,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu,
                        color: Colors.white, size: 24),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tetapkan Penguji',
                  style: AppTextStyles.h1
                      .copyWith(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Seminar Hasil'),
              Tab(text: 'Sidang TA'),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Assignment list tab
// ════════════════════════════════════════════════════════════════

class _AssignmentListTab extends StatefulWidget {
  /// 'seminar' or 'defence'.
  final String kind;
  final UserModel? user;
  const _AssignmentListTab({required this.kind, this.user});

  @override
  State<_AssignmentListTab> createState() => _AssignmentListTabState();
}

class _AssignmentListTabState extends State<_AssignmentListTab>
    with AutomaticKeepAliveClientMixin {
  final _api = ExaminerAssignmentApiService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String _statusFilter = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = widget.kind == 'seminar'
          ? await _api.getAssignmentSeminars()
          : await _api.getAssignmentDefences();
      if (!mounted) return;
      setState(() {
        _items = list;
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

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _items.where((it) {
      if (_statusFilter.isNotEmpty &&
          it['assignmentStatus']?.toString() != _statusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final name = (it['studentName'] ?? '').toString().toLowerCase();
      final nim = (it['studentNim'] ?? '').toString().toLowerCase();
      final title = (it['thesisTitle'] ?? '').toString().toLowerCase();
      return name.contains(q) || nim.contains(q) || title.contains(q);
    }).toList();
  }

  Future<void> _openForm(Map<String, dynamic> item) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssignExaminerFormScreen(
          kind: widget.kind,
          parentId: item['id'].toString(),
          studentName: (item['studentName'] ?? '-').toString(),
          studentNim: (item['studentNim'] ?? '-').toString(),
          thesisTitle: (item['thesisTitle'] ?? '-').toString(),
          existingExaminers: (item['examiners'] as List?)
                  ?.whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              const [],
          rejectedExaminers: (item['rejectedExaminers'] as List?)
                  ?.whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              const [],
        ),
      ),
    );
    if (result == true) _fetch();
  }

  Future<void> _openSeminarDetail(Map<String, dynamic> item) async {
    if (widget.kind != 'seminar') return;
    final id = item['id']?.toString();
    if (id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeminarDetailScreen(
          seminarId: id,
          user: widget.user,
        ),
      ),
    );
    if (mounted) _fetch();
  }

  Future<void> _openDefenceDetail(Map<String, dynamic> item) async {
    if (widget.kind != 'defence') return;
    final id = item['id']?.toString();
    if (id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DefenceDetailScreen(
          defenceId: id,
          user: widget.user,
        ),
      ),
    );
    if (mounted) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari mahasiswa / judul…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final opt in _statusOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opt.label),
                      selected: _statusFilter == opt.value,
                      onSelected: (_) {
                        setState(() => _statusFilter = opt.value);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.18),
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: _statusFilter == opt.value
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _statusFilter == opt.value
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      backgroundColor: AppColors.surface,
                    ),
                  ),
              ],
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
                _error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final data = _filtered;
    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.fact_check_outlined,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _items.isEmpty
                    ? 'Belum ada ${widget.kind == 'seminar' ? 'seminar' : 'sidang'} '
                        'yang perlu ditetapkan penguji.'
                    : 'Tidak ada hasil yang cocok.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          4,
          AppSpacing.pagePadding,
          AppSpacing.lg,
        ),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => _AssignmentCard(
          item: data[i],
          onAction: () => _openForm(data[i]),
          onTap: widget.kind == 'seminar'
              ? () => _openSeminarDetail(data[i])
              : () => _openDefenceDetail(data[i]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Card (one row in the list)
// ════════════════════════════════════════════════════════════════

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onAction;
  final VoidCallback? onTap;

  const _AssignmentCard({
    required this.item,
    required this.onAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = (item['assignmentStatus'] ?? 'unassigned').toString();
    final examiners = (item['examiners'] as List?) ?? const [];
    final supervisors = (item['supervisors'] as List?) ?? const [];
    final actionLabel = _actionLabel(status);
    final actionEnabled = actionLabel != null;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['studentName'] ?? '-').toString(),
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (item['studentNim'] ?? '-').toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (item['thesisTitle'] ?? '-').toString(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (supervisors.isNotEmpty) ...[
            _PeopleSection(
              icon: Icons.supervisor_account_outlined,
              label: 'Pembimbing',
              names: supervisors
                  .whereType<Map>()
                  .map((s) => (s['name'] ?? '-').toString())
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          _ExaminersSection(examiners: examiners),
          if (actionEnabled) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(actionLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _actionLabel(String status) {
    switch (status) {
      case 'unassigned':
      case 'rejected':
        return 'Tetapkan Penguji';
      case 'partially_rejected':
        return 'Ganti Penguji';
      case 'pending':
      case 'confirmed':
        return 'Ubah Penguji';
      default:
        return null;
    }
  }
}

class _PeopleSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> names;
  const _PeopleSection({
    required this.icon,
    required this.label,
    required this.names,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 6),
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
              for (var i = 0; i < names.length; i++)
                Text(
                  '${i + 1}. ${names[i]}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExaminersSection extends StatelessWidget {
  final List examiners;
  const _ExaminersSection({required this.examiners});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.gavel_outlined,
            size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Penguji',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              if (examiners.isEmpty)
                Text(
                  'Belum ada penguji',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              for (var i = 0; i < examiners.length; i++)
                _ExaminerRow(
                  index: i + 1,
                  examiner: Map<String, dynamic>.from(examiners[i] as Map),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExaminerRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> examiner;
  const _ExaminerRow({required this.index, required this.examiner});

  @override
  Widget build(BuildContext context) {
    final name = (examiner['lecturerName'] ?? '-').toString();
    final status = (examiner['availabilityStatus'] ?? 'pending').toString();

    IconData icon;
    Color color;
    switch (status) {
      case 'available':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'unavailable':
        icon = Icons.cancel;
        color = AppColors.destructive;
        break;
      default:
        icon = Icons.schedule;
        color = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$index. $name',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 13, color: color),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final variant = _statusVariant(status);
    return AppBadge(label: label, variant: variant);
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'unassigned':
        return 'Belum Ditetapkan';
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      case 'partially_rejected':
        return 'Sebagian Ditolak';
      case 'confirmed':
        return 'Ditetapkan';
      case 'finished':
        return 'Selesai';
      default:
        return s;
    }
  }

  static BadgeVariant _statusVariant(String s) {
    switch (s) {
      case 'unassigned':
      case 'partially_rejected':
        return BadgeVariant.warning;
      case 'pending':
        return BadgeVariant.primary;
      case 'rejected':
        return BadgeVariant.destructive;
      case 'confirmed':
        return BadgeVariant.success;
      case 'finished':
      default:
        return BadgeVariant.secondary;
    }
  }
}

// ─── Filter options ─────────────────────────────────────────────

class _StatusOption {
  final String label;
  final String value;
  const _StatusOption(this.label, this.value);
}

const List<_StatusOption> _statusOptions = [
  _StatusOption('Semua', ''),
  _StatusOption('Belum Ditetapkan', 'unassigned'),
  _StatusOption('Menunggu', 'pending'),
  _StatusOption('Sebagian Ditolak', 'partially_rejected'),
  _StatusOption('Ditolak', 'rejected'),
  _StatusOption('Ditetapkan', 'confirmed'),
  _StatusOption('Selesai', 'finished'),
];
