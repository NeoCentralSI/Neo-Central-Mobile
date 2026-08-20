# Rencana Implementasi Penyesuaian Mobile: Seminar Hasil, Sidang TA, dan Yudisium

## 1. Tujuan

Dokumen ini menjadi rencana kerja sebelum perubahan kode pada `Neo-Central-Mobile/` dimulai. Tujuannya adalah menyelaraskan seluruh alur mobile yang berkaitan dengan Seminar Hasil Tugas Akhir, Sidang Tugas Akhir, dan Yudisium terhadap kontrak backend dan schema terbaru, dengan website final sebagai referensi perilaku serta UX.

Hasil akhir yang dituju:

- alur mahasiswa, dosen/pembimbing, penguji, dan Ketua Departemen yang sudah tersedia di mobile kembali kompatibel dengan API terbaru;
- model data mobile mengikuti struktur dinamis pada backend, khususnya persyaratan tahun akademik, rubrik penilaian, revisi, dan lifecycle yudisium;
- tidak ada lagi aturan bisnis penting yang di-hardcode di widget;
- error kontrak tidak lagi berubah diam-diam menjadi tampilan data kosong;
- screen besar dipecah menjadi unit yang dapat diuji dan dipelihara;
- pengumuman, notifikasi, deep-link, upload, preview, serta download dokumen konsisten dengan status dan hak akses pengguna.

## 2. Batasan Mutasi dan Sumber Kebenaran

### Direktori yang boleh diubah

- `Neo-Central-Mobile/`
- dokumen rencana ini

### Direktori read-only

- `services/`
- `website/`

Tidak ada perubahan, formatting, perbaikan, commit, atau file baru yang akan dibuat di `services/` maupun `website/`. Ketidakkonsistenan pada kedua codebase tersebut hanya akan dicatat dan, jika aman, dinormalisasi di mobile.

### Baseline yang digunakan

| Sumber | Branch | Commit baseline | Fungsi |
|---|---|---|---|
| Backend | `fathur-sidang` | `ea39506` | Kontrak route, payload, response, role guard, status, dan aturan bisnis |
| Website | `fathur-sidang` | `bdb8348` | Referensi final untuk pemetaan data, state UI, action visibility, loading/error/empty state, dan terminologi |
| Mobile | `fathur` | `325a4a0` dengan perubahan lokal `app_config.dart` | Target implementasi |

Perubahan lokal `Neo-Central-Mobile/lib/core/constants/app_config.dart` yang mengganti base URL ke `https://api-neocentral.fathur.tech` harus dipertahankan dan tidak ditimpa.

## 3. Mengapa Perombakan Diperlukan

Implementasi mobile terakhir yang berhubungan langsung dengan modul ini selesai sekitar 17 Mei 2026. Backend dan website kemudian mendapat perubahan besar pada 27 Juli sampai 4 Agustus 2026, antara lain:

- migrasi persyaratan seminar dan sidang menjadi konfigurasi dinamis per tahun akademik;
- migrasi kriteria serta rubrik penilaian seminar dan sidang ke schema baru;
- pemisahan rubrik penguji dan pembimbing pada sidang;
- stabilisasi draft, submit, penguncian, dan finalisasi penilaian;
- stabilisasi revisi mahasiswa, approval penguji, dan finalisasi pembimbing;
- perubahan lifecycle serta guard yudisium, exit survey, validasi CPL, dan SK;
- protected streaming untuk dokumen sidang;
- penyempurnaan response overview, detail, history, announcement, dan assignment.

Mobile masih mengandalkan banyak `Map<String, dynamic>`, key lama, fallback kosong, serta aturan UI lokal. Karena itu, penyesuaian harus dilakukan pada lapisan data terlebih dahulu sebelum screen.

## 4. Scope Implementasi

### Termasuk dalam scope utama

1. Mahasiswa Seminar Hasil:
   - overview dan checklist;
   - registrasi otomatis melalui upload pertama;
   - persyaratan dokumen dinamis;
   - status dan milestone;
   - riwayat seminar;
   - riwayat kehadiran;
   - detail seminar;
   - hasil penilaian;
   - revisi;
   - pendaftaran/pembatalan sebagai peserta seminar lain.

2. Dosen/Penguji/Pembimbing Seminar Hasil:
   - daftar mahasiswa bimbingan;
   - permintaan sebagai penguji;
   - respons bersedia/tidak bersedia;
   - detail identitas;
   - penilaian berbasis CPMK, kriteria, dan rubrik dinamis;
   - simpan draft dan submit final;
   - rekap/finalisasi hasil oleh pembimbing yang berhak;
   - pengelolaan serta finalisasi revisi;
   - verifikasi kehadiran peserta seminar.

3. Mahasiswa Sidang TA:
   - overview dan checklist;
   - persyaratan dokumen dinamis;
   - status dan milestone;
   - riwayat sidang;
   - detail sidang;
   - hasil penilaian melalui endpoint student assessment view;
   - revisi sidang.

4. Dosen/Penguji/Pembimbing Sidang TA:
   - daftar bimbingan dan permintaan penguji;
   - respons assignment;
   - form penilaian sesuai `assessorRole`;
   - rubrik penguji dan pembimbing yang berbeda;
   - draft/submit/penguncian;
   - finalisasi hasil;
   - revisi dan finalisasi revisi.

