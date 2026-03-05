import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/lecturer_api_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Guidance session detail screen for lecturer to approve or reject a request.
/// Loads full detail from backend and supports file/document download.
class GuidanceSessionDetailScreen extends StatefulWidget {
  final Map<String, String> session;
  const GuidanceSessionDetailScreen({super.key, required this.session});

  @override
  State<GuidanceSessionDetailScreen> createState() =>
      _GuidanceSessionDetailScreenState();
}

class _GuidanceSessionDetailScreenState
    extends State<GuidanceSessionDetailScreen> {
  final _api = LecturerApiService();
  bool _isApproving = false;
  bool _isRejecting = false;
  bool _isLoadingDetail = false;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final guidanceId = widget.session['id'];
    if (guidanceId == null || guidanceId.isEmpty) return;

    setState(() => _isLoadingDetail = true);
    try {
      final detail = await _api.getGuidanceDetail(guidanceId);
      if (mounted) setState(() => _detail = detail);
    } catch (_) {
      // Non-critical — fallback to session map data
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  void _approve() async {
    final guidanceId = widget.session['id'];
    if (guidanceId == null || guidanceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID permintaan tidak ditemukan'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _isApproving = true);
    try {
      await _api.approveGuidanceRequest(guidanceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan bimbingan disetujui!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyetujui: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  void _reject() async {
    final guidanceId = widget.session['id'];
    if (guidanceId == null || guidanceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID permintaan tidak ditemukan'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Permintaan'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Alasan penolakan (opsional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isRejecting = true);
      try {
        await _api.rejectGuidanceRequest(
          guidanceId,
          feedback: reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan ditolak'),
              backgroundColor: AppColors.destructive,
            ),
          );
          Navigator.pop(context, true);
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menolak: $e'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isRejecting = false);
      }
    }
  }

  Future<void> _openDocument(String? url) async {
    if (url == null || url.isEmpty) return;
    // Build full URL if relative — ensure slash between base URL and path
    final String fullUrl;
    if (url.startsWith('http')) {
      fullUrl = url;
    } else {
      final path = url.startsWith('/') ? url : '/$url';
      fullUrl = '${AppConfig.baseUrl}$path';
    }
    try {
      var uri = Uri.parse(fullUrl);
      // Thesis uploads require authentication — append token as query param
      // so the external browser can access the protected route.
      if (uri.path.contains('/uploads/thesis')) {
        final token = await SecureStorageService().getAccessToken();
        if (token != null && token.isNotEmpty) {
          uri = uri.replace(queryParameters: {
            ...uri.queryParameters,
            'token': token,
          });
        }
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka dokumen'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka dokumen'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final d = _detail;

    // Prefer detail data over session map
    final name = d?['studentName'] ?? s['name'] ?? '';
    final nim = d?['studentNim'] ?? s['nim'] ?? '';
    final topic = d?['studentNotes'] ?? s['topic'] ?? '';
    final date = d?['requestedDateFormatted'] ?? s['date'] ?? '';
    final supervisor = d?['supervisorName'] ?? s['supervisor'] ?? '';
    final thesisTitle = d?['thesisTitle'] ?? '';
    final documentUrl = d?['documentUrl'];
    final document = d?['document'];
    final milestones = d?['milestoneTitles'] is List
        ? (d!['milestoneTitles'] as List).join(', ')
        : (d?['milestoneName'] ?? '');
    final duration = d?['duration']?.toString() ?? '60';

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSecondary,
        title: Text('Detail Permintaan', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Student Info Card ──
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                name.isNotEmpty
                                    ? name.toString().substring(0, 1)
                                    : 'M',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name.toString(),
                                      style: AppTextStyles.h4),
                                  if (nim.toString().isNotEmpty)
                                    Text(nim.toString(),
                                        style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                            const AppBadge(
                              label: 'Menunggu',
                              variant: BadgeVariant.warning,
                            ),
                          ],
                        ),
                        const AppDivider(),
                        InfoRow(
                          icon: Icons.topic_outlined,
                          label: 'Catatan/Topik',
                          value: topic.toString(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal Diminta',
                          value: date.toString(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InfoRow(
                          icon: Icons.person_outlined,
                          label: 'Dosen Pembimbing',
                          value: supervisor.toString(),
                        ),
                        if (thesisTitle.toString().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          InfoRow(
                            icon: Icons.school_outlined,
                            label: 'Judul TA',
                            value: thesisTitle.toString(),
                          ),
                        ],
                        if (milestones.toString().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          InfoRow(
                            icon: Icons.flag_outlined,
                            label: 'Milestone',
                            value: milestones.toString(),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        InfoRow(
                          icon: Icons.timer_outlined,
                          label: 'Durasi',
                          value: '$duration menit',
                        ),
                      ],
                    ),
                  ),

                  // ── Document/File Download Card ──
                  if (documentUrl != null &&
                      documentUrl.toString().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: InkWell(
                        onTap: () => _openDocument(documentUrl.toString()),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dokumen Bimbingan',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'Tap untuk membuka dokumen',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (document != null && document is Map) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: InkWell(
                        onTap: () => _openDocument(
                          document['filePath']?.toString(),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.attach_file,
                                color: AppColors.info,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    document['fileName']?.toString() ??
                                        'Dokumen TA',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.info,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Tap untuk download',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.download_outlined,
                              size: 18,
                              color: AppColors.info,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Info Banner ──
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    backgroundColor: AppColors.infoLight,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pastikan jadwal Anda tersedia pada tanggal tersebut sebelum menyetujui.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.infoDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Action Buttons ──
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Tolak',
                          isOutline: true,
                          color: AppColors.destructive,
                          icon: Icons.close,
                          isLoading: _isRejecting,
                          onPressed: _reject,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Setujui',
                          icon: Icons.check,
                          color: AppColors.success,
                          isLoading: _isApproving,
                          onPressed: _approve,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
