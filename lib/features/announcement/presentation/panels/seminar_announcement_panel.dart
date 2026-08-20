import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../seminar/data/models/seminar_models.dart';
import '../../../seminar/presentation/seminar_detail_screen.dart';

class SeminarAnnouncementPanel extends StatefulWidget {
  final UserModel? user;
  final bool canManageAudience;
  final void Function(String seminarId) onOpenSeminar;

  const SeminarAnnouncementPanel({
    super.key,
    required this.canManageAudience,
    required this.onOpenSeminar,
    this.user,
  });

  @override
  State<SeminarAnnouncementPanel> createState() =>
      _SeminarAnnouncementPanelState();
}

class _SeminarAnnouncementPanelState extends State<SeminarAnnouncementPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = SeminarApiService();
  final _searchController = TextEditingController();
  List<SeminarAnnouncement> _announcements = const [];
  bool _isLoading = true;
  String? _error;
  String? _busySeminarId;

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
      final result = await _api.getSeminarAnnouncements();
      if (!mounted) return;
      setState(() => _announcements = result);
    } catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<SeminarAnnouncement> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final items = _announcements.where((item) {
      if (query.isEmpty) return true;
      return item.presenterName.toLowerCase().contains(query) ||
          item.thesisTitle.toLowerCase().contains(query) ||
          item.supervisors.any(
            (supervisor) => supervisor.name.toLowerCase().contains(query),
          );
    }).toList();
    items.sort((a, b) => _dateTimeOf(b).compareTo(_dateTimeOf(a)));
    return items;
  }

  Map<DateTime, List<SeminarAnnouncement>> get _grouped {
    final result = <DateTime, List<SeminarAnnouncement>>{};
    for (final item in _filtered) {
      final date = DateTime.tryParse(item.date)?.toLocal();
      final key = date == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime(date.year, date.month, date.day);
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }

  DateTime _dateTimeOf(SeminarAnnouncement item) {
    final date = DateTime.tryParse(item.date)?.toLocal();
    if (date == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final time = _parseTime(item.startTime);
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.$1 ?? 0,
      time?.$2 ?? 0,
    );
  }

  Future<void> _register(SeminarAnnouncement seminar) async {
    final confirmed = await _confirmAudienceChange(seminar, register: true);
    if (!confirmed) return;
    await _runAudienceChange(
      seminar,
      action: () => _api.registerAsAudience(seminar.id),
      successMessage: 'Berhasil mendaftar seminar.',
    );
  }

  Future<void> _unregister(SeminarAnnouncement seminar) async {
    final confirmed = await _confirmAudienceChange(seminar, register: false);
    if (!confirmed) return;
    await _runAudienceChange(
      seminar,
      action: () => _api.unregisterFromAudience(seminar.id),
      successMessage: 'Pendaftaran seminar berhasil dibatalkan.',
    );
  }

  Future<bool> _confirmAudienceChange(
    SeminarAnnouncement seminar, {
    required bool register,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(register ? 'Daftar Seminar?' : 'Batalkan Pendaftaran?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue(label: 'Presenter', value: seminar.presenterName),
                _KeyValue(label: 'Judul TA', value: seminar.thesisTitle),
                _KeyValue(label: 'Tanggal', value: _dateLabel(seminar.date)),
                _KeyValue(
                  label: 'Waktu',
                  value: _timeRange(seminar.startTime, seminar.endTime),
                ),
                if (seminar.room != null)
                  _KeyValue(label: 'Ruangan', value: seminar.room!.name),
                const SizedBox(height: 8),
                Text(
                  register
                      ? 'Kehadiran akan tercatat setelah diverifikasi oleh dosen pembimbing.'
                      : 'Anda dapat mendaftar ulang selama seminar belum berlangsung.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(register ? 'Daftar' : 'Batalkan Pendaftaran'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runAudienceChange(
    SeminarAnnouncement seminar, {
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    setState(() => _busySeminarId = seminar.id);
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage, AppColors.successDark);
      await _load();
    } catch (exception) {
      if (mounted) {
        _showMessage('Tindakan gagal: $exception', AppColors.destructive);
      }
    } finally {
      if (mounted) setState(() => _busySeminarId = null);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final groups = _grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
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
              hintText: 'Cari mahasiswa, judul, atau pembimbing…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? _EmptyView(
                  onRefresh: _load,
                  searching: _searchController.text.trim().isNotEmpty,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      4,
                      AppSpacing.pagePadding,
                      AppSpacing.lg,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (_, index) {
                      final group = groups[index];
                      return _DateGroup(
                        date: group.key,
                        items: group.value,
                        canManageAudience: widget.canManageAudience,
                        busySeminarId: _busySeminarId,
                        onOpen: widget.onOpenSeminar,
                        onRegister: _register,
                        onUnregister: _unregister,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<SeminarAnnouncement> items;
  final bool canManageAudience;
  final String? busySeminarId;
  final ValueChanged<String> onOpen;
  final ValueChanged<SeminarAnnouncement> onRegister;
  final ValueChanged<SeminarAnnouncement> onUnregister;

  const _DateGroup({
    required this.date,
    required this.items,
    required this.canManageAudience,
    required this.busySeminarId,
    required this.onOpen,
    required this.onRegister,
    required this.onUnregister,
  });

  @override
  Widget build(BuildContext context) {
    final unknown = date.millisecondsSinceEpoch == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              unknown ? 'Tanggal belum tersedia' : formatDateIndonesian(date),
              style: AppTextStyles.label,
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            radius: 16,
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _SeminarCard(
                    seminar: items[index],
                    canManageAudience: canManageAudience,
                    busy: busySeminarId == items[index].id,
                    onTap: () => onOpen(items[index].id),
                    onRegister: () => onRegister(items[index]),
                    onUnregister: () => onUnregister(items[index]),
                  ),
                  if (index != items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeminarCard extends StatelessWidget {
  final SeminarAnnouncement seminar;
  final bool canManageAudience;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onRegister;
  final VoidCallback onUnregister;

  const _SeminarCard({
    required this.seminar,
    required this.canManageAudience,
    required this.busy,
    required this.onTap,
    required this.onRegister,
    required this.onUnregister,
  });

  @override
  Widget build(BuildContext context) {
    final finalized =
        seminar.resultFinalizedAt != null || seminar.status.isFinal;
    final supervisor = seminar.supervisors.isEmpty
        ? null
        : seminar.supervisors.first;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(seminar.presenterName, style: AppTextStyles.label),
                AppBadge(
                  label: seminarStatusLabel(seminar.status.value),
                  variant: seminarStatusVariant(seminar.status.value),
                ),
                if (seminar.isOwn)
                  const AppBadge(
                    label: 'Seminar Anda',
                    variant: BadgeVariant.outline,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              seminar.thesisTitle,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Pill(
                  icon: Icons.schedule,
                  text: _timeRange(seminar.startTime, seminar.endTime),
                ),
                if (seminar.room != null)
                  _Pill(icon: Icons.place_outlined, text: seminar.room!.name)
                else if (seminar.meetingLink != null)
                  const _Pill(icon: Icons.videocam_outlined, text: 'Daring'),
              ],
            ),
            if (supervisor != null) ...[
              const SizedBox(height: 8),
              _PersonLine(label: 'Pembimbing', value: supervisor.name),
            ],
            for (final examiner in seminar.examiners)
              _PersonLine(
                label: 'Penguji ${examiner.order}',
                value: examiner.name,
              ),
            if (canManageAudience) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PresenceBadge(
                      seminar: seminar,
                      finalized: finalized,
                    ),
                  ),
                  if (seminar.canRegister)
                    FilledButton(
                      onPressed: busy ? null : onRegister,
                      child: busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Daftar'),
                    )
                  else if (seminar.canUnregister)
                    OutlinedButton(
                      onPressed: busy ? null : onUnregister,
                      child: busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Batalkan'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresenceBadge extends StatelessWidget {
  final SeminarAnnouncement seminar;
  final bool finalized;

  const _PresenceBadge({required this.seminar, required this.finalized});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch ((
      seminar.isOwn,
      seminar.isRegistered,
      seminar.isPresent,
      finalized,
      seminar.isPast,
    )) {
      (true, _, _, _, _) => (
        'Seminar Anda',
        AppColors.primary,
        Icons.school_outlined,
      ),
      (_, true, true, _, _) => (
        'Hadir',
        AppColors.successDark,
        Icons.check_circle_outline,
      ),
      (_, true, false, true, _) => (
        'Tidak Hadir',
        AppColors.destructive,
        Icons.close_rounded,
      ),
      (_, true, false, false, _) => (
        'Terdaftar',
        AppColors.warningDark,
        Icons.how_to_reg_outlined,
      ),
      (_, false, _, _, true) => (
        'Selesai',
        AppColors.textSecondary,
        Icons.event_available_outlined,
      ),
      _ => ('Belum daftar', AppColors.textSecondary, Icons.person_add_alt),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PersonLine extends StatelessWidget {
  final String label;
  final String value;

  const _PersonLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: AppTextStyles.caption,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final bool searching;

  const _EmptyView({required this.onRefresh, required this.searching});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.event_busy_outlined,
            size: 56,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            searching
                ? 'Tidak ada seminar yang cocok dengan pencarian.'
                : 'Belum ada pengumuman seminar hasil.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
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
            const SizedBox(height: 10),
            Text(message, style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
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

(int, int)? _parseTime(String? value) {
  if (value == null || value.isEmpty) return null;
  final plain = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
  if (plain != null) {
    return (int.parse(plain.group(1)!), int.parse(plain.group(2)!));
  }
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : (parsed.hour, parsed.minute);
}

String _timeRange(String? start, String? end) {
  String label(String? value) {
    final time = _parseTime(value);
    if (time == null) return '--:--';
    return '${time.$1.toString().padLeft(2, '0')}.${time.$2.toString().padLeft(2, '0')}';
  }

  return '${label(start)}–${label(end)} WIB';
}

String _dateLabel(String value) {
  final date = DateTime.tryParse(value);
  return date == null ? value : formatDateIndonesian(date.toLocal());
}
