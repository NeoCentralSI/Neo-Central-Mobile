import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/services/seminar_api_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/widgets/shared_widgets.dart';
import 'examiner_response_dialog.dart';

/// Seminar Hasil — lecturer (and HoD acting as lecturer) view.
///
/// Two tabs:
///   • Mahasiswa Bimbingan — seminars where the user is a supervisor
///   • Menguji Mahasiswa   — seminars where the user is an examiner
///
/// FCM notifications of type `seminar_examiner_assigned` deep-link straight
/// into the "Menguji Mahasiswa" tab (see `MainShell._onLecturerNotificationOpened`).
class LecturerSeminarScreen extends StatefulWidget {
  final UserModel? user;

  /// Either `'mahasiswa_bimbingan'` (default) or `'menguji_mahasiswa'`.
  final String initialTab;

  const LecturerSeminarScreen({
    super.key,
    this.user,
    this.initialTab = 'mahasiswa_bimbingan',
  });

  @override
  State<LecturerSeminarScreen> createState() => _LecturerSeminarScreenState();
}

class _LecturerSeminarScreenState extends State<LecturerSeminarScreen>
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
      drawer: AppDrawer(user: widget.user, activeRoute: 'seminar_hasil'),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _SupervisedTab(),
                  _ExaminerRequestsTab(),
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
                  'Seminar Hasil',
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
              Tab(text: 'Mahasiswa Bimbingan'),
              Tab(text: 'Menguji Mahasiswa'),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Mahasiswa Bimbingan tab
// ════════════════════════════════════════════════════════════════

class _SupervisedTab extends StatefulWidget {
  const _SupervisedTab();

  @override
  State<_SupervisedTab> createState() => _SupervisedTabState();
}

class _SupervisedTabState extends State<_SupervisedTab>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

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
      final list = await _api.getSupervisedStudentSeminars();
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
    if (q.isEmpty) return _items;
    return _items.where((it) {
      final name = (it['studentName'] ?? '').toString().toLowerCase();
      final nim = (it['studentNim'] ?? '').toString().toLowerCase();
      final title = (it['thesisTitle'] ?? '').toString().toLowerCase();
      return name.contains(q) || nim.contains(q) || title.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _SearchBar(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _fetch)
                  : _SeminarList(
                      items: _filtered,
                      onRefresh: _fetch,
                      emptyText: _items.isEmpty
                          ? 'Belum ada mahasiswa bimbingan yang '
                              'mendaftar seminar hasil.'
                          : 'Tidak ada hasil yang cocok.',
                      cardBuilder: (item) => _SupervisedCard(item: item),
                    ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Menguji Mahasiswa tab
// ════════════════════════════════════════════════════════════════

class _ExaminerRequestsTab extends StatefulWidget {
  const _ExaminerRequestsTab();

  @override
  State<_ExaminerRequestsTab> createState() => _ExaminerRequestsTabState();
}

class _ExaminerRequestsTabState extends State<_ExaminerRequestsTab>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();
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
      final list = await _api.getExaminerRequests();
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
    final filtered = _items.where((it) {
      if (_statusFilter.isNotEmpty &&
          (it['myExaminerStatus']?.toString() ?? '') != _statusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final name = (it['studentName'] ?? '').toString().toLowerCase();
      final nim = (it['studentNim'] ?? '').toString().toLowerCase();
      final title = (it['thesisTitle'] ?? '').toString().toLowerCase();
      return name.contains(q) || nim.contains(q) || title.contains(q);
    }).toList();

    // Match the web priority sort: pending first, then available, then unavailable.
    const rank = {'pending': 1, 'available': 2, 'unavailable': 3};
    filtered.sort((a, b) {
      final ra = rank[a['myExaminerStatus']?.toString() ?? ''] ?? 9;
      final rb = rank[b['myExaminerStatus']?.toString() ?? ''] ?? 9;
      if (ra != rb) return ra - rb;
      final na = (a['studentName'] ?? '').toString();
      final nb = (b['studentName'] ?? '').toString();
      return na.compareTo(nb);
    });
    return filtered;
  }

  Future<void> _openResponseDialog(Map<String, dynamic> item) async {
    final result = await showExaminerResponseDialog(context, seminar: item);
    if (result == true) {
      await _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _SearchBar(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
        ),
        _FilterChipsRow(
          options: const [
            _FilterOption('Semua', ''),
            _FilterOption('Menunggu', 'pending'),
            _FilterOption('Disetujui', 'available'),
            _FilterOption('Ditolak', 'unavailable'),
          ],
          selected: _statusFilter,
          onChanged: (v) => setState(() => _statusFilter = v),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _fetch)
                  : _SeminarList(
                      items: _filtered,
                      onRefresh: _fetch,
                      emptyText: _items.isEmpty
                          ? 'Belum ada penugasan menguji.'
                          : 'Tidak ada hasil yang cocok.',
                      cardBuilder: (item) => _ExaminerRequestCard(
                        item: item,
                        onTanggapi: () => _openResponseDialog(item),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Cards
// ════════════════════════════════════════════════════════════════

class _SupervisedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SupervisedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final examiners = (item['examiners'] as List?) ?? const [];
    final status = (item['status'] ?? '-').toString();
    final myRole = (item['myRole'] ?? 'Pembimbing').toString();

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _studentHeader(item)),
              _SeminarStatusBadge(status: status),
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
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.badge_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Peran saya: ',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                myRole,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ExaminersSection(examiners: examiners),
          if (_hasSchedule(item)) ...[
            const SizedBox(height: 8),
            _SchedulePill(item: item),
          ],
        ],
      ),
    );
  }

  bool _hasSchedule(Map<String, dynamic> it) =>
      (it['date'] ?? '').toString().isNotEmpty;
}

class _ExaminerRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTanggapi;

  const _ExaminerRequestCard({required this.item, required this.onTanggapi});

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? '-').toString();
    final myStatus = (item['myExaminerStatus'] ?? 'pending').toString();
    final supervisors = (item['supervisors'] as List?) ?? const [];
    final myOrder = item['myExaminerOrder'];
    final isPending = myStatus == 'pending' && item['myExaminerId'] != null;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _studentHeader(item)),
              _MyExaminerStatusBadge(status: myStatus),
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
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.gavel_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Peran saya: ',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Penguji ${myOrder ?? "-"}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _SeminarStatusBadge(status: status),
            ],
          ),
          if (supervisors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PeopleSection(
              icon: Icons.supervisor_account_outlined,
              label: 'Pembimbing',
              names: supervisors
                  .whereType<Map>()
                  .map((s) => (s['name'] ?? '-').toString())
                  .toList(),
            ),
          ],
          if (_hasSchedule(item)) ...[
            const SizedBox(height: 8),
            _SchedulePill(item: item),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onTanggapi,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Tanggapi Penugasan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
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

  bool _hasSchedule(Map<String, dynamic> it) =>
      (it['date'] ?? '').toString().isNotEmpty;
}

