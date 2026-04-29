import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/internship_api_service.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/formatters.dart' as fmt;

class InternshipSeminarDetailScreen extends StatefulWidget {
  final String seminarId;
  final UserModel? user;

  const InternshipSeminarDetailScreen({
    super.key,
    required this.seminarId,
    this.user,
  });

  @override
  State<InternshipSeminarDetailScreen> createState() => _InternshipSeminarDetailScreenState();
}

class _InternshipSeminarDetailScreenState extends State<InternshipSeminarDetailScreen> {
  final InternshipApiService _api = InternshipApiService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic>? _seminar;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.getSeminarDetail(widget.seminarId);
      if (res['success'] == true) {
        setState(() {
          _seminar = res['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat detail seminar');
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

  Future<void> _handleAttendance() async {
    final isAlreadyRegistered = _seminar?['isRegistered'] == true;
    
    setState(() => _isSubmitting = true);
    try {
      final res = isAlreadyRegistered
          ? await _api.unregisterAttendance(widget.seminarId)
          : await _api.registerAttendance(widget.seminarId);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? (isAlreadyRegistered ? 'Berhasil membatalkan kehadiran' : 'Berhasil mengambil kehadiran')),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDetail();
      } else {
        throw Exception(res['message'] ?? 'Gagal memproses kehadiran');
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (e is ApiException) {
        errorMessage = e.message;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        title: const Text('Detail Seminar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _seminar == null || _isLoading
          ? null
          : _buildBottomAction(),
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
          ElevatedButton(onPressed: _loadDetail, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final seminar = _seminar!;
    final studentName = seminar['internship']?['student']?['user']?['fullName'] ?? 'Mahasiswa';
    final companyName = seminar['internship']?['proposal']?['targetCompany']?['companyName'] ?? '-';
    final date = DateTime.tryParse(seminar['seminarDate']?.toString() ?? '') ?? DateTime.now();
    final startTime = seminar['startTime'];
    final endTime = seminar['endTime'];
    final room = seminar['room']?['name'] ?? 'TBA';
    final link = seminar['linkMeeting'];
    final moderator = seminar['moderatorStudent']?['user']?['fullName'] ?? 'TBA';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card
          Container(
            padding: const EdgeInsets.all(20),
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName, style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text(companyName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Informasi Seminar', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          _buildDetailItem(Icons.calendar_today, 'Tanggal', fmt.formatDateIndonesian(date)),
          _buildDetailItem(Icons.access_time, 'Waktu', '${_formatTime(startTime)} - ${_formatTime(endTime)} WIB'),
          _buildDetailItem(Icons.location_on, 'Ruangan', room),
          if (link != null && link.isNotEmpty)
            _buildDetailItem(Icons.link, 'Link Meeting', link, isLink: true),
          _buildDetailItem(Icons.person_outline, 'Moderator', moderator),
          
          const SizedBox(height: 24),
          _buildAttendanceInfo(),
        ],
      ),
    );
  }

  Widget _buildAttendanceInfo() {
    final isAlreadyRegistered = _seminar?['isRegistered'] == true;
    final audienceStatus = _seminar?['myRegistrationStatus']; // 'REQUESTED' or 'VALIDATED'

    if (!isAlreadyRegistered) return const SizedBox.shrink();

    Color statusColor = Colors.amber;
    String statusLabel = 'Menunggu Validasi';
    IconData statusIcon = Icons.hourglass_empty;

    if (audienceStatus == 'VALIDATED') {
      statusColor = AppColors.success;
      statusLabel = 'Kehadiran Tervalidasi';
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Text(
            statusLabel,
            style: AppTextStyles.label.copyWith(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final isAlreadyRegistered = _seminar?['isRegistered'] == true;
    final audienceStatus = _seminar?['myRegistrationStatus'];
    final canCancel = audienceStatus != 'VALIDATED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isSubmitting || (isAlreadyRegistered && !canCancel)) ? null : _handleAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAlreadyRegistered ? AppColors.destructive : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(isAlreadyRegistered ? 'Batalkan Kehadiran' : 'Ambil Kehadiran'),
          ),
        ),
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
