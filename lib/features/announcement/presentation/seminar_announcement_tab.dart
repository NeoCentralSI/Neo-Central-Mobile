import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/announcement_api_service.dart';
import '../data/announcement_models.dart';
import 'seminar_detail_screen.dart';

/// Pengumuman Seminar Hasil: announced seminars grouped by day, newest first.
class SeminarAnnouncementTab extends StatefulWidget {
  final AnnouncementApiService api;
  final UserModel? user;

  const SeminarAnnouncementTab({super.key, required this.api, this.user});

  @override
  State<SeminarAnnouncementTab> createState() => _SeminarAnnouncementTabState();
}

class _SeminarAnnouncementTabState extends State<SeminarAnnouncementTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  List<SeminarAnnouncement> _items = const [];
  bool _isLoading = true;
  String? _error;
  String? _busyId;

  @override
  bool get wantKeepAlive => true;

  /// Only students register as audience; other roles read the board.
  bool get _isStudent => widget.user?.appRole == UserRole.student;

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
      final items = await widget.api.getSeminarAnnouncements();
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
          fallback: 'Pengumuman seminar tidak dapat dimuat.',
        );
        _isLoading = false;
      });
    }
  }

  List<SeminarAnnouncement> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final items = _items.where((item) {
      if (query.isEmpty) return true;
      return item.presenterName.toLowerCase().contains(query) ||
          item.thesisTitle.toLowerCase().contains(query) ||
          item.supervisors.any((s) => s.name.toLowerCase().contains(query));
    }).toList()..sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return items;
  }

  /// Seminars grouped by WIB day, newest day first.
  List<MapEntry<DateTime?, List<SeminarAnnouncement>>> get _grouped {
    final groups = <DateTime?, List<SeminarAnnouncement>>{};
    for (final item in _filtered) {
      groups.putIfAbsent(wibDay(item.date), () => []).add(item);
    }
    return groups.entries.toList();
  }

  Future<void> _openDetail(SeminarAnnouncement item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeminarDetailScreen(
          seminarId: item.id,
          user: widget.user,
          api: widget.api,
        ),
      ),
    );
    if (mounted) _load(silent: true);
  }

  Future<void> _register(SeminarAnnouncement item) async {
    final confirmed = await _confirm(
      title: 'Daftar Seminar',
      item: item,
      note:
          'Kehadiran Anda akan tercatat setelah dikonfirmasi oleh dosen '
          'pembimbing mahasiswa yang bersangkutan.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Daftar',
    );
    if (confirmed != true) return;
    await _runAction(
      item,
      () => widget.api.registerAsAudience(item.id),
      fallbackSuccess: 'Berhasil mendaftar sebagai peserta seminar.',
    );
  }

  Future<void> _unregister(SeminarAnnouncement item) async {
    final confirmed = await _confirm(
      title: 'Batalkan Pendaftaran?',
      item: item,
      note: 'Anda dapat mendaftar ulang selama seminar belum berlangsung.',
      cancelLabel: 'Tidak, Tetap Hadir',
      confirmLabel: 'Ya, Batalkan',
      destructive: true,
    );
    if (confirmed != true) return;
    await _runAction(
      item,
      () => widget.api.unregisterFromAudience(item.id),
      fallbackSuccess: 'Pendaftaran berhasil dibatalkan.',
    );
  }

  Future<void> _runAction(
    SeminarAnnouncement item,
    Future<String?> Function() action, {
    required String fallbackSuccess,
  }) async {
    setState(() => _busyId = item.id);
    try {
      final message = await action();
      if (!mounted) return;
      _showSnack(message ?? fallbackSuccess, AppColors.successDark);
      await _load(silent: true);
    } catch (error) {
      if (!mounted) return;
      _showSnack(errorMessageOf(error), AppColors.destructive);
    } finally {
      if (mounted) setState(() => _busyId = null);
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

  Future<bool?> _confirm({
    required String title,
    required SeminarAnnouncement item,
    required String note,
    required String cancelLabel,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppTextStyles.h4),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField('Penyaji', toTitleCase(item.presenterName)),
              _DialogField('Judul Tugas Akhir', item.thesisTitle),
              _DialogField('Tanggal', _dateText(item.date)),
              _DialogField('Waktu', _timeText(item)),
              if (item.roomName != null)
                _DialogField('Ruangan', item.roomName!),
              const SizedBox(height: AppSpacing.xs),
              Text(note, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: destructive ? AppColors.destructive : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ScrollableCenter(
        child: ErrorStateView(message: _error!, onRetry: _load),
      );
    }
    final groups = _grouped;
    final searching = _searchController.text.trim().isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          _isStudent
              ? 'Jadwal seminar hasil mahasiswa yang telah ditetapkan'
              : 'Jadwal seminar hasil mahasiswa yang telah diumumkan',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        AppSearchField(
          controller: _searchController,
          hintText: 'Cari nama mahasiswa atau judul TA...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.base),
        if (groups.isEmpty)
          EmptyStateView(
            icon: searching ? Icons.search_off : Icons.campaign_outlined,
            title: searching ? 'Tidak Ditemukan' : 'Belum Ada Pengumuman',
            message: searching
                ? 'Tidak ditemukan seminar yang sesuai pencarian'
                : 'Belum ada pengumuman seminar hasil',
          )
        else
          for (final group in groups) ...[
            _DayHeader(day: group.key, count: group.value.length),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < group.value.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.divider),
                    _SeminarRow(
                      item: group.value[i],
                      isStudent: _isStudent,
                      isBusy: _busyId == group.value[i].id,
                      onTap: () => _openDetail(group.value[i]),
                      onRegister: () => _register(group.value[i]),
                      onUnregister: () => _unregister(group.value[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}

String _dateText(DateTime? date) {
  final day = wibDay(date);
  return day == null ? '-' : formatDateIndonesian(day);
}

String _timeText(SeminarAnnouncement item) {
  final start = clockOf(item.startTime);
  final end = clockOf(item.endTime);
  if (start == null || end == null) return _dateText(item.date);
  return '$start – $end WIB';
}

BadgeVariant seminarStatusVariant(String status) => switch (status) {
  'scheduled' => BadgeVariant.info,
  'ongoing' => BadgeVariant.warning,
  'passed' => BadgeVariant.success,
  'passed_with_revision' => BadgeVariant.warning,
  'failed' => BadgeVariant.destructive,
  'cancelled' => BadgeVariant.outline,
  _ => BadgeVariant.secondary,
};

class _DayHeader extends StatelessWidget {
  final DateTime? day;
  final int count;

  const _DayHeader({required this.day, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.event_outlined, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            day == null
                ? 'Tanggal belum ditentukan'
                : formatDateIndonesian(day!),
            style: AppTextStyles.label,
          ),
        ),
        AppBadge(label: '$count seminar', fontSize: 11),
      ],
    );
  }
}

class _SeminarRow extends StatelessWidget {
  final SeminarAnnouncement item;
  final bool isStudent;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onRegister;
  final VoidCallback onUnregister;

  const _SeminarRow({
    required this.item,
    required this.isStudent,
    required this.isBusy,
    required this.onTap,
    required this.onRegister,
    required this.onUnregister,
  });

  @override
  Widget build(BuildContext context) {
    final audience = isStudent ? item.audienceState : null;
    final accent = item.isUpcoming
        ? AppColors.primary
        : (item.isPast ? AppColors.divider : AppColors.success);
    final mainSupervisor = item.mainSupervisor;
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(_timeText(item), style: AppTextStyles.labelSmall),
                        if (item.roomName != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.roomName!,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          toTitleCase(item.presenterName),
                          style: AppTextStyles.label,
                        ),
                        AppBadge(
                          label: seminarStatusLabel(item.status),
                          variant: seminarStatusVariant(item.status),
                          fontSize: 11,
                        ),
                        if (item.isOwn)
                          const AppBadge(
                            label: 'Seminar Anda',
                            variant: BadgeVariant.outline,
                            fontSize: 11,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.thesisTitle,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mainSupervisor != null ||
                        item.examiners.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      if (mainSupervisor != null)
                        _PersonLine('Pembimbing', mainSupervisor.name),
                      for (final examiner in item.examiners)
                        _PersonLine(examiner.role, examiner.name),
                    ],
                    if (audience != null ||
                        item.canRegister ||
                        item.canUnregister) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          if (audience != null)
                            AppBadge(
                              label: audience.label,
                              variant: _audienceVariant(audience),
                              fontSize: 11,
                            ),
                          const Spacer(),
                          if (isStudent && item.canRegister)
                            _ActionButton(
                              label: 'Daftar',
                              busyLabel: 'Mendaftar...',
                              isBusy: isBusy,
                              onPressed: onRegister,
                            ),
                          if (isStudent && item.canUnregister)
                            _ActionButton(
                              label: 'Batalkan',
                              busyLabel: 'Membatalkan...',
                              isBusy: isBusy,
                              destructive: true,
                              onPressed: onUnregister,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BadgeVariant _audienceVariant(AudienceState state) => switch (state) {
    AudienceState.present => BadgeVariant.success,
    AudienceState.absent => BadgeVariant.destructive,
    AudienceState.registered => BadgeVariant.warning,
    AudienceState.finished ||
    AudienceState.notRegistered => BadgeVariant.secondary,
  };
}

class _PersonLine extends StatelessWidget {
  final String role;
  final String name;

  const _PersonLine(this.role, this.name);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$role: ',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            TextSpan(
              text: toTitleCase(name),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String busyLabel;
  final bool isBusy;
  final bool destructive;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.busyLabel,
    required this.isBusy,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.destructive : AppColors.primary;
    final text = Text(
      isBusy ? busyLabel : label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
      ),
    );
    if (destructive) {
      return OutlinedButton(
        onPressed: isBusy ? null : onPressed,
        style: style.copyWith(
          foregroundColor: WidgetStatePropertyAll(color),
          side: WidgetStatePropertyAll(BorderSide(color: color)),
        ),
        child: text,
      );
    }
    return FilledButton(
      onPressed: isBusy ? null : onPressed,
      style: style.copyWith(backgroundColor: WidgetStatePropertyAll(color)),
      child: text,
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final String value;

  const _DialogField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.label),
        ],
      ),
    );
  }
}