// ════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ════════════════════════════════════════════════════════════════

Widget _studentHeader(Map<String, dynamic> item) {
  return Column(
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
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
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

class _SchedulePill extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SchedulePill({required this.item});

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(item['date']?.toString());
    final start = _formatTime(item['startTime']?.toString());
    final end = _formatTime(item['endTime']?.toString());
    final room = item['room'] is Map ? (item['room']['name'] ?? '') : '';
    final scheduleText = [
      if (date != null) date,
      if (start != null) (end != null ? '$start – $end' : start),
      if (room.toString().isNotEmpty) room,
    ].join(' · ');

    if (scheduleText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              scheduleText,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

  static String? _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      if (iso.contains('T')) {
        final d = DateTime.parse(iso);
        return '${d.hour.toString().padLeft(2, '0')}:'
            '${d.minute.toString().padLeft(2, '0')}';
      }
      // Already in HH:MM form
      return iso.length >= 5 ? iso.substring(0, 5) : iso;
    } catch (_) {
      return null;
    }
  }
}

class _SeminarStatusBadge extends StatelessWidget {
  final String status;
  const _SeminarStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _label(status);
    final variant = _variant(status);
    return AppBadge(label: label, variant: variant);
  }

  static String _label(String s) {
    switch (s) {
      case 'registered':
        return 'Terdaftar';
      case 'verified':
        return 'Terverifikasi';
      case 'examiner_assigned':
        return 'Penguji Ditetapkan';
      case 'scheduled':
        return 'Dijadwalkan';
      case 'ongoing':
        return 'Berlangsung';
      case 'passed':
        return 'Lulus';
      case 'passed_with_revision':
        return 'Lulus + Revisi';
      case 'failed':
        return 'Gagal';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return s;
    }
  }

  static BadgeVariant _variant(String s) {
    switch (s) {
      case 'ongoing':
        return BadgeVariant.primary;
      case 'scheduled':
      case 'examiner_assigned':
        return BadgeVariant.warning;
      case 'passed':
      case 'passed_with_revision':
        return BadgeVariant.success;
      case 'failed':
      case 'cancelled':
        return BadgeVariant.destructive;
      case 'verified':
        return BadgeVariant.outline;
      case 'registered':
      default:
        return BadgeVariant.secondary;
    }
  }
}

class _MyExaminerStatusBadge extends StatelessWidget {
  final String status;
  const _MyExaminerStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'available':
        return const AppBadge(
          label: 'Disetujui',
          variant: BadgeVariant.success,
        );
      case 'unavailable':
        return const AppBadge(
          label: 'Ditolak',
          variant: BadgeVariant.destructive,
        );
      case 'pending':
      default:
        return const AppBadge(
          label: 'Menunggu Respons',
          variant: BadgeVariant.warning,
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════
// Layout helpers
// ════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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
    );
  }
}

class _FilterOption {
  final String label;
  final String value;
  const _FilterOption(this.label, this.value);
}

class _FilterChipsRow extends StatelessWidget {
  final List<_FilterOption> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChipsRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final opt in options)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(opt.label),
                  selected: selected == opt.value,
                  onSelected: (_) => onChanged(opt.value),
                  selectedColor: AppColors.primary.withValues(alpha: 0.18),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: selected == opt.value
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected == opt.value
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
    );
  }
}

class _SeminarList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;
  final String emptyText;
  final Widget Function(Map<String, dynamic> item) cardBuilder;

  const _SeminarList({
    required this.items,
    required this.onRefresh,
    required this.emptyText,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding),
                child: Text(
                  emptyText,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
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
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => cardBuilder(items[i]),
      ),
    );
  }
}

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
