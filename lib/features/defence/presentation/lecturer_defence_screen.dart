import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/defence_api_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../thesis_shared/data/models/thesis_people_models.dart';
import '../data/models/defence_models.dart';
import 'defence_examiner_response_dialog.dart';
import 'defence_detail_screen.dart';

class LecturerDefenceScreen extends StatefulWidget {
  final UserModel? user;
  final String initialTab;

  const LecturerDefenceScreen({
    super.key,
    this.user,
    this.initialTab = 'mahasiswa_bimbingan',
  });

  @override
  State<LecturerDefenceScreen> createState() => _LecturerDefenceScreenState();
}

class _LecturerDefenceScreenState extends State<LecturerDefenceScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'menguji_mahasiswa' ? 1 : 0,
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
      drawer: AppDrawer(user: widget.user, activeRoute: 'sidang_ta'),
      body: SafeArea(
        child: Column(
          children: [
            _Header(tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LecturerListTab(user: widget.user, examinerView: false),
                  _LecturerListTab(user: widget.user, examinerView: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TabController tabController;

  const _Header({required this.tabController});

  @override
  Widget build(BuildContext context) {
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
                builder: (drawerContext) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sidang TA',
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Mahasiswa Bimbingan'),
              Tab(text: 'Menguji Mahasiswa'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LecturerListTab extends StatefulWidget {
  final UserModel? user;
  final bool examinerView;

  const _LecturerListTab({required this.user, required this.examinerView});

  @override
  State<_LecturerListTab> createState() => _LecturerListTabState();
}

class _LecturerListTabState extends State<_LecturerListTab>
    with AutomaticKeepAliveClientMixin {
  final _api = DefenceApiService();
  final _searchController = TextEditingController();
  List<LecturerDefenceListItem> _items = const [];
  ExaminerAvailabilityStatus? _statusFilter;
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = widget.examinerView
          ? await _api.getExaminerRequests()
          : await _api.getSupervisedStudentDefences();
      if (!mounted) return;
      setState(() => _items = result);
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LecturerDefenceListItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    final result = _items.where((item) {
      if (widget.examinerView &&
          _statusFilter != null &&
          item.myExaminerStatus != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return item.studentName.toLowerCase().contains(query) ||
          item.studentNim.toLowerCase().contains(query) ||
          item.thesisTitle.toLowerCase().contains(query);
    }).toList();
    if (widget.examinerView) {
      const rank = {
        ExaminerAvailabilityStatus.pending: 0,
        ExaminerAvailabilityStatus.available: 1,
        ExaminerAvailabilityStatus.unavailable: 2,
      };
      result.sort((a, b) {
        final statusOrder = (rank[a.myExaminerStatus] ?? 9).compareTo(
          rank[b.myExaminerStatus] ?? 9,
        );
        return statusOrder != 0
            ? statusOrder
            : a.studentName.compareTo(b.studentName);
      });
    }
    return result;
  }

  Future<void> _openDetail(LecturerDefenceListItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DefenceDetailScreen(defenceId: item.id, user: widget.user),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _respond(LecturerDefenceListItem item) async {
    final changed = await showDefenceExaminerResponseDialog(
      context,
      defence: item,
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.base,
            AppSpacing.pagePadding,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari mahasiswa, NIM, atau judul…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (widget.examinerView) _buildFilters(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            selected: _statusFilter == null,
            onTap: () => setState(() => _statusFilter = null),
          ),
          for (final option in const [
            (ExaminerAvailabilityStatus.pending, 'Menunggu'),
            (ExaminerAvailabilityStatus.available, 'Disetujui'),
            (ExaminerAvailabilityStatus.unavailable, 'Ditolak'),
          ])
            _FilterChip(
              label: option.$2,
              selected: _statusFilter == option.$1,
              onTap: () => setState(() => _statusFilter = option.$1),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final items = _filteredItems;
    if (items.isEmpty) {
      return _EmptyList(
        onRefresh: _load,
        message: _items.isEmpty
            ? widget.examinerView
                  ? 'Belum ada penugasan menguji.'
                  : 'Belum ada mahasiswa bimbingan yang mendaftar sidang tugas akhir.'
            : 'Tidak ada hasil yang cocok.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          4,
          AppSpacing.pagePadding,
          AppSpacing.lg,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, index) {
          final item = items[index];
          return _DefenceCard(
            item: item,
            examinerView: widget.examinerView,
            onTap: () => _openDetail(item),
            onRespond: () => _respond(item),
          );
        },
      ),
    );
  }
}

class _DefenceCard extends StatelessWidget {
  final LecturerDefenceListItem item;
  final bool examinerView;
  final VoidCallback onTap;
  final VoidCallback onRespond;

  const _DefenceCard({
    required this.item,
    required this.examinerView,
    required this.onTap,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final pending =
        examinerView &&
        item.myExaminerStatus == ExaminerAvailabilityStatus.pending &&
        item.myExaminerId != null;
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
                      item.studentName,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(item.studentNim, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (examinerView)
                _AvailabilityBadge(status: item.myExaminerStatus)
              else
                AppBadge(
                  label: defenceStatusLabel(item.status.value),
                  variant: defenceStatusVariant(item.status.value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.thesisTitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _RoleLine(item: item, examinerView: examinerView),
          if (examinerView && item.supervisors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PeopleLine(
              label: 'Pembimbing',
              names: item.supervisors.map((person) => person.name).toList(),
            ),
          ],
          if (!examinerView && item.examiners.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PeopleLine(
              label: 'Penguji',
              names: item.examiners
                  .map(
                    (person) =>
                        '${person.lecturerName} (${_availabilityLabel(person.availabilityStatus)})',
                  )
                  .toList(),
            ),
          ],
          if (item.date != null) ...[
            const SizedBox(height: 8),
            _ScheduleLine(item: item),
          ],
          if (pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRespond,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Tanggapi Penugasan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleLine extends StatelessWidget {
  final LecturerDefenceListItem item;
  final bool examinerView;

  const _RoleLine({required this.item, required this.examinerView});

  @override
  Widget build(BuildContext context) {
    final role = examinerView
        ? 'Penguji ${item.myExaminerOrder ?? '-'}'
        : formatRoleName(item.myRole ?? 'Pembimbing');
    return Row(
      children: [
        Icon(
          examinerView ? Icons.gavel_outlined : Icons.badge_outlined,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 6),
        Text('Peran saya: $role', style: AppTextStyles.caption),
        if (examinerView) ...[
          const Spacer(),
          AppBadge(
            label: defenceStatusLabel(item.status.value),
            variant: defenceStatusVariant(item.status.value),
          ),
        ],
      ],
    );
  }
}

class _PeopleLine extends StatelessWidget {
  final String label;
  final List<String> names;

  const _PeopleLine({required this.label, required this.names});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.people_outline,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: ${names.join(', ')}',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

class _ScheduleLine extends StatelessWidget {
  final LecturerDefenceListItem item;

  const _ScheduleLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(item.date!);
    final date = parsedDate == null
        ? item.date!
        : formatDateIndonesian(parsedDate.toLocal());
    final times = [
      item.startTime,
      item.endTime,
    ].whereType<String>().where((value) => value.isNotEmpty).join('–');
    final room = item.room?.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        [date, if (times.isNotEmpty) times, if (room != null) room].join(' • '),
        style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final ExaminerAvailabilityStatus? status;

  const _AvailabilityBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: _availabilityLabel(status),
      variant: switch (status) {
        ExaminerAvailabilityStatus.available => BadgeVariant.success,
        ExaminerAvailabilityStatus.unavailable => BadgeVariant.destructive,
        _ => BadgeVariant.warning,
      },
    );
  }
}

String _availabilityLabel(ExaminerAvailabilityStatus? status) {
  return switch (status) {
    ExaminerAvailabilityStatus.available => 'Disetujui',
    ExaminerAvailabilityStatus.unavailable => 'Ditolak',
    _ => 'Menunggu',
  };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String message;

  const _EmptyList({required this.onRefresh, required this.message});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.inbox_outlined,
            size: 56,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 12),
            Text('Gagal memuat data', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall,
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