5. Ketua Departemen:
   - assignment penguji seminar;
   - assignment penguji sidang;
   - penggantian penguji yang menolak;
   - locked examiner dan previous examiner;
   - validasi jumlah penguji sesuai prasyarat finalisasi.

6. Mahasiswa Yudisium:
   - overview, checklist akademik, lifecycle, dan history;
   - exit survey penuh di mobile;
   - upload dan status verifikasi persyaratan;
   - nilai serta status CPL;
   - download laporan CPL;
   - download sertifikat setelah status mengizinkan;
   - informasi SK/decree yang tersedia.

7. Integrasi lintas modul:
   - announcement seminar dan yudisium;
   - drawer dan routing;
   - FCM notification routing/deep-link;
   - binary download dan protected document access;
   - error mapping;
   - refresh serta invalidasi data setelah mutation.

### Tidak termasuk tanpa keputusan produk tambahan

Mobile saat ini sengaja tidak menyediakan pengalaman administrasi penuh. Karena itu, scope utama tidak menambahkan dari nol:

- verifikasi dokumen dan scheduling oleh Admin;
- archive import/export seminar dan sidang;
- CRUD event/requirement yudisium;
- verifikasi dokumen peserta oleh Admin;
- validasi/perbaikan CPL oleh GKM;
- finalisasi peserta oleh Koordinator Yudisium;
- pengelolaan form exit survey;
- repository administrasi dan report analytics.

API dan website untuk fungsi tersebut tetap dipetakan agar model mobile tidak bertentangan, tetapi pembuatan screen manajemen baru ditempatkan sebagai fase opsional terpisah.

## 5. Temuan Kontrak yang Harus Ditangani di Mobile

| Area | Kondisi mobile sekarang | Kontrak terbaru / dampak | Rencana penanganan |
|---|---|---|---|
| Upload seminar | Mengirim `documentTypeName` dari `docType['name']` | Backend seminar hanya membaca `requirementId` | Kirim UUID `requirement.id` pada field `requirementId` |
| Upload sidang | Mengirim nama pada `documentTypeName` | Fallback backend memperlakukan nilai tersebut sebagai ID persyaratan | Kirim UUID `requirement.id`; hilangkan nama sebagai identifier |
| Persyaratan dokumen | UI menyatukan tipe dan dokumen melalui key longgar | Requirement sekarang dinamis per tahun akademik | Model `Requirement` dan `RequirementDocument` terpisah, join melalui `requirementId` |
| Penilaian seminar | Data berupa raw map | Response sekarang berisi `criteriaGroups`, nested criteria/rubrics, draft, dan `minimumPassingScore` | Model typed dan renderer dinamis |
| Penilaian sidang | Form diperlakukan hampir sama untuk semua dosen | Backend membedakan `assessorRole: examiner/supervisor/viewer` dan rubric set | UI dan payload dipilih dari capability response, bukan tebakan role lokal |
| Penilaian mahasiswa sidang | Menggunakan endpoint form umum | Endpoint umum mengembalikan viewer tanpa criteria; backend menyediakan `/:id/assessment-view` | Tambah method khusus student assessment view |
| Batas kelulusan | Hardcode `55` pada beberapa widget | Backend mengirim `minimumPassingScore` per tahun akademik | Semua badge, dialog, dan keputusan tampilan memakai nilai response |
| Draft assessment | `isDraft` dikirim, tetapi state lokal tersebar | Backend mengunci form setelah `assessmentSubmittedAt` | Satukan state draft/submitted/locked dalam model form |
| Revisi | Action string dan permission diputuskan tersebar | Backend memakai `save_action`, `submit`, `cancel_submit`, `approve`, `unapprove` serta finalization lock | Enum action, capability mapper, dan satu controller mutation |
| Assignment sidang | Mobile mengizinkan satu penguji | Finalisasi backend membutuhkan setidaknya dua penguji tersedia | Mobile memvalidasi minimal dua untuk sidang dan menjelaskan alasannya |
| Status temporal | Widget mengolah status secara lokal | Backend mengembalikan effective status termasuk `ongoing` | UI memakai status backend; local computation hanya untuk formatting countdown |
| Yudisium overview | Raw map dan satu file 1.711 baris | Response kini memuat checklist kondisional, lifecycle, CPL, history, dan requirement dinamis | Model typed dan panel terpisah |
| Exit survey | Mobile mengarahkan pengguna ke web | Endpoint GET/POST mobile-compatible sudah tersedia | Implementasikan screen multi-session dengan enam jenis pertanyaan |
| Exit survey form | Nama kadang tampil sebagai `title`, website type memakai `name` | Backend saat ini menormalisasi form response ke `name`, overview masih dapat membawa `title` | Parser menerima `name` dan `title`, tetapi domain model hanya memakai `name` |
| Yudisium participant | `participantId` tidak selalu tersedia di overview | Backend overview saat ini tidak selalu mengembalikannya; requirements response mengembalikannya | Jangan menjadikan `participantId` overview sebagai syarat render; ambil dari requirements saat perlu |
| Download PDF | `ApiClient` hanya JSON | CPL report, certificate, invitation, assessment result, dan dokumen protected berupa binary | Tambah binary response/download dengan bearer token |
| Envelope API | `_unwrapMap/_unwrapList` dapat menghasilkan `{}`/`[]` diam-diam | Contract drift tampak sebagai empty state palsu | Decoder envelope strict dan `ApiContractException` |
| Sesi login | Tidak ada refresh-on-401 | Semua alur panjang seperti assessment/survey rentan gagal setelah token kedaluwarsa | Refresh single-flight, retry satu kali, lalu logout terkontrol |
| Penyimpanan token | Bernama secure storage tetapi memakai `SharedPreferences` | Access/refresh token tersimpan plaintext | Migrasi token ke `flutter_secure_storage`, preferensi nonrahasia tetap di SharedPreferences |
| Notification routing | Hanya beberapa tipe assignment ditangani | Backend mengirim tipe doc, assignment, scheduled, yudisium, dan finalization-related | Router notifikasi terpusat berdasarkan `type` dan resource ID |

