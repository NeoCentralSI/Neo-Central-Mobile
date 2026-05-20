import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/internship_api_service.dart';
import '../../../../core/utils/formatters.dart' as fmt;
import '../../../../core/widgets/app_drawer.dart';
import '../../../notifications/presentation/notification_screen.dart';
import 'seminar_detail_screen.dart';

class InternshipSeminarScreen extends StatefulWidget {
  final UserModel? user;
  const InternshipSeminarScreen({super.key, this.user});

  @override
  State<InternshipSeminarScreen> createState() => _InternshipSeminarScreenState();
}

class _InternshipSeminarScreenState extends State<InternshipSeminarScreen> {
  final InternshipApiService _api = InternshipApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _internship;
  Map<String, dynamic>? _seminar;
  List<dynamic> _allUpcomingSeminars = [];
  List<dynamic> _upcomingSeminars = [];
  List<dynamic> _rooms = [];
  List<dynamic> _eligibleStudents = [];
  bool _isSubmitting = false;
  StateSetter? _sheetSetState;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedRoomId = '';
  String _selectedModeratorId = '';
  String _linkMeeting = '';
  List<String> _selectedMemberIds = [];
  String _moderatorSearch = '';
  String _otherSeminarSearch = '';

  void _refreshSheet(VoidCallback updateFields) {
    updateFields();
    if (mounted) {
      setState(() {});
    }
    _sheetSetState?.call(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getLogbookOverview(),
        _api.getUpcomingSeminars(),
        _api.getEligibleStudents(),
        _api.getRooms(),
      ]);

      final overviewRes = results[0] as Map<String, dynamic>;
      final upcomingRes = results[1] as List<dynamic>;
      final eligibleRes = results[2] as List<dynamic>;
      final roomsRes = results[3] as List<dynamic>;

