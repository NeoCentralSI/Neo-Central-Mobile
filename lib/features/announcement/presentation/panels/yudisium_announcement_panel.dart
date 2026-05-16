import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/yudisium_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Pengumuman Yudisium panel.
///
/// Public list of yudisium events (registration window already closed) with
/// their appointed / finalized participants. Mirrors the web
/// `YudisiumAnnouncement.tsx`.
class YudisiumAnnouncementPanel extends StatefulWidget {
  final UserModel? user;

  const YudisiumAnnouncementPanel({super.key, this.user});

  @override
  State<YudisiumAnnouncementPanel> createState() =>
      _YudisiumAnnouncementPanelState();
}

class _YudisiumAnnouncementPanelState
    extends State<YudisiumAnnouncementPanel>
    with AutomaticKeepAliveClientMixin {
  final _api = YudisiumApiService();
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.getYudisiumAnnouncements();
      if (!mounted) return;
      setState(() {
        _items = res;
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

  /// Mirrors the filter shape on the web `YudisiumAnnouncement.tsx`:
  ///   • if the event name matches the query, keep all participants;
  ///   • otherwise narrow participants down to those that match by
  ///     studentName / studentNim / thesisTitle;
  ///   • drop the event entirely when nothing matches.
  /// Events are sorted by eventDate desc (newest first), matching the web.
  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final scoped = _items.map((y) {
      final participants = ((y['participants'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      if (q.isEmpty) return {...y, 'participants': participants};

      final eventMatches =
          (y['name'] ?? '').toString().toLowerCase().contains(q);
      final filteredParticipants = eventMatches
          ? participants
          : participants.where((p) {
              final pn = (p['studentName'] ?? '').toString().toLowerCase();
              final nim = (p['studentNim'] ?? '').toString().toLowerCase();
              final title = (p['thesisTitle'] ?? '').toString().toLowerCase();
              return pn.contains(q) || nim.contains(q) || title.contains(q);
            }).toList();
      return {...y, 'participants': filteredParticipants};
    }).where((y) {
      if (q.isEmpty) return true;
      final hasParticipants =
          ((y['participants'] as List?) ?? const []).isNotEmpty;
      final eventMatches =
          (y['name'] ?? '').toString().toLowerCase().contains(q);
      return eventMatches || hasParticipants;
    }).toList();

    scoped.sort((a, b) {
      final at = _parseDate(a['eventDate']?.toString());
      final bt = _parseDate(b['eventDate']?.toString());
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return scoped;
  }

  DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }

    final items = _filtered;
    return Column(
      children: [
        _buildSearchHeader(),
        Expanded(
          child: items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
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
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.base),
                    itemBuilder: (_, i) => _EventCard(item: items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.base,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari nama yudisium, mahasiswa, atau judul…',
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

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.emoji_events_outlined,
            size: 56,
            color: AppColors.textTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              child: Text(
                _searchCtrl.text.trim().isNotEmpty
                    ? 'Tidak ada pengumuman yang cocok.'
                    : 'Belum ada pengumuman hasil yudisium.',
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
}

// ════════════════════════════════════════════════════════════════
// Event card (one yudisium event with its participants)
// ════════════════════════════════════════════════════════════════

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _EventCard({required this.item});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  static const _initialParticipantLimit = 10;
  bool _expanded = true;
  bool _showAllParticipants = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final participants = ((item['participants'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final hasOverflow = participants.length > _initialParticipantLimit;
    final visibleParticipants = !_showAllParticipants && hasOverflow
        ? participants.take(_initialParticipantLimit).toList()
        : participants;
    final room = item['room'] is Map
        ? Map<String, dynamic>.from(item['room'] as Map)
        : null;
    final notes = (item['notes'] ?? '').toString();

    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header ────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (item['name'] ?? '-').toString(),
                          style: AppTextStyles.label,
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _MetaPill(
                        icon: Icons.access_time,
                        text: _formatDate(item['eventDate']?.toString()) ?? '-',
                      ),
                      if (room != null)
                        _MetaPill(
                          icon: Icons.place_outlined,
                          text: (room['name'] ?? '-').toString(),
                        ),
                      _MetaPill(
                        icon: Icons.people_outline,
                        text: '${participants.length} Peserta',
                        background:
                            AppColors.primary.withValues(alpha: 0.08),
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Container(height: 1, color: AppColors.divider),
            if (participants.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Belum ada peserta yang ditetapkan.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else ...[
              for (var i = 0; i < visibleParticipants.length; i++) ...[
                if (i > 0)
                  Container(height: 1, color: AppColors.divider),
                _ParticipantRow(
                  index: i + 1,
                  participant: visibleParticipants[i],
                ),
              ],
              if (hasOverflow)
                InkWell(
                  onTap: () => setState(
                      () => _showAllParticipants = !_showAllParticipants),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: AppColors.divider)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAllParticipants
                              ? Icons.unfold_less
                              : Icons.unfold_more,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showAllParticipants
                              ? 'Sembunyikan ${participants.length - _initialParticipantLimit} peserta'
                              : 'Lihat semua ${participants.length} peserta',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (notes.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                  color: AppColors.surfaceSecondary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notes,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      const dows = [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
      ];
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      return '${dows[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return null;
    }
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final Color? background;
  const _MetaPill({
    required this.icon,
    required this.text,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textSecondary;
    final bg = background ?? AppColors.surfaceSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> participant;
  const _ParticipantRow({required this.index, required this.participant});

  @override
  Widget build(BuildContext context) {
    final status = (participant['status'] ?? 'appointed').toString();
    final isFinalized = status == 'finalized';
    final label = isFinalized ? 'LULUS' : 'PESERTA';
    final variant =
        isFinalized ? BadgeVariant.success : BadgeVariant.primary;

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
            child: Text(
              '$index',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (participant['studentName'] ?? '-').toString(),
                  style: AppTextStyles.label,
                ),
                Text(
                  (participant['studentNim'] ?? '-').toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if ((participant['thesisTitle'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (participant['thesisTitle'] ?? '-').toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppBadge(label: label, variant: variant),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.destructive),
            const SizedBox(height: 12),
            Text('Gagal memuat pengumuman',
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
