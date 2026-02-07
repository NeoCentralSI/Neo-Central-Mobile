import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'request_detail_screen.dart';

class ApprovalListScreen extends StatelessWidget {
  const ApprovalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // List Content
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            children: [
              const Text(
                'Menunggu Approval',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '12 permintaan tersisa',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // List Items
              _ApprovalItem(
                name: 'Sarah Jenkins',
                title: 'Machine Learning in Agriculture',
                timeAgo: '2 jam yang lalu',
              ),
              _ApprovalItem(
                name: 'Michael Chen',
                title: 'Urban Planning AI',
                timeAgo: '4 jam yang lalu',
              ),
              _ApprovalItem(
                name: 'Jessica Wong',
                title: 'Sustainable Energy Grids',
                timeAgo: '1 hari yang lalu',
              ),
              _ApprovalItem(
                name: 'David Kim',
                title: 'Cybersecurity in FinTech',
                timeAgo: '1 hari yang lalu',
              ),
              _ApprovalItem(
                name: 'Amanda Cole',
                title: 'Bio-mimicry Architecture',
                timeAgo: '2 hari yang lalu',
              ),
              _ApprovalItem(
                name: 'Marcus Johnson',
                title: 'Quantum Computing Ethics',
                timeAgo: '3 hari yang lalu',
              ),
              _ApprovalItem(
                name: 'Priya Patel',
                title: 'Telemedicine Access',
                timeAgo: '3 hari yang lalu',
              ),
            ],
          ),

          // Floating Action Button
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Approve Semua (5)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalItem extends StatelessWidget {
  final String name;
  final String title;
  final String timeAgo;

  const _ApprovalItem({
    required this.name,
    required this.title,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RequestDetailScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.background, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: 'Judul Tugas Akhir: ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: title,
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diajukan $timeAgo',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
