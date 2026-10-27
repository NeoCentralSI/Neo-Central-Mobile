import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/announcement_api_service.dart';
import '../data/announcement_models.dart';

/// Pengumuman Hasil Yudisium: each event with its appointed participants,
/// newest event first (as on web).
class YudisiumAnnouncementTab extends StatefulWidget {
  final AnnouncementApiService api;

  const YudisiumAnnouncementTab({super.key, required this.api});

  @override
  State<YudisiumAnnouncementTab> createState() =>
      _YudisiumAnnouncementTabState();
}

class _YudisiumAnnouncementTabState extends State<YudisiumAnnouncementTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  List<YudisiumAnnouncement> _items = const [];
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
      final items = await widget.api.getYudisiumAnnouncements();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = errorMessageOf(
          error,
          fallback: 'Pengumuman yudisium tidak dapat dimuat.',
        );
        _isLoading = false;
      });
    }
  }

  /// Search narrows the participants; an event whose name matches keeps all.
  List<YudisiumAnnouncement> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final result = <YudisiumAnnouncement>[];
    for (final item in _items) {
      if (query.isEmpty || item.name.toLowerCase().contains(query)) {
        result.add(item);
        continue;
      }
      final participants = item.participants
          .where(
            (p) =>
                p.studentName.toLowerCase().contains(query) ||
                p.studentNim.toLowerCase().contains(query) ||
                p.thesisTitle.toLowerCase().contains(query),
          )
          .toList();
      if (participants.isEmpty) continue;
      result.add(
        YudisiumAnnouncement(
          id: item.id,
          name: item.name,
          eventDate: item.eventDate,
          roomName: item.roomName,
          notes: item.notes,
          participants: participants,
        ),
      );
    }
    result.sort((a, b) {
      final aTime = a.eventDate?.millisecondsSinceEpoch ?? 0;
      final bTime = b.eventDate?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return result;
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
    final items = _filtered;
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
          'Daftar mahasiswa yang telah ditetapkan sebagai peserta yudisium',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        AppSearchField(
          controller: _searchController,
          hintText: 'Cari nama mahasiswa, NIM, atau judul TA...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.base),
        if (items.isEmpty)
          EmptyStateView(
            icon: searching ? Icons.search_off : Icons.campaign_outlined,
            title: searching ? 'Tidak Ditemukan' : 'Belum Ada Pengumuman',
            message: searching
                ? 'Tidak ditemukan pengumuman yang sesuai pencarian'
                : 'Belum ada pengumuman hasil yudisium',
          )
        else
          for (final item in items) ...[
            _YudisiumCard(item: item),
            const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}

class _YudisiumCard extends StatelessWidget {
  final YudisiumAnnouncement item;

  const _YudisiumCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final day = wibDay(item.eventDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.event_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(item.name, style: AppTextStyles.label)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: 4,
          children: [
            _Meta(
              Icons.schedule,
              day == null
                  ? 'Tanggal belum ditentukan'
                  : formatDateIndonesian(day),
            ),
            if (item.roomName != null)
              _Meta(Icons.place_outlined, item.roomName!),
            _Meta(Icons.people_outline, '${item.participants.length} peserta'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: item.participants.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Text(
                    'Tidak ada peserta yudisium pada pengumuman ini',
                    style: AppTextStyles.bodySmall,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < item.participants.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.divider),
                      _ParticipantRow(
                        number: i + 1,
                        participant: item.participants[i],
                      ),
                    ],
                  ],
                ),
        ),
        if (item.notes != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Catatan: ',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: item.notes,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final int number;
  final YudisiumParticipant participant;

  const _ParticipantRow({required this.number, required this.participant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text('$number', style: AppTextStyles.labelSmall),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      toTitleCase(participant.studentName),
                      style: AppTextStyles.label,
                    ),
                    AppBadge(
                      label: participant.studentNim,
                      variant: BadgeVariant.outline,
                      fontSize: 11,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(participant.thesisTitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