## 6. Arsitektur Target di Mobile

Perombakan dilakukan secara bertahap tanpa mengganti framework state management dan tanpa menambah dependency berat. Flutter SDK `ChangeNotifier`/controller sederhana cukup untuk memisahkan data loading dari widget.

### 6.1 Lapisan transport

`ApiClient` tetap menjadi pintu tunggal HTTP, tetapi ditambah:

- dependency injection untuk `http.Client` dan token store agar unit test nyata dapat dibuat;
- parser standar envelope `{ success, data, message, details }`;
- `getJson`, `postJson`, `patchJson`, `deleteJson` dan multipart yang konsisten;
- request binary dengan bearer token;
- refresh token single-flight saat 401 dan retry maksimal satu kali;
- exception typed: transport, unauthorized, forbidden, validation, not found, conflict, contract, dan server;
- dukungan cancellation/lifecycle minimal melalui pemeriksaan `mounted` pada presentation controller;
- tidak mencetak token atau body sensitif ke log.

Perubahan dibuat kompatibel dengan service lain: method lama dapat dipertahankan sementara sebagai wrapper agar modul di luar scope tidak rusak sekaligus.

### 6.2 Model dan parsing

Raw map tidak akan langsung masuk ke widget. Model minimum yang perlu dibuat:

#### Shared thesis models

- `AcademicRequirement`
- `RequirementDocument`
- `DocumentStatus`
- `ThesisSchedule`
- `RoomSummary`
- `StudentSummary`
- `LecturerSummary`
- `ExaminerAssignment`
- `ExaminerAvailabilityStatus`
- `AssessmentRubric`
- `AssessmentCriterion`
- `AssessmentGroup`
- `AssessmentSubmissionState`
- `RevisionItem`
- `RevisionBoard`

#### Seminar models

- `SeminarStatus`
- `StudentSeminarOverview`
- `StudentSeminarChecklist`
- `StudentSeminarHistoryItem`
- `SeminarDetail`
- `SeminarAssessmentForm`
- `SeminarFinalizationData`
- `SeminarAudience`
- `SeminarAnnouncement`
- `SeminarAssignmentListItem`

#### Defence models

- `DefenceStatus`
- `StudentDefenceOverview`
- `StudentDefenceChecklist`
- `StudentDefenceHistoryItem`
- `DefenceDetail`
- `DefenceAssessmentForm`
- `StudentDefenceAssessmentResult`
- `DefenceFinalizationData`
- `DefenceAssignmentListItem`

#### Yudisium models

- `YudisiumStatus`
- `YudisiumParticipantStatus`
- `StudentYudisiumOverview`
- `StudentYudisiumChecklist`
- `YudisiumRequirementStatus`
- `YudisiumCplScore`
- `YudisiumHistoryItem`
- `ExitSurveyForm`
- `ExitSurveySession`
- `ExitSurveyQuestion`
- `ExitSurveyQuestionType`
- `ExitSurveyOption`
- `ExitSurveyAnswer`
- `YudisiumAnnouncement`

Parser harus:

- menerima nilai nullable sesuai backend;
- melakukan normalisasi alias yang memang ditemukan pada kontrak (`name/title`, beberapa wrapper response);
- menolak UUID atau struktur wajib yang hilang dengan contract error;
- tidak mengubah response tidak dikenal menjadi list kosong;
- menyimpan raw field hanya jika diperlukan untuk forward compatibility, bukan untuk rendering utama.

### 6.3 Service dan repository

Nama `SeminarApiService`, `DefenceApiService`, `YudisiumApiService`, dan `ExaminerAssignmentApiService` dapat dipertahankan untuk mengurangi blast radius, tetapi return value-nya dimigrasikan ke model typed.

Setiap service dibagi menurut use case:

- query overview/list/detail;
- mutation dokumen;
- assignment/response;
- assessment/finalization;
- revision;
- audience;
- survey;
- binary export/download.

Controller presentation memegang loading/error/data/mutation state. Widget hanya merender state dan mengirim intent.

### 6.4 Capability-driven UI

Tombol tidak boleh hanya ditentukan dari role aplikasi. Prioritas sumber keputusan:

