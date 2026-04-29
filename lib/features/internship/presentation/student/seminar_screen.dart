import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/internship_api_service.dart';
import '../../../../core/services/api_client.dart';
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
  List<dynamic> _upcomingSeminars = [];

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
      ]);

      final overviewRes = results[0] as Map<String, dynamic>;
      final upcomingRes = results[1] as List<dynamic>;

      if (overviewRes['success'] == true) {
        final data = overviewRes['data'];
        final internship = data['internship'];
        final seminars = internship?['seminars'] as List? ?? [];
        
        setState(() {
          _internship = internship;
          _seminar = seminars.isNotEmpty ? seminars[0] : null;
          // Filter out user's own seminar from upcoming list
          _upcomingSeminars = upcomingRes.where((s) {
            return s['internship']?['id'] != internship?['id'];
          }).toList();
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur pendaftaran seminar sedang disiapkan')),
                );
              },
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
    if (_upcomingSeminars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Belum ada jadwal seminar lain', style: AppTextStyles.h4),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _upcomingSeminars.length,
        itemBuilder: (context, index) {
          final seminar = _upcomingSeminars[index];
          return _buildUpcomingSeminarCard(seminar);
        },
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
                  _buildCompactInfo(Icons.location_on, room),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption),
      ],
    );
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

