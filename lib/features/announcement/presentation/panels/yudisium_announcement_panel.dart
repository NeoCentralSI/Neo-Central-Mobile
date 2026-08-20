import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/yudisium_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../yudisium/data/models/yudisium_models.dart';

/// Public announcement board for completed/closed yudisium periods.
class YudisiumAnnouncementPanel extends StatefulWidget {
  final UserModel? user;

  const YudisiumAnnouncementPanel({super.key, this.user});

  @override
  State<YudisiumAnnouncementPanel> createState() =>
      _YudisiumAnnouncementPanelState();
}

class _YudisiumAnnouncementPanelState extends State<YudisiumAnnouncementPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = YudisiumApiService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<YudisiumAnnouncement> _announcements = const [];

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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final announcements = await _api.getYudisiumAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.toString();
        _isLoading = false;
      });
    }
  }

  List<_FilteredAnnouncement> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final values = <_FilteredAnnouncement>[];
    for (final announcement in _announcements) {
      final eventMatches =
          query.isEmpty || announcement.name.toLowerCase().contains(query);
      final participants =
          (query.isEmpty || eventMatches
                  ? announcement.participants
                  : announcement.participants.where(
                      (participant) =>
                          participant.studentName.toLowerCase().contains(
                            query,
                          ) ||
                          participant.studentNim.toLowerCase().contains(
                            query,
                          ) ||
                          participant.thesisTitle.toLowerCase().contains(query),
                    ))
              .toList();
      participants.sort(_compareParticipants);
      if (eventMatches || participants.isNotEmpty) {
        values.add(
          _FilteredAnnouncement(
            announcement: announcement,
            participants: participants,
          ),
        );
      }
    }
    values.sort(
      (a, b) => _compareNullableDatesDesc(
        a.announcement.eventDate,
        b.announcement.eventDate,
      ),
    );
    return values;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final items = _filtered;
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
              hintText: 'Cari periode, mahasiswa, NIM, atau judul…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyView(
                  filtered: _searchController.text.trim().isNotEmpty,
                  onRefresh: _load,
                )
              : RefreshIndicator(
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
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.base),
                    itemBuilder: (_, index) =>
                        _AnnouncementCard(value: items[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilteredAnnouncement {
  final YudisiumAnnouncement announcement;
  final List<YudisiumAnnouncementParticipant> participants;

  const _FilteredAnnouncement({
    required this.announcement,
    required this.participants,
  });
}

class _AnnouncementCard extends StatefulWidget {
  final _FilteredAnnouncement value;

  const _AnnouncementCard({required this.value});

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  static const _initialLimit = 10;
  bool _expanded = true;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.value.announcement;
    final participants = widget.value.participants;
    final hasOverflow = participants.length > _initialLimit;
    final visible = hasOverflow && !_showAll
        ? participants.take(_initialLimit).toList()
        : participants;
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(event.name, style: AppTextStyles.label),
                      ),
                      AppBadge(
                        label: _eventStatusLabel(event.status),
                        variant: _eventStatusVariant(event.status),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaPill(
                        icon: Icons.calendar_today_outlined,
                        text: _formatDate(event.eventDate),
                      ),
                      if (event.room != null)
                        _MetaPill(
                          icon: Icons.place_outlined,
                          text: event.room!.name,
                        ),
                      _MetaPill(
                        icon: Icons.people_outline,
                        text: '${participants.length} peserta',
                        highlighted: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (participants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Belum ada peserta yang ditetapkan.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              for (var index = 0; index < visible.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                _ParticipantRow(index: index + 1, participant: visible[index]),
              ],
            if (hasOverflow)
              TextButton.icon(
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(_showAll ? Icons.unfold_less : Icons.unfold_more),
                label: Text(
                  _showAll
                      ? 'Tampilkan lebih sedikit'
                      : 'Lihat semua ${participants.length} peserta',
                ),
              ),
            if (event.notes?.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                color: AppColors.surfaceSecondary,
                child: Text(
                  'Catatan: ${event.notes}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final int index;
  final YudisiumAnnouncementParticipant participant;

  const _ParticipantRow({required this.index, required this.participant});

  @override
  Widget build(BuildContext context) {
    final finalized = participant.status == YudisiumParticipantStatus.finalized;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('$index', style: AppTextStyles.labelSmall),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participant.studentName, style: AppTextStyles.label),
                Text(participant.studentNim, style: AppTextStyles.caption),
                if (participant.thesisTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    participant.thesisTitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 7),
          AppBadge(
            label: finalized ? 'Lulus' : 'Peserta',
            variant: finalized ? BadgeVariant.success : BadgeVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlighted;

  const _MetaPill({
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primaryDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool filtered;
  final Future<void> Function() onRefresh;

  const _EmptyView({required this.filtered, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.emoji_events_outlined,
            size: 52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            filtered
                ? 'Tidak ada pengumuman yang cocok.'
                : 'Belum ada pengumuman hasil yudisium.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.destructive,
            ),
            const SizedBox(height: 12),
            Text('Gagal memuat pengumuman', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

int _compareParticipants(
  YudisiumAnnouncementParticipant a,
  YudisiumAnnouncementParticipant b,
) {
  final firstDate = a.registeredAt;
  final secondDate = b.registeredAt;
  if (firstDate != null && secondDate != null) {
    final byDate = firstDate.compareTo(secondDate);
    if (byDate != 0) return byDate;
  } else if (firstDate == null && secondDate != null) {
    return 1;
  } else if (firstDate != null && secondDate == null) {
    return -1;
  }
  return a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
}

int _compareNullableDatesDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${days[local.weekday - 1]}, ${local.day} '
      '${months[local.month - 1]} ${local.year}';
}

String _eventStatusLabel(YudisiumDisplayStatus status) => switch (status) {
  YudisiumDisplayStatus.draft => 'Draft',
  YudisiumDisplayStatus.open => 'Pendaftaran dibuka',
  YudisiumDisplayStatus.closed => 'Pendaftaran ditutup',
  YudisiumDisplayStatus.ongoing => 'Berlangsung',
  YudisiumDisplayStatus.completed => 'Selesai',
};

BadgeVariant _eventStatusVariant(YudisiumDisplayStatus status) =>
    switch (status) {
      YudisiumDisplayStatus.open ||
      YudisiumDisplayStatus.ongoing => BadgeVariant.primary,
      YudisiumDisplayStatus.completed => BadgeVariant.success,
      YudisiumDisplayStatus.closed => BadgeVariant.warning,
      YudisiumDisplayStatus.draft => BadgeVariant.secondary,
    };