1. status/capability yang dikirim backend;
2. relasi response seperti `myExaminer`, `isSupervisor`, `assessorRole`, `isSubmitted`, dan timestamp finalisasi;
3. role lokal hanya untuk pemilihan entry screen/navigation.

Ini penting bagi pengguna dengan multi-role dan bagi dosen yang sekaligus pembimbing/penguji.

## 7. Rencana per Modul

## 7.1 Seminar Hasil

### Data/API

- ubah upload menjadi `{ requirementId }`;
- tambah method student assessment/result yang eksplisit jika dibutuhkan oleh konteks UI;
- pertahankan query `view=examiner_requests`, `supervised_students`, dan `assignment` dengan model berbeda;
- map `criteriaGroups[].criteria[].rubrics[]` secara typed;
- map `minimumPassingScore` dari assessment/finalization;
- map dokumen berdasarkan `requirementId`, bukan nama;
- map response audience dengan `approvedAt`, `isPresent`, dan action capability;
- sediakan binary download invitation letter dan assessment result bila action tersedia pada screen;
- konsolidasikan action revisi ke enum.

### Screen mahasiswa

Referensi web utama:

- `StudentThesisSeminar.tsx`
- `StudentThesisSeminarOverviewPanel.tsx`
- `StudentThesisSeminarChecklistRequirementsCard.tsx`
- `StudentThesisSeminarDocumentCard.tsx`
- `StudentThesisSeminarAttendanceHistoryPanel.tsx`
- `ThesisSeminarDetailAssessmentPanel.tsx`
- `ThesisSeminarDetailRevisionPanel.tsx`

Implementasi:

- jadikan `student_seminar_screen.dart` wrapper tab dan coordinator refresh;
- pecah `student_seminar_overview_panel.dart` menjadi identity, status stepper, checklist, documents, dan history widgets;
- load overview sebagai satu typed state; document type tidak lagi dipanggil terpisah jika overview/detail sudah menjadi sumber yang cukup;
- first upload memakai ID requirement dan menerima seminar yang baru dibuat dari response;
- setelah upload, invalidasi overview, history, dan detail aktif;
- tampilkan rejected/declined note dan izinkan re-upload hanya saat backend mengizinkan;
- attendance tab memetakan registered/approved/present secara eksplisit;
- hasil penilaian dan revisi hanya muncul pada status yang diizinkan backend.

### Screen dosen/detail

- daftar supervised dan examiner request memakai model masing-masing;
- response dialog memvalidasi alasan saat `unavailable`;
- detail tabs ditentukan dari relasi dan status response;
- assessment panel menggunakan rubrik dinamis, score range per criterion, draft restore, submit confirmation, dan lock setelah submit;
- finalization memakai score backend dan `minimumPassingScore`;
- revision panel mengikuti state machine backend dan menampilkan siapa yang boleh melakukan action;
- audience panel hanya memanggil PATCH `{ action: approve|unapprove|present|absent }` yang benar;
- hilangkan asumsi endpoint `/presence` lama.

### Announcement

- gunakan model announcement typed;
- bedakan mahasiswa pemilik, peserta terdaftar, peserta hadir, dan non-mahasiswa;
- tombol register/unregister hanya untuk mahasiswa dan sebelum waktu mulai;
- detail dibuka dengan resource ID dan viewer context yang benar.

## 7.2 Sidang Tugas Akhir

### Data/API

- ubah upload ke `requirementId`;
- tambah `getStudentDefenceAssessmentView(id)` ke endpoint `/:id/assessment-view`;
- bedakan `DefenceAssessmentForm` untuk examiner, supervisor, dan viewer;
- map kriteria/rubrik penguji dan pembimbing tanpa menyatukan keduanya;
- map supervisor assessment fields, examiner assessment fields, final score, grade, dan threshold;
- gunakan protected file endpoint `/:id/documents/:requirementId/file` melalui binary client;
- validasi assignment minimal dua penguji pada mobile agar alur dapat difinalisasi;
- map revision board dan history schema terbaru.

### Screen mahasiswa

Referensi web utama:

- `StudentThesisDefence.tsx`
- `StudentThesisDefenceOverviewPanel.tsx`
- `StudentThesisDefenceChecklistRequirementsCard.tsx`
- `StudentThesisDefenceDocumentCard.tsx`
- `ThesisDefenceDetailAssessmentPanel.tsx`
- `ThesisDefenceDetailRevisionPanel.tsx`

Implementasi:

- pecah `student_defence_screen.dart` menjadi screen/controller dan panel terpisah;
- render checklist dinamis: lulus seminar, finalisasi revisi seminar jika diperlukan, SKS, dan readiness pembimbing;
- gunakan requirement ID pada upload dan refresh overview setelah mutation;
- detail identitas memakai document model baru;
- hasil mahasiswa menggunakan assessment-view, bukan form assessor;
- nilai lulus/gagal dan dialog memakai threshold backend;
- download dokumen/berita acara memakai bearer-authenticated binary request.

### Screen dosen/detail

- daftar supervised/request menggunakan typed item;
- respons assignment dan reason validation sama dengan seminar;
- assessment memilih layout dari `assessorRole`;
- examiner mengisi rubric examiner dan revision notes;
- supervisor mengisi rubric supervisor dan supervisor notes;
- draft dan final submit dipisahkan jelas;
- finalization hanya aktif untuk pembimbing yang diizinkan dan setelah seluruh submission terpenuhi;
- revision panel mengikuti action/lock backend dan melakukan refresh parent setelah mutation.

