import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/seminar_api_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../seminar/presentation/seminar_detail_screen.dart'
    show seminarStatusLabel, seminarStatusVariant;

/// Pengumuman Seminar Hasil panel.
///
/// Student: list of announced seminars (past registration deadline) with
/// search, register / cancel registration, and tap-to-open detail.
/// Lecturer / HoD: backend endpoint is MAHASISWA-only, so we render a
/// friendly notice instead of issuing the request.
class SeminarAnnouncementPanel extends StatefulWidget {
  final UserModel? user;
  final bool isStudent;
  final void Function(String seminarId) onOpenSeminar;

  const SeminarAnnouncementPanel({
    super.key,
    required this.isStudent,
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
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  String? _busyRegisterId;
  String? _busyCancelId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.isStudent) _fetch();
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
      final res = await _api.getStudentAnnouncements();
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

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((s) {
      final presenter = (s['presenterName'] ?? '').toString().toLowerCase();
      final title = (s['thesisTitle'] ?? '').toString().toLowerCase();
      final supervisors = ((s['supervisors'] as List?) ?? const [])
          .whereType<Map>()
          .map((sv) => (sv['name'] ?? '').toString().toLowerCase())
          .toList();
      return presenter.contains(q) ||
          title.contains(q) ||
          supervisors.any((n) => n.contains(q));
    }).toList();
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.destructive : AppColors.successDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmRegister(Map<String, dynamic> seminar) async {
    final id = seminar['id']?.toString();
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _RegisterConfirmDialog(seminar: seminar),
    );
    if (confirmed != true) return;
    setState(() => _busyRegisterId = id);
    try {
      await _api.registerAsAudience(id);
      _toast('Berhasil mendaftar seminar.');
      await _fetch();
    } catch (e) {
      _toast('Gagal mendaftar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyRegisterId = null);
    }
  }

  Future<void> _confirmCancel(Map<String, dynamic> seminar) async {
    final id = seminar['id']?.toString();
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CancelConfirmDialog(seminar: seminar),
    );
    if (confirmed != true) return;
    setState(() => _busyCancelId = id);
    try {
      await _api.unregisterFromAudience(id);
      _toast('Pendaftaran dibatalkan.');
      await _fetch();
    } catch (e) {
      _toast('Gagal membatalkan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyCancelId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isStudent) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: AppColors.textTertiary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Pendaftaran Seminar Khusus Mahasiswa',
                style: AppTextStyles.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Pengumuman pendaftaran seminar hasil hanya tersedia untuk '
                'akun mahasiswa. Anda tetap dapat melihat detail seminar '
                'melalui menu Seminar Hasil.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }

    final grouped = _groupByDate(
      _sortedNewestFirst(_filtered),
    );

    return Column(
      children: [
        _buildSearchHeader(),
        Expanded(
          child: grouped.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      4,
                      AppSpacing.pagePadding,
                      AppSpacing.lg,
                    ),
                    itemCount: grouped.length,
                    itemBuilder: (_, i) {
                      final entry = grouped[i];
                      return _DateGroup(
                        date: entry.date,
                        items: entry.items,
                        onTap: (s) =>
                            widget.onOpenSeminar(s['id'].toString()),
                        onRegister: _confirmRegister,
                        onCancel: _confirmCancel,
                        busyRegisterId: _busyRegisterId,
                        busyCancelId: _busyCancelId,
                      );
                    },
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
          hintText: 'Cari mahasiswa / judul / pembimbing…',
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
            Icons.event_busy_outlined,
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
                    ? 'Tidak ada seminar yang cocok dengan pencarian.'
                    : 'Belum ada pengumuman seminar hasil.',
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

  // ─── Sorting / grouping helpers ────────────────────────────────

  List<Map<String, dynamic>> _sortedNewestFirst(
      List<Map<String, dynamic>> items) {
    final list = [...items];
    list.sort((a, b) {
      final ad = _composeDateTime(a);
      final bd = _composeDateTime(b);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return list;
  }

  DateTime? _composeDateTime(Map<String, dynamic> s) {
    try {
      final dateStr = s['date']?.toString();
      if (dateStr == null || dateStr.isEmpty) return null;
      final base = DateTime.parse(dateStr);
      final startStr = s['startTime']?.toString();
      if (startStr == null || startStr.isEmpty) return base;
      final t = DateTime.parse(startStr).toUtc();
      return DateTime(base.year, base.month, base.day, t.hour, t.minute);
    } catch (_) {
      return null;
    }
  }

  List<_DateGroupEntry> _groupByDate(List<Map<String, dynamic>> items) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final s in items) {
      final key = _dayKey(s['date']?.toString());
      map.putIfAbsent(key, () => []).add(s);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map((k) => _DateGroupEntry(date: k, items: map[k] ?? const []))
        .toList();
  }

  String _dayKey(String? iso) {
    if (iso == null || iso.isEmpty) return 'unknown';
    try {
      final d = DateTime.parse(iso).toUtc();
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'unknown';
    }
  }
}

class _DateGroupEntry {
  final String date;
  final List<Map<String, dynamic>> items;
  _DateGroupEntry({required this.date, required this.items});
}

// ════════════════════════════════════════════════════════════════
// Date group block + seminar card
// ════════════════════════════════════════════════════════════════

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onTap;
  final void Function(Map<String, dynamic>) onRegister;
  final void Function(Map<String, dynamic>) onCancel;
  final String? busyRegisterId;
  final String? busyCancelId;

  const _DateGroup({
    required this.date,
    required this.items,
    required this.onTap,
    required this.onRegister,
    required this.onCancel,
    required this.busyRegisterId,
    required this.busyCancelId,
  });

  @override
  Widget build(BuildContext context) {
    final headerLabel = _formatHeader(items.first['date']?.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    headerLabel,
                    style: AppTextStyles.label,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${items.length} seminar',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            radius: 16,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Container(height: 1, color: AppColors.divider),
                  _SeminarCard(
                    seminar: items[i],
                    onTap: () => onTap(items[i]),
                    onRegister: () => onRegister(items[i]),
                    onCancel: () => onCancel(items[i]),
                    isRegistering:
                        busyRegisterId == items[i]['id']?.toString(),
                    isCancelling:
                        busyCancelId == items[i]['id']?.toString(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatHeader(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso).toUtc();
      const dows = [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
      ];
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      // DateTime.weekday: 1 = Monday … 7 = Sunday
      return '${dows[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _SeminarCard extends StatelessWidget {
  final Map<String, dynamic> seminar;
  final VoidCallback onTap;
  final VoidCallback onRegister;
  final VoidCallback onCancel;
  final bool isRegistering;
  final bool isCancelling;

  const _SeminarCard({
    required this.seminar,
    required this.onTap,
    required this.onRegister,
    required this.onCancel,
    required this.isRegistering,
    required this.isCancelling,
  });

  @override
  Widget build(BuildContext context) {
    final status = (seminar['status'] ?? 'scheduled').toString();
    final isOwn = seminar['isOwn'] == true;
    final isPast = seminar['isPast'] == true;
    final isRegistered = seminar['isRegistered'] == true;
    final isPresent = seminar['isPresent'] == true;
    final isFinalizedResult = const ['passed', 'passed_with_revision', 'failed']
        .contains(status);

    final examiners = ((seminar['examiners'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final supervisors = ((seminar['supervisors'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final pembimbing1 = supervisors.firstWhere(
      (s) => (s['role'] ?? '').toString().toLowerCase().contains('1'),
      orElse: () => supervisors.isNotEmpty ? supervisors.first : const {},
    );
    final room = seminar['room'] is Map
        ? Map<String, dynamic>.from(seminar['room'] as Map)
        : null;
    final isOnline =
        room == null && (seminar['meetingLink'] ?? '').toString().isNotEmpty;

    final timeRange = _formatTimeRange(
      seminar['startTime']?.toString(),
      seminar['endTime']?.toString(),
    );

    final (presenceLabel, presenceBg, presenceFg, presenceIcon) = _audienceState(
      isOwn: isOwn,
      isPast: isPast,
      isRegistered: isRegistered,
      isPresent: isPresent,
      isFinalizedResult: isFinalizedResult,
    );

    final showActionRegister =
        !isOwn && status == 'scheduled' && !isPast && !isRegistered;
    final showActionCancel =
        !isOwn && status == 'scheduled' && !isPast && isRegistered;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            (seminar['presenterName'] ?? '-').toString(),
                            style: AppTextStyles.label,
                          ),
                          AppBadge(
                            label: seminarStatusLabel(status),
                            variant: seminarStatusVariant(status),
                          ),
                          if (isOwn)
                            const AppBadge(
                              label: 'Seminar Anda',
                              variant: BadgeVariant.outline,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.menu_book_outlined,
                              size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (seminar['thesisTitle'] ?? '-').toString(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Pill(
                  icon: Icons.schedule,
                  text: timeRange ??
                      (_formatDate(seminar['date']?.toString()) ?? '-'),
                ),
                if (room != null)
                  _Pill(
                    icon: Icons.place_outlined,
                    text: (room['name'] ?? '-').toString(),
                  )
                else if (isOnline)
                  _Pill(
                    icon: Icons.videocam_outlined,
                    text: 'Daring',
                    color: AppColors.infoDark,
                    background: AppColors.infoLight,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (pembimbing1.isNotEmpty)
              _PersonRow(
                label: 'Pembimbing',
                value: (pembimbing1['name'] ?? '-').toString(),
              ),
            for (final e in examiners)
              _PersonRow(
                label: 'Penguji ${e['order'] ?? ''}',
                value: (e['name'] ?? '-').toString(),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: !(isOwn && !isPast && !isRegistered)
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: presenceBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(presenceIcon,
                                  size: 12, color: presenceFg),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  presenceLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    color: presenceFg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                if (showActionRegister)
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: isRegistering ? null : onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isRegistering
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Daftar'),
                    ),
                  )
                else if (showActionCancel)
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: isCancelling ? null : onCancel,
                      icon: isCancelling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.destructive,
                              ),
                            )
                          : const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Batalkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        side: BorderSide(
                          color: AppColors.destructive.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                else if (isPast && !isRegistered && !isOwn)
                  Text(
                    'Selesai',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static (String, Color, Color, IconData) _audienceState({
    required bool isOwn,
    required bool isPast,
    required bool isRegistered,
    required bool isPresent,
    required bool isFinalizedResult,
  }) {
    if (isRegistered) {
      if (isPresent) {
        return ('Hadir', AppColors.successLight, AppColors.successDark,
            Icons.check_circle_outline);
      }
      if (isFinalizedResult) {
        return ('Tidak Hadir', AppColors.destructiveLight,
            AppColors.destructiveDark, Icons.close_rounded);
      }
      return ('Terdaftar', AppColors.warningLight, AppColors.warningDark,
          Icons.how_to_reg_outlined);
    }
    if (isPast) {
      return ('Selesai', AppColors.surfaceSecondary, AppColors.textSecondary,
          Icons.check_circle_outline);
    }
    return ('Belum daftar', AppColors.surfaceSecondary,
        AppColors.textSecondary, Icons.how_to_reg_outlined);
  }

  static String? _formatTimeRange(String? startIso, String? endIso) {
    final s = _extractTime(startIso);
    final e = _extractTime(endIso);
    if (s == null && e == null) return null;
    if (e == null) return '$s WIB';
    return '$s – $e WIB';
  }

  static String? _extractTime(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toUtc();
      return '${d.hour.toString().padLeft(2, '0')}.'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  static String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toUtc();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return null;
    }
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final Color? background;

  const _Pill({
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
        borderRadius: BorderRadius.circular(6),
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

class _PersonRow extends StatelessWidget {
  final String label;
  final String value;
  const _PersonRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Register / cancel confirmation dialogs
// ════════════════════════════════════════════════════════════════

class _RegisterConfirmDialog extends StatelessWidget {
  final Map<String, dynamic> seminar;
  const _RegisterConfirmDialog({required this.seminar});

  @override
  Widget build(BuildContext context) {
    final room = seminar['room'] is Map
        ? Map<String, dynamic>.from(seminar['room'] as Map)
        : null;
    return AlertDialog(
      title: const Text('Daftar Seminar'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _kv('Presenter', (seminar['presenterName'] ?? '-').toString()),
            _kv('Judul TA', (seminar['thesisTitle'] ?? '-').toString()),
            _kv('Tanggal',
                _SeminarCard._formatDate(seminar['date']?.toString()) ?? '-'),
            _kv(
              'Waktu',
              _SeminarCard._formatTimeRange(
                    seminar['startTime']?.toString(),
                    seminar['endTime']?.toString(),
                  ) ??
                  '-',
            ),
            if (room != null) _kv('Ruangan', (room['name'] ?? '-').toString()),
            const SizedBox(height: 10),
            Text(
              'Kehadiran Anda akan tercatat setelah dikonfirmasi oleh dosen '
              'pembimbing mahasiswa yang bersangkutan.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ya, Daftar'),
        ),
      ],
    );
  }
}

class _CancelConfirmDialog extends StatelessWidget {
  final Map<String, dynamic> seminar;
  const _CancelConfirmDialog({required this.seminar});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batalkan Pendaftaran?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _kv('Presenter', (seminar['presenterName'] ?? '-').toString()),
            _kv('Judul TA', (seminar['thesisTitle'] ?? '-').toString()),
            _kv('Tanggal',
                _SeminarCard._formatDate(seminar['date']?.toString()) ?? '-'),
            const SizedBox(height: 10),
            Text(
              'Anda dapat mendaftar ulang selama seminar belum berlangsung.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Tidak, Tetap Hadir'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ya, Batalkan'),
        ),
      ],
    );
  }
}

Widget _kv(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
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
