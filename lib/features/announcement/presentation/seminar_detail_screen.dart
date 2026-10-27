import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/announcement_api_service.dart';
import '../data/announcement_models.dart';
import 'seminar_announcement_tab.dart' show seminarStatusVariant;

/// Detail Seminar Hasil, opened only from Pengumuman.
///
/// Two tabs:
///   • Identitas — Informasi Seminar and Informasi Tugas Akhir.
///   • Peserta   — the audience list. The seminar's own supervisors confirm or
///                 undo attendance, with the same endpoint as the web app.
/// Seminar documents stay on the web app.
class SeminarDetailScreen extends StatefulWidget {
  final String seminarId;
  final UserModel? user;
  final AnnouncementApiService? api;

  const SeminarDetailScreen({
    super.key,
    required this.seminarId,
    this.user,
    this.api,
  });

  @override
  State<SeminarDetailScreen> createState() => _SeminarDetailScreenState();
}

class _SeminarDetailScreenState extends State<SeminarDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnnouncementApiService _api;
  late final TabController _tabController;
  SeminarDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AnnouncementApiService();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _api.getSeminarDetail(widget.seminarId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = errorMessageOf(
          error,
          fallback: 'Detail seminar tidak dapat dimuat.',
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: Column(
        children: [
          GradientHeader(
            title: 'Detail Seminar Hasil',
            subtitle: detail == null ? null : toTitleCase(detail.studentName),
            leading: HeaderIconButton.back(context),
            bottom: HeaderTabBar(
              controller: _tabController,
              labels: const ['Identitas', 'Peserta'],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _detail == null) {
      return ScrollableCenter(
        child: ErrorStateView(
          message: _error ?? 'Detail seminar tidak dapat dimuat.',
          onRetry: _load,
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: _IdentityTab(detail: _detail!),
        ),
        _AudienceTab(
          api: _api,
          detail: _detail!,
          lecturerId: widget.user?.lecturer?.id,
        ),
      ],
    );
  }
}

// ─── Identitas ───────────────────────────────────────────────

class _IdentityTab extends StatelessWidget {
  final SeminarDetail detail;

  const _IdentityTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final day = wibDay(detail.date);
    final start = clockOf(detail.startTime);
    final end = clockOf(detail.endTime);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.base,
      ),
      children: [
        _SectionCard(
          title: 'Informasi Seminar',
          trailing: AppBadge(
            label: seminarStatusLabel(detail.status),
            variant: seminarStatusVariant(detail.status),
            fontSize: 11,
          ),
          children: [
            InfoRow(
              icon: Icons.person_outline,
              label: 'Nama Mahasiswa',
              value: toTitleCase(detail.studentName),
            ),
            InfoRow(
              icon: Icons.badge_outlined,
              label: 'NIM',
              value: detail.studentNim,
            ),
            InfoRow(
              icon: Icons.event_outlined,
              label: 'Tanggal',
              value: day == null ? '-' : formatDateIndonesian(day),
            ),
            InfoRow(
              icon: Icons.schedule,
              label: 'Waktu',
              value: start == null || end == null ? '-' : '$start – $end WIB',
            ),
            InfoRow(
              icon: Icons.place_outlined,
              label: 'Ruangan',
              value: detail.roomName ?? '-',
            ),
            if (detail.meetingLink != null)
              InfoRow(
                icon: Icons.link,
                label: 'Tautan Daring',
                value: detail.meetingLink!,
              ),
            for (final examiner in detail.examiners)
              InfoRow(
                icon: Icons.how_to_reg_outlined,
                label: examiner.role,
                value: toTitleCase(examiner.name),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        _SectionCard(
          title: 'Informasi Tugas Akhir',
          children: [
            InfoRow(
              icon: Icons.menu_book_outlined,
              label: 'Judul',
              value: detail.thesisTitle,
            ),
            for (final supervisor in detail.supervisors)
              InfoRow(
                icon: Icons.school_outlined,
                label: formatRoleName(supervisor.role),
                value: toTitleCase(supervisor.name),
              ),
          ],
        ),
        const FootnoteText('Dokumen seminar tersedia di NeoCentral versi web'),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.h4)),
              ?trailing,
            ],
          ),
          const AppDivider(verticalPadding: AppSpacing.md),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ─── Peserta ─────────────────────────────────────────────────

class _AudienceTab extends StatefulWidget {
  final AnnouncementApiService api;
  final SeminarDetail detail;
  final String? lecturerId;

  const _AudienceTab({
    required this.api,
    required this.detail,
    required this.lecturerId,
  });

  @override
  State<_AudienceTab> createState() => _AudienceTabState();
}

class _AudienceTabState extends State<_AudienceTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  List<SeminarAudience> _items = const [];
  bool _isLoading = true;
  String? _error;
  String? _busyStudentId;

  @override
  bool get wantKeepAlive => true;

  bool get _isSupervisor => widget.detail.isSupervisedBy(widget.lecturerId);

  /// Supervisors confirm attendance once the seminar has started, as on web.
  bool get _canConfirm => _isSupervisor && widget.detail.isAttendanceOpen();

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

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final items = await widget.api.getAudiences(widget.detail.id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = errorMessageOf(
          error,
          fallback: 'Daftar peserta tidak dapat dimuat.',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePresence(SeminarAudience audience) async {
    final studentId = audience.studentId;
    if (studentId == null) return;
    setState(() => _busyStudentId = studentId);
    try {
      await widget.api.setAudiencePresence(
        widget.detail.id,
        studentId,
        present: !audience.isPresent,
      );
      if (!mounted) return;
      _showSnack(
        audience.isPresent
            ? 'Konfirmasi kehadiran dibatalkan.'
            : 'Kehadiran peserta dikonfirmasi.',
        AppColors.successDark,
      );
      await _load(silent: true);
    } catch (error) {
      if (!mounted) return;
      _showSnack(errorMessageOf(error), AppColors.destructive);
    } finally {
      if (mounted) setState(() => _busyStudentId = null);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  List<SeminarAudience> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.nim.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ScrollableCenter(
        child: ErrorStateView(message: _error!, onRetry: _load),
      );
    }
    final items = _filtered;
    final present = _items.where((item) => item.isPresent).length;
    final searching = _searchController.text.trim().isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_items.length} peserta terdaftar',
                style: AppTextStyles.label,
              ),
            ),
            AppBadge(
              label: '$present hadir',
              variant: BadgeVariant.success,
              fontSize: 11,
            ),
          ],
        ),
        if (_isSupervisor) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _canConfirm
                ? 'Centang peserta yang hadir untuk mengonfirmasi kehadirannya.'
                : 'Kehadiran dapat dikonfirmasi setelah seminar dimulai.',
            style: AppTextStyles.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AppSearchField(
          controller: _searchController,
          hintText: 'Cari nama atau NIM peserta...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.base),
        if (items.isEmpty)
          EmptyStateView(
            icon: searching ? Icons.search_off : Icons.groups_outlined,
            title: searching ? 'Tidak Ditemukan' : 'Belum Ada Peserta',
            message: searching
                ? 'Tidak ditemukan peserta yang sesuai pencarian'
                : 'Belum ada mahasiswa yang terdaftar sebagai peserta seminar ini',
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.divider),
                  _AudienceRow(
                    number: i + 1,
                    audience: items[i],
                    canConfirm: _canConfirm && items[i].studentId != null,
                    isBusy: _busyStudentId == items[i].studentId,
                    onToggle: () => _togglePresence(items[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AudienceRow extends StatelessWidget {
  final int number;
  final SeminarAudience audience;
  final bool canConfirm;
  final bool isBusy;
  final VoidCallback onToggle;

  const _AudienceRow({
    required this.number,
    required this.audience,
    required this.canConfirm,
    required this.isBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$number', style: AppTextStyles.labelSmall),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(toTitleCase(audience.name), style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(audience.nim, style: AppTextStyles.caption),
                if (audience.isPresent && audience.approvedByName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Dikonfirmasi oleh ${toTitleCase(audience.approvedByName!)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (canConfirm)
            isBusy
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Checkbox(
                    value: audience.isPresent,
                    activeColor: AppColors.success,
                    onChanged: (_) => onToggle(),
                  )
          else
            AppBadge(
              label: audience.isPresent ? 'Hadir' : 'Terdaftar',
              variant: audience.isPresent
                  ? BadgeVariant.success
                  : BadgeVariant.secondary,
              fontSize: 11,
            ),
        ],
      ),
    );
  }
}