## 7.3 Yudisium

### Data/API

Tambahkan atau sesuaikan method:

- `getStudentYudisiumOverview()`;
- `getStudentYudisiumRequirements()`;
- `uploadStudentYudisiumDocument(requirementId, file)`;
- `getStudentExitSurvey()`;
- `submitStudentExitSurvey(answers)`;
- `downloadStudentCplReport()`;
- `downloadStudentCertificate()`;
- `getYudisiumAnnouncements()`.

Overview dan requirements tetap dipanggil terpisah karena keduanya membawa detail berbeda. Controller menggabungkannya menjadi satu view state tanpa mengandalkan `participantId` dari overview.

### Screen overview mahasiswa

Referensi web utama:

- `StudentYudisium.tsx`
- `StudentYudisiumOverviewPanel.tsx`
- `StudentYudisiumIdentityCard.tsx`
- `StudentYudisiumStatusCard.tsx`
- `StudentYudisiumChecklistRequirementsCard.tsx`
- `StudentYudisiumDocumentCard.tsx`
- `StudentYudisiumCplTable.tsx`
- `StudentYudisiumHistoryCard.tsx`

`yudisium_overview_screen.dart` dipertahankan sebagai entry screen, tetapi isi 1.711 baris dipecah menjadi panel:

- identity/event card;
- participant lifecycle/status stepper;
- academic checklist;
- requirement upload list;
- CPL result table/cards;
- download action card;
- history section;
- empty period state.

Aturan UI:

- exit survey hanya aktif ketika `checklist.exitSurvey.isAvailable`;
- upload hanya aktif setelah seluruh checklist termasuk survey terpenuhi dan periode masih open;
- dokumen approved/declined/submitted dipetakan secara eksplisit;
- `eligible`, `appointed`, `rejected`, dan `finalized` memiliki visual dan action berbeda;
- report CPL serta certificate hanya ditampilkan saat endpoint/status mengizinkan;
- rejected history tidak tercampur dengan participant aktif.

### Exit survey baru

Referensi utama: `StudentExitSurvey.tsx`.

Tambahkan screen mobile bertahap per session dengan dukungan:

- `short_answer`;
- `paragraph`;
- `number` dengan normalisasi format Indonesia;
- `date`;
- `single_choice`;
- `multiple_choice`.

Controller survey harus:

- mengurutkan session dan question berdasarkan order;
- memulihkan jawaban response untuk tampilan read-only jika sudah submitted;
- memvalidasi seluruh pertanyaan wajib, bukan hanya session aktif;
- memvalidasi opsi merupakan bagian dari pertanyaan;
- mengubah number/date ke payload backend yang benar;
- meminta konfirmasi sebelum submit;
- mencegah submit ganda;
- kembali ke overview dan refresh checklist setelah sukses.

## 8. File Mobile yang Terdampak

### File existing yang pasti diubah

#### Core/data

- `lib/core/services/api_client.dart`
- `lib/core/services/auth_service.dart`
- `lib/core/services/secure_storage_service.dart`
- `lib/core/services/seminar_api_service.dart`
- `lib/core/services/defence_api_service.dart`
- `lib/core/services/yudisium_api_service.dart`
- `lib/core/services/examiner_assignment_api_service.dart`
- `lib/core/services/fcm_service.dart`
- `lib/core/utils/error_mapper.dart`
- `lib/core/utils/notification_helpers.dart`
- `lib/core/widgets/app_drawer.dart`
- `lib/features/shell/main_shell.dart`

#### Seminar

- seluruh file di `lib/features/seminar/`;
- `lib/features/announcement/presentation/panels/seminar_announcement_panel.dart`;
- bagian seminar pada `lib/features/announcement/presentation/announcement_screen.dart`;
- bagian seminar pada `lib/features/hod/presentation/assign_examiner_screen.dart`;
- `lib/features/hod/presentation/assign_examiner_form_screen.dart`.

#### Sidang

- seluruh file di `lib/features/defence/`;
- bagian defence pada kedua screen assignment Ketua Departemen.

#### Yudisium

- `lib/features/yudisium/presentation/yudisium_overview_screen.dart`;
- `lib/features/announcement/presentation/panels/yudisium_announcement_panel.dart`;
- bagian yudisium pada `announcement_screen.dart`, drawer, dan notification routing.

### File baru yang direncanakan

Nama final dapat disesuaikan dengan konvensi repo, tetapi tanggung jawabnya harus terpisah:

