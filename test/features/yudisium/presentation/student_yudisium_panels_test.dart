import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/features/yudisium/data/models/yudisium_models.dart';
import 'package:neocentral/features/yudisium/presentation/student_panels/student_yudisium_cpl_history_panel.dart';

void main() {
  testWidgets('CPL panel shows scores, outcome, and validator metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentYudisiumCplPanel(
              scores: [
                YudisiumCplScore(
                  code: 'CPL-01',
                  description: 'Mampu memecahkan masalah komputasi',
                  score: 82.5,
                  minimalScore: 70,
                  status: YudisiumCplStatus.validated,
                  passed: true,
                  validatedBy: 'Dr. Validator',
                  validatedByNip: '19800101',
                  validatedAt: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Capaian Pembelajaran'), findsOneWidget);
    expect(find.text('CPL-01'), findsOneWidget);
    expect(find.text('82.5'), findsOneWidget);
    expect(find.text('Lulus'), findsOneWidget);
    expect(find.text('Dr. Validator'), findsOneWidget);
    expect(find.textContaining('NIP 19800101'), findsOneWidget);
  });

  testWidgets('history panel labels rejected registrations as history', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentYudisiumHistoryPanel(
              items: [
                YudisiumHistoryItem(
                  id: 'participant-old',
                  yudisiumId: 'yudisium-old',
                  yudisiumName: 'Yudisium Juli 2026',
                  status: YudisiumParticipantStatus.rejected,
                  createdAt: null,
                  registrationOpenDate: null,
                  registrationCloseDate: null,
                  eventDate: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Riwayat Pendaftaran Yudisium'), findsOneWidget);
    expect(find.text('Yudisium Juli 2026'), findsOneWidget);
    expect(find.text('Tidak memenuhi'), findsOneWidget);
  });
}