      if (overviewRes['success'] == true) {
        final data = overviewRes['data'];
        final internship = data['internship'];
        final seminars = internship?['seminars'] as List? ?? [];
        
        setState(() {
          _internship = internship;
          _seminar = seminars.isNotEmpty ? seminars[0] : null;
          _allUpcomingSeminars = upcomingRes;
          // Filter out user's own seminar from upcoming list
          _upcomingSeminars = upcomingRes.where((s) {
            return s['internship']?['id'] != internship?['id'];
          }).toList();
          _eligibleStudents = eligibleRes;
          _rooms = roomsRes;
          _isLoading = false;
        });
      } else {
        throw Exception(overviewRes['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (e is ApiException) {
        errorMessage = e.message;
      }
      setState(() {
        _isLoading = false;
        _error = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSecondary,
        drawer: AppDrawer(user: widget.user, activeRoute: 'internship'),
        appBar: AppBar(
          title: const Text('Seminar Kerja Praktik'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: 'Seminar Saya'),
              Tab(text: 'Seminar Lain'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildErrorState()
                : TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.pagePadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_seminar == null)
                                _buildNoSeminarState()
                              else
                                _buildSeminarDetails(),
                            ],
                          ),
                        ),
                      ),
                      _buildOtherSeminars(),
                    ],
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
          backgroundColor: Colors.amber,
          child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.destructive),
          const SizedBox(height: 16),
          Text('Terjadi Kesalahan', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(_error ?? 'Gagal memuat data', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildNoSeminarState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Pengajuan Seminar',
            style: AppTextStyles.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Anda dapat mengajukan seminar setelah menyelesaikan KP dan mendapatkan persetujuan dari dosen pembimbing.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openRegisterSeminarSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Daftar Seminar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeminarDetails() {
    final status = _seminar!['status'] as String;
    final date = DateTime.tryParse(_seminar!['seminarDate']?.toString() ?? '') ?? DateTime.now();
    final startTime = _seminar!['startTime'];
    final endTime = _seminar!['endTime'];
    final room = _seminar!['room']?['name'] ?? 'TBA';
    final link = _seminar!['linkMeeting'];
    final moderator = _seminar!['moderatorStudent']?['user']?['fullName'] ?? 'TBA';
    final notes = _seminar!['supervisorNotes'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusCard(status),
        const SizedBox(height: 24),
        Text('Informasi Seminar', style: AppTextStyles.h4),
        const SizedBox(height: 16),
        _buildDetailItem(Icons.calendar_today, 'Tanggal', fmt.formatDateIndonesian(date)),
        _buildDetailItem(Icons.access_time, 'Waktu', '${_formatTime(startTime)} - ${_formatTime(endTime)} WIB'),
        _buildDetailItem(Icons.location_on, 'Ruangan', room),
        if (link != null && link.isNotEmpty)
          _buildDetailItem(Icons.link, 'Link Meeting', link, isLink: true),
        _buildDetailItem(Icons.person, 'Moderator', moderator),
        
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Catatan Pembimbing', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              notes,
              style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard(String status) {
    String label = 'Menunggu';
    Color color = Colors.amber;
    IconData icon = Icons.hourglass_empty;

    switch (status) {
      case 'APPROVED':
        label = 'Disetujui';
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'REJECTED':
        label = 'Ditolak / Perlu Revisi';
        color = AppColors.destructive;
        icon = Icons.cancel;
        break;
      case 'COMPLETED':
        label = 'Selesai';
        color = AppColors.info;
        icon = Icons.task_alt;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Pengajuan',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  label,
                  style: AppTextStyles.h3.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLink ? Colors.blue : AppColors.textPrimary,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSeminars() {
    final filteredSeminars = _filteredUpcomingSeminars;

    if (_upcomingSeminars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Belum ada jadwal seminar lain', style: AppTextStyles.h4),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildRegisterCTA(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _buildRegisterCTA(),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _otherSeminarSearch = value.trim()),
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIM mahasiswa...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredSeminars.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Seminar tidak ditemukan', style: AppTextStyles.h4),
                  const SizedBox(height: 6),
                  Text(
                    'Coba kata kunci lain.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...filteredSeminars.map(
              (seminar) => _buildUpcomingSeminarCard(seminar as Map<String, dynamic>),
            ),
        ],
      ),
    );
  }

  List<dynamic> get _filteredUpcomingSeminars {
    final query = _otherSeminarSearch.trim().toLowerCase();
    if (query.isEmpty) return _upcomingSeminars;
    return _upcomingSeminars.where((seminar) {
      final student = seminar['internship']?['student']?['user'];
      final name = student?['fullName']?.toString().toLowerCase() ?? '';
      final nim = student?['identityNumber']?.toString().toLowerCase() ?? '';
      return name.contains(query) || nim.contains(query);
    }).toList();
  }

  Widget _buildRegisterCTA() {
    final canRegister = _internship != null && _canSubmitNewSeminar();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ajukan Jadwal Seminar', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  canRegister
                      ? 'Pilih tanggal, waktu, dan ruangan untuk pengajuan seminar.'
                      : 'Anda sudah memiliki pengajuan seminar aktif.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: canRegister ? _openRegisterSeminarSheet : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSeminarCard(Map<String, dynamic> seminar) {
    final studentName = seminar['internship']?['student']?['user']?['fullName'] ?? 'Mahasiswa';
    final companyName = seminar['internship']?['proposal']?['targetCompany']?['companyName'] ?? '-';
    final date = DateTime.tryParse(seminar['seminarDate']?.toString() ?? '') ?? DateTime.now();
    final startTime = seminar['startTime'];
    final room = seminar['room']?['name'] ?? 'TBA';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InternshipSeminarDetailScreen(
              seminarId: seminar['id'],
              user: widget.user,
            ),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentName, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                        Text(companyName, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactInfo(Icons.calendar_today, fmt.formatDateIndonesian(date)),
                  _buildCompactInfo(Icons.access_time, _formatTime(startTime)),
                ],
              ),
              const SizedBox(height: 8),
              _buildCompactInfo(Icons.location_on, room, allowWrap: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text, {bool allowWrap = false}) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        if (allowWrap)
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(text, style: AppTextStyles.caption),
      ],
    );
  }

  void _openRegisterSeminarSheet() {
    if (_internship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan seminar hanya tersedia untuk mahasiswa KP aktif.')),
      );
      return;
    }

    if (!_canSubmitNewSeminar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda sudah memiliki pengajuan seminar aktif.')),
      );
      return;
    }

    setState(() {
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _selectedRoomId = '';
      _selectedModeratorId = '';
      _linkMeeting = '';
      _selectedMemberIds = [];
      _moderatorSearch = '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _sheetSetState = setModalState;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ajukan Jadwal Seminar', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDateTimeSection(),
                  const SizedBox(height: 16),
                  _buildRoomDropdown(),
                  const SizedBox(height: 16),
                  _buildModeratorDropdown(),
                  const SizedBox(height: 16),
                  _buildLinkMeetingField(),
                  if (_groupMembers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildGroupMemberPicker(),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSeminarRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_isSubmitting ? 'Menyimpan...' : 'Kirim Pengajuan'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      _sheetSetState = null;
    });
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal & Waktu', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPickerField(
                label: 'Tanggal',
                value: _selectedDate == null ? 'Pilih tanggal' : fmt.formatDateIndonesian(_selectedDate!),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPickerField(
                label: 'Mulai',
                value: _startTime == null ? 'HH:MM' : _formatTimeOfDay(_startTime!),
                onTap: () => _pickTime(isStart: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPickerField(
          label: 'Selesai',
          value: _endTime == null ? 'HH:MM' : _formatTimeOfDay(_endTime!),
          onTap: () => _pickTime(isStart: false),
        ),
      ],
    );
  }

  Widget _buildPickerField({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ruangan', style: AppTextStyles.label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedRoomId),
          initialValue: _selectedRoomId.isEmpty ? null : _selectedRoomId,
          items: _rooms
              .map((room) => DropdownMenuItem<String>(
                    value: room['id']?.toString() ?? '',
                    child: Text(room['name']?.toString() ?? '-'),
                  ))
              .toList(),
          onChanged: (value) => _refreshSheet(() => _selectedRoomId = value ?? ''),
          decoration: InputDecoration(
            hintText: 'Pilih Ruangan',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildModeratorDropdown() {
    final selectedModerator = _eligibleStudents.firstWhere(
      (student) => student['id']?.toString() == _selectedModeratorId,
      orElse: () => null,
    );
    final query = _moderatorSearch.trim();
    final matches = query.isEmpty
        ? <dynamic>[]
        : _eligibleStudents.where((student) {
            final nim = student['identityNumber']?.toString() ?? '';
            return nim == query;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moderator (Mahasiswa)', style: AppTextStyles.label),
        const SizedBox(height: 8),
        if (selectedModerator != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surfaceSecondary,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedModerator['fullName']?.toString() ?? '-',
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        selectedModerator['identityNumber']?.toString() ?? '-',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _refreshSheet(() {
                    _selectedModeratorId = '';
                    _moderatorSearch = '';
                  }),
                ),
              ],
            ),
          )
        else
          TextField(
            onChanged: (value) => _refreshSheet(() => _moderatorSearch = value.trim()),
            decoration: InputDecoration(
              hintText: 'Ketik NIM (harus sama persis)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        if (selectedModerator == null && query.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (matches.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Column(
                children: matches.map((student) {
                  final name = student['fullName']?.toString() ?? '-';
                  final nim = student['identityNumber']?.toString() ?? '-';
                  return InkWell(
                    onTap: () => _refreshSheet(() {
                      _selectedModeratorId = student['id']?.toString() ?? '';
                      _moderatorSearch = '';
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                Text(nim, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Text('Mahasiswa tidak ditemukan.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildLinkMeetingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Link Meeting (Opsional)', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) => _linkMeeting = value.trim(),
          decoration: InputDecoration(
            hintText: 'https://meet.google.com/...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupMemberPicker() {
    final eligibleMembers = _eligibleGroupMembers;
    final ineligibleMembers = _ineligibleGroupMembers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sertakan Anggota Kelompok', style: AppTextStyles.label),
          const SizedBox(height: 12),
          if (eligibleMembers.isEmpty)
            Text(
              'Anggota kelompok Anda tidak dapat disertakan karena dosen pembimbing berbeda.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            )
          else
            Column(
              children: eligibleMembers.map((member) {
                final id = member['id']?.toString() ?? '';
                final name = member['student']?['user']?['fullName'] ?? '-';
                final nim = member['student']?['user']?['identityNumber'] ?? '-';
                final isSelected = _selectedMemberIds.contains(id);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    _refreshSheet(() {
                      if (checked == true) {
                        _selectedMemberIds.add(id);
                      } else {
                        _selectedMemberIds.remove(id);
                      }
                    });
                  },
                  title: Text(name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(nim, style: AppTextStyles.caption),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          if (ineligibleMembers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${ineligibleMembers.length} anggota lainnya tidak dapat disertakan karena dosen pembimbing berbeda.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  List<dynamic> get _groupMembers {
    final proposalInternships = _internship?['proposal']?['internships'] as List? ?? [];
    return proposalInternships.where((m) => m['id'] != _internship?['id']).toList();
  }

  List<dynamic> get _eligibleGroupMembers {
    final supervisorId = _internship?['supervisorId'];
    return _groupMembers.where((m) => m['supervisorId'] == supervisorId).toList();
  }

  List<dynamic> get _ineligibleGroupMembers {
    final supervisorId = _internship?['supervisorId'];
    return _groupMembers.where((m) => m['supervisorId'] != supervisorId).toList();
  }

  bool _canSubmitNewSeminar() {
    final status = _seminar?['status'];
    if (status == null) return true;
    return !['REQUESTED', 'APPROVED', 'COMPLETED'].contains(status);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _refreshSheet(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0)) : (_endTime ?? const TimeOfDay(hour: 10, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      _refreshSheet(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isWeekday(DateTime date) {
    return date.weekday != DateTime.saturday && date.weekday != DateTime.sunday;
  }

  Future<void> _submitSeminarRegistration() async {
    if (_selectedDate == null || _startTime == null || _endTime == null || _selectedRoomId.isEmpty || _selectedModeratorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib harus diisi.')),
      );
      return;
    }

    if (!_isWeekday(_selectedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seminar hanya dapat dijadwalkan pada hari kerja (Senin-Jumat).')),
      );
      return;
    }

    final startStr = _formatTimeOfDay(_startTime!);
    final endStr = _formatTimeOfDay(_endTime!);
    if (startStr.compareTo(endStr) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu mulai harus lebih awal dari waktu selesai.')),
      );
      return;
    }

    final start = DateTime.parse('1970-01-01T$startStr:00Z');
    final end = DateTime.parse('1970-01-01T$endStr:00Z');
    final dateStr = _selectedDate!.toIso8601String().split('T')[0];

    final conflict = _allUpcomingSeminars.firstWhere(
      (s) {
        final sDate = DateTime.tryParse(s['seminarDate']?.toString() ?? '')?.toIso8601String().split('T')[0];
        if (sDate != dateStr) return false;
        final sStart = DateTime.tryParse(s['startTime']?.toString() ?? '');
        final sEnd = DateTime.tryParse(s['endTime']?.toString() ?? '');
        if (sStart == null || sEnd == null) return false;
        final isOverlapping = start.isBefore(sEnd) && end.isAfter(sStart);
        if (!isOverlapping) return false;
        if (s['room']?['id']?.toString() == _selectedRoomId) return true;
        if (s['moderatorStudentId']?.toString() == _selectedModeratorId) return true;
        return false;
      },
      orElse: () => null,
    );

    if (conflict != null) {
      if (conflict['room']?['id']?.toString() == _selectedRoomId) {
        final name = conflict['room']?['name'] ?? '-';
        final student = conflict['internship']?['student']?['user']?['fullName'] ?? 'mahasiswa lain';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruangan $name sudah dipesan oleh $student pada waktu tersebut.')),
        );
      } else {
        final moderator = conflict['moderatorStudent']?['user']?['fullName'] ?? 'mahasiswa lain';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mahasiswa $moderator sudah terjadwal menjadi moderator pada waktu tersebut.')),
        );
      }
      return;
    }

    _refreshSheet(() => _isSubmitting = true);
    try {
      final payload = {
        'seminarDate': dateStr,
        'startTime': startStr,
        'endTime': endStr,
        'roomId': _selectedRoomId,
        'linkMeeting': _linkMeeting,
        'moderatorStudentId': _selectedModeratorId,
        if (_selectedMemberIds.isNotEmpty) 'memberInternshipIds': _selectedMemberIds,
      };

      await _api.registerSeminar(payload);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedMemberIds.isNotEmpty
                ? 'Pengajuan seminar untuk Anda dan ${_selectedMemberIds.length} anggota kelompok berhasil dikirim.'
                : 'Pengajuan seminar berhasil dikirim.'
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan seminar: $e'), backgroundColor: AppColors.destructive),
      );
    } finally {
      _refreshSheet(() => _isSubmitting = false);
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    try {
      final dt = DateTime.tryParse(time.toString());
      if (dt != null) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return time.toString().substring(11, 16);
    } catch (_) {
      return time.toString();
    }
  }
}