```text
lib/
  core/
    models/
      api_envelope.dart
    services/
      token_store.dart
    utils/
      api_contract_parser.dart
  features/
    thesis_shared/
      data/models/
        academic_requirement.dart
        assessment_models.dart
        revision_models.dart
        thesis_people_models.dart
      presentation/
        thesis_status_badge.dart
        requirement_document_card.dart
        assessment_rubric_sheet.dart
    seminar/
      data/models/
        seminar_models.dart
      presentation/controllers/
        student_seminar_controller.dart
        seminar_detail_controller.dart
      presentation/student_panels/
        seminar_identity_card.dart
        seminar_status_card.dart
        seminar_checklist_card.dart
        seminar_documents_card.dart
        seminar_history_card.dart
    defence/
      data/models/
        defence_models.dart
      presentation/controllers/
        student_defence_controller.dart
        defence_detail_controller.dart
      presentation/student_panels/
        defence_identity_card.dart
        defence_status_card.dart
        defence_checklist_card.dart
        defence_documents_card.dart
        defence_history_card.dart
    yudisium/
      data/models/
        yudisium_models.dart
        exit_survey_models.dart
      presentation/controllers/
        student_yudisium_controller.dart
        exit_survey_controller.dart
      presentation/panels/
        yudisium_identity_card.dart
        yudisium_status_card.dart
        yudisium_checklist_card.dart
        yudisium_documents_card.dart
        yudisium_cpl_panel.dart
        yudisium_history_card.dart
      presentation/
        exit_survey_screen.dart
```

Tidak semua model harus berada dalam satu file besar. Jika satu file melewati sekitar 400–500 baris, model dipisah berdasarkan use case.

## 9. Urutan Implementasi

## Fase 0 — Baseline dan contract fixtures

1. Catat status Git ketiga codebase dan pertahankan perubahan lokal base URL.
2. Buat fixture JSON yang mewakili response backend terbaru dari unit/integration test dan mapping website.
3. Buat matriks endpoint versus consumer mobile.
4. Tetapkan enum status dan role/capability yang valid.
5. Jangan menyentuh widget sebelum decoder dasar dan fixture test tersedia.

Checkpoint:

- seluruh endpoint mobile dalam scope mempunyai expected request dan response shape;
- fixture mencakup happy path, nullable data, empty period, rejected history, draft, submitted, dan finalized.

## Fase 1 — Transport, auth, dan model dasar

1. Jadikan `ApiClient` injectable dan testable.
2. Tambahkan strict envelope decoder dan typed errors.
3. Tambahkan multipart UUID field dan binary download.
4. Implementasikan refresh-on-401 single-flight serta retry satu kali.
5. Migrasikan token ke secure storage tanpa menghapus preferensi nonrahasia.
6. Tambahkan shared models untuk requirement, assessment, revision, person, room, dan schedule.
7. Pertahankan adapter method lama sementara agar fitur di luar scope tetap build.

Checkpoint:

- existing API client tests diperbarui dan lulus;
- token migration memiliki test;
- JSON salah menghasilkan contract error, bukan `{}` atau `[]`;
- binary endpoint mengirim Authorization header.

## Fase 2 — Seminar Hasil

Status pelaksanaan: implementasi dan verifikasi otomatis selesai pada 18 Agustus 2026. Validasi manual lintas role terhadap backend live tetap menjadi bagian Fase 5.

1. Model dan parser seminar.
2. Migrasi `SeminarApiService` dan assignment service.
3. Perbaikan upload `requirementId`.
4. Rebuild student overview dan attendance.
5. Migrasi lecturer lists serta response dialog.
6. Migrasi detail identity, assessment, revision, dan audience.
7. Migrasi announcement serta notification/deep-link seminar.
8. Widget dan service tests.

Checkpoint:

- mahasiswa dapat menyelesaikan alur upload sampai status terverifikasi;
- penguji dapat draft/submit nilai dinamis;
- pembimbing dapat finalisasi sesuai threshold backend;
- revisi dan audience action sesuai state backend;
- tidak ada hardcode `55` pada modul seminar.

## Fase 3 — Sidang TA

Status pelaksanaan: implementasi dan verifikasi otomatis selesai pada 18 Agustus 2026. Validasi manual lintas role terhadap backend live tetap menjadi bagian Fase 5.

1. Model dan parser defence.
2. Migrasi `DefenceApiService`.
3. Perbaikan upload requirement UUID.
4. Tambah student assessment-view dan protected binary document.
5. Rebuild student overview/detail.
6. Migrasi lecturer lists, response, assessment per assessor role, finalization, dan revisions.
7. Perketat assignment dua penguji pada mobile.
8. Migrasi notification/deep-link defence.
9. Widget dan service tests.

Checkpoint:

- examiner dan supervisor memperoleh rubric set berbeda yang benar;
- mahasiswa melihat hasil, bukan form kosong viewer;
- final score, grade, dan pass/fail memakai backend response;
- tidak ada hardcode `55` pada modul defence.

## Fase 4 — Yudisium

Status pelaksanaan: implementasi dan verifikasi otomatis selesai pada 18 Agustus 2026. Seluruh 38 test terarah Fase 4 lulus; pada checkpoint Fase 4 suite penuh menghasilkan 235 test lulus dengan dua kegagalan baseline lama pada asumsi `UserRole`. Kedua baseline tersebut telah diselaraskan dengan kontrak lima role pada Fase 5.

1. Model dan parser overview/requirements/CPL/history.
2. Migrasi `YudisiumApiService`.
3. Pecah overview screen menjadi controller dan panel.
4. Implementasikan exit survey penuh.
5. Implementasikan download CPL report dan certificate.
6. Migrasi announcement yudisium.
7. Migrasi notification/deep-link yudisium.
8. Widget, parser, validation, dan service tests.

