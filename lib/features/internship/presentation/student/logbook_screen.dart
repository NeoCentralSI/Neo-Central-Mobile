import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/services/internship_api_service.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../notifications/presentation/notification_screen.dart';
import '../../../../core/utils/formatters.dart' as fmt;

class InternshipLogbookScreen extends StatefulWidget {
  final UserModel? user;
  const InternshipLogbookScreen({super.key, this.user});

  @override
  State<InternshipLogbookScreen> createState() => _InternshipLogbookScreenState();
}

class _InternshipLogbookScreenState extends State<InternshipLogbookScreen> {
  final _api = InternshipApiService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _logbooks = [];
  bool _isLogbookLocked = false;

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
      final res = await _api.getLogbookOverview();
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _logbooks = data['logbooks'] ?? [];
          // Check if logbook is locked (usually based on internship status)
          final internship = data['internship'];
          if (internship != null) {
            final status = internship['status'];
            _isLogbookLocked = status == 'COMPLETED' || status == 'REPORTING';
          }
          _isLoading = false;
        });
      } else {
        throw Exception(res['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateEntry(String id, String description) async {
    try {
      await _api.updateLogbook(id, description);
      _loadData(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui logbook: $e')),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> entry) {
    if (_isLogbookLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logbook sudah dikunci dan tidak dapat diedit lagi.')),
      );
      return;
    }

    final controller = TextEditingController(text: entry['activityDescription'] ?? '');
    final date = DateTime.tryParse(entry['activityDate'] ?? '') ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  Text('Isi Logbook', style: AppTextStyles.h4),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fmt.formatDateIndonesian(date),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tuliskan aktivitas Anda hari ini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateEntry(entry['id'].toString(), controller.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Perubahan'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      drawer: AppDrawer(user: widget.user, activeRoute: 'internship'),
      appBar: AppBar(
        title: const Text('Logbook Kerja Praktik'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState()
              : _logbooks.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logbooks.length,
                        itemBuilder: (context, index) {
                          final entry = _logbooks[index];
                          return _buildLogbookCard(entry, index);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        ),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildLogbookCard(Map<String, dynamic> entry, int index) {
    final date = DateTime.tryParse(entry['activityDate'] ?? '') ?? DateTime.now();
    final description = entry['activityDescription'] as String?;
    final hasEntry = description != null && description.trim().isNotEmpty;

    return Container(
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
      child: InkWell(
        onTap: () => _showEditDialog(entry),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fmt.formatDateIndonesian(date),
                            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Hari Ke-${index + 1}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(hasEntry),
                ],
              ),
              const Divider(height: 24),
              Text(
                hasEntry ? description : 'Belum ada catatan aktivitas untuk hari ini.',
                style: AppTextStyles.body.copyWith(
                  color: hasEntry ? AppColors.textPrimary : AppColors.textTertiary,
                  fontStyle: hasEntry ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (!_isLogbookLocked) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      hasEntry ? 'Edit Catatan' : 'Isi Logbook',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: Colors.amber[800]),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filled ? Icons.check_circle : Icons.pending_outlined,
            size: 12,
            color: filled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            filled ? 'Terisi' : 'Kosong',
            style: AppTextStyles.caption.copyWith(
              color: filled ? Colors.green[700] : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Belum ada data logbook', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          const Text('Silakan periksa kembali setelah KP dimulai.'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Gagal memuat data', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