Checkpoint:

- mahasiswa dapat menyelesaikan exit survey tanpa web;
- checklist otomatis berubah setelah survey/upload;
- seluruh status dokumen dan participant ditampilkan benar;
- history rejected tidak menggantikan participant aktif;
- report/certificate dapat diunduh dengan bearer token.

## Fase 5 — Integrasi dan pembersihan

Status pelaksanaan: implementasi, audit statis lintas role, dan verifikasi otomatis selesai pada 18 Agustus 2026.

1. Hapus adapter dan raw map yang sudah tidak digunakan dalam scope.
2. Konsolidasikan duplicate widget seminar/defence hanya jika perilakunya benar-benar identik.
3. Audit seluruh action visibility berdasarkan status dan capability.
4. Audit refresh setelah mutation dan ketika kembali dari detail.
5. Audit navigation stack, drawer active state, deep-link cold start, background, dan foreground.
6. Jalankan format, analyze, semua tests, dan manual role matrix.
7. Pastikan diff tidak menyentuh `services/` atau `website/`.

Hasil pelaksanaan:

- adapter endpoint yang tidak lagi dipakai di seminar/defence telah dihapus; `Map<String, dynamic>` yang tersisa dalam scope hanya serializer input `toJson()`, bukan response yang dikonsumsi UI;
- tombol unduh binary terautentikasi yang identik telah dikonsolidasikan untuk surat undangan dan dokumen seminar/sidang, sedangkan panel assessment/revision tetap terpisah karena kontrak dan perilakunya berbeda;
- visibility assessment dan revision memakai policy bersama yang mengikuti capability backend: mahasiswa baru melihat nilai yang sudah final, admin/ketua departemen dapat melihat assessment, dan admin tidak ditawari revision route yang akan menghasilkan 403;
- dokumen seminar kini diunduh melalui route terproteksi `/thesis-seminars/:id/documents/:requirementId`, setara dengan pola sidang dan yudisium;
- controller yudisium aman saat request selesai setelah screen di-dispose dan overview di-refresh setelah kembali dari exit survey;
- routing notifikasi dipusatkan pada resolver teruji untuk announcement seminar, detail seminar/sidang, yudisium mahasiswa, assignment penguji, reminder acara, dan penguji yang belum merespons;
- audit matriks role dilakukan secara statis terhadap route guard/service backend dan action visibility mobile untuk mahasiswa, penguji, pembimbing, ketua departemen, admin, dan multi-role dosen;
- 77 regression test terarah Fase 5 lulus dan suite penuh lulus **255/255 test**;
- analyzer pada seluruh file yang disentuh Fase 5 menghasilkan **No issues found**;
- full-project analyzer masih melaporkan empat error karena generated `lib/firebase_options.dart` tidak tersedia di workspace, serta warning/info lama pada modul guidance/internship di luar scope ini;
- `git diff --check` bersih dan tidak ada perubahan baru pada `services/` maupun `website/`; dua untracked item website (`.pnpm-store/` dan `pnpm-workspace.yaml`) sudah ada sebelumnya dan tidak disentuh.

Batas verifikasi lingkungan: smoke test pada perangkat dengan akun nyata per role belum dapat dijalankan dari workspace ini karena generated Firebase options dan kredensial sesi tidak tersedia. Implementasi mobile dan kontrak request/response telah ditutup oleh analyzer terarah, service/controller/model/widget tests, dan full test suite.

## 10. Strategi Pengujian

### Unit test model/parser

Untuk setiap response utama:

- parse response lengkap;
- parse seluruh field nullable;
- reject field wajib yang hilang;
- status tidak dikenal dipetakan ke fallback eksplisit, bukan crash tanpa pesan;
- alias yang disetujui (`name/title`) dipetakan konsisten;
- threshold selain 55 diuji, misalnya 60 dan 70;
- document join diuji menggunakan UUID, bukan nama.

### Unit test API service

- method, path, query, dan body setiap endpoint;
- multipart mengirim `requirementId`;
- assessment payload membedakan examiner/supervisor;
- revision action memakai nilai enum backend;
- 401 memicu satu refresh untuk beberapa request paralel;
- retry berhenti setelah satu kali;
- binary download membawa bearer token;
- response error 400/403/404/409 mempertahankan message backend.

### Controller test

- loading → success/error/empty;
- mutation sukses menginvalidasi data yang benar;
- mutation gagal tidak merusak data sebelumnya;
- draft assessment dipulihkan;
- submitted assessment terkunci;
- exit survey wajib, number, date, single, dan multiple choice;
- dispose saat request berjalan tidak memanggil update state ilegal.

### Widget test

- setiap status seminar, defence, dan yudisium;
- checklist kondisional;
- document submitted/approved/declined;
- capability-based action visibility;
- examiner versus supervisor assessment;
- threshold dinamis;
- exit survey session navigation dan read-only submitted state;
- responsive layout pada ukuran ponsel kecil dan besar.

### Contract test berbasis fixture

Fixture diambil dari bentuk response backend terbaru dan type/interface website. Test ini menjadi alarm ketika key backend berubah lagi.

### Manual role matrix

| Role/context | Seminar | Sidang | Yudisium |
|---|---|---|---|
| Mahasiswa belum memenuhi syarat | Checklist/blocked upload | Checklist/blocked upload | Checklist/blocked survey |
| Mahasiswa memenuhi syarat | Upload dan lifecycle | Upload dan lifecycle | Survey, upload, CPL |
| Mahasiswa peserta seminar | Register/cancel/detail | N/A | N/A |
| Penguji pending | Respond assignment | Respond assignment | N/A |
| Penguji available | Assessment/revision | Assessment/revision | N/A |
| Pembimbing | Finalization/revision | Supervisor assessment/finalization | N/A |
| Ketua Departemen | Assignment/replace | Assignment minimal dua/replace | N/A |
| Multi-role dosen | Capability gabungan | Capability gabungan | Sesuai navigation yang tersedia |

### Perintah verifikasi akhir

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Jika toolchain membutuhkan dependency download, approval jaringan diminta pada saat implementasi, bukan pada tahap perencanaan ini.

## 11. Definition of Done

Implementasi dinyatakan selesai hanya jika:

- tidak ada perubahan pada `website/` dan `services/`;
- seluruh file mobile dalam impact inventory telah diaudit, meskipun akhirnya tidak semuanya perlu diubah;
- upload seminar dan defence mengirim UUID `requirementId`;
- mobile tidak lagi memakai nilai kelulusan hardcode;
- student defence memakai assessment-view yang tepat;
- yudisium dapat diselesaikan dari mobile termasuk exit survey;
- raw response utama tidak langsung dirender oleh widget;
- parser tidak menyembunyikan contract drift sebagai empty state;
- draft, submit, locked, revision, dan finalization mengikuti backend;
- protected PDF dapat diakses melalui request ber-token;
- notification deep-link membuka screen dan resource yang tepat;
- seluruh test baru dan lama lulus;
- `flutter analyze` tidak menghasilkan error;
- manual smoke test berhasil untuk mahasiswa, penguji, pembimbing, dan Ketua Departemen.

## 12. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Branch backend jauh dari `main` | Kunci baseline ke commit `ea39506`; perubahan kontrak setelah itu harus memperbarui fixture |
| Ketidakkonsistenan backend/website | Backend route/service menjadi sumber utama; website hanya referensi UX dan typing |
| Service mobile dipakai fitur lain | Pertahankan wrapper kompatibilitas selama migrasi dan jalankan seluruh test suite |
| Refactor screen besar menimbulkan regresi visual | Ekstraksi panel dilakukan setelah typed state stabil, satu use case per commit |
| Multi-role menghasilkan tombol salah | Gunakan capability response, bukan hanya `UserRole` lokal |
| Download protected gagal melalui browser eksternal | Download bytes melalui `ApiClient` ber-token sebelum preview/share |
| Refresh token menimbulkan request loop | Single-flight lock, retry maksimal satu kali, logout terkontrol |
| Backend mengizinkan satu penguji tetapi finalisasi butuh dua | Validasi dua penguji di mobile dan catat mismatch sebagai batasan backend read-only |
| `participantId` overview yudisium tidak konsisten | Gunakan requirements response untuk ID operasional; overview hanya untuk presentasi |
| Scope berkembang menjadi admin parity penuh | Selesaikan scope role existing terlebih dahulu; admin/Koordinator/GKM menjadi milestone terpisah |

## 13. Strategi Commit Saat Implementasi

Urutan commit yang disarankan agar review dan rollback aman:

1. `test(mobile): add academic module contract fixtures`
2. `refactor(mobile-api): add typed envelopes, binary responses, and injectable client`
3. `fix(mobile-auth): secure token storage and refresh retry`
4. `refactor(mobile): add shared thesis domain models`
5. `feat(mobile-seminar): align API contracts and student flow`
6. `feat(mobile-seminar): align lecturer assessment revision and audience flows`
7. `feat(mobile-defence): align student overview documents and result view`
8. `feat(mobile-defence): align assessor-specific assessment and revisions`
9. `feat(mobile-yudisium): align overview documents CPL and history`
10. `feat(mobile-yudisium): implement student exit survey and downloads`
11. `fix(mobile): align examiner assignment notifications and deep links`
12. `test(mobile): complete seminar defence yudisium coverage`
13. `refactor(mobile): remove transitional raw-map adapters`

Setiap commit fitur harus tetap build dan tidak bergantung pada perubahan yang belum di-commit di `services/` atau `website/`.

## 14. Keputusan Implementasi yang Dikunci oleh Rencana Ini

- Backend dan website tetap read-only.
- Backend adalah sumber kebenaran kontrak dan business rule.
- Website adalah sumber referensi flow dan UX, bukan kode yang disalin langsung.
- Perubahan dimulai dari transport dan model, bukan dari widget.
- Mobile existing role flow diselesaikan lebih dahulu daripada menambah dashboard admin baru.
- Identifier persyaratan selalu UUID, bukan nama.
- Nilai minimum kelulusan selalu berasal dari backend.
- Assessment sidang selalu memperhatikan `assessorRole`.
- Exit survey menjadi fitur mobile native agar alur yudisium mahasiswa end-to-end.
- Semua ketidaksesuaian kontrak harus terlihat sebagai error terdiagnosis dan tercakup test.
