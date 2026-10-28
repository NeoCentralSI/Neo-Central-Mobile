# NeoCentral Mobile

Aplikasi pendamping NeoCentral, sistem informasi akademik Departemen Sistem
Informasi Universitas Andalas. Aplikasi ini bukan salinan web: fitur lengkap
tetap ada di [NeoCentral versi web](https://github.com/NeoCentralSI/website),
dan API-nya di [services](https://github.com/NeoCentralSI/services).

## Lingkup

| Peran | Menu |
|---|---|
| Mahasiswa | Drawer: Tugas Akhir, Kerja Praktek, Pengumuman. Tab bawah: Beranda, Bimbingan, Ajukan Bimbingan (tombol tengah), Milestone, Profil |
| Dosen (termasuk Ketua/Sekretaris Departemen) | Drawer: Tugas Akhir, Kerja Praktek, Pengumuman. Tab bawah: Beranda, Persetujuan (Permintaan, Catatan, Milestone), Mahasiswa, Profil |
| Admin | Tab bawah: Pengumuman, Notifikasi, Profil |

Notifikasi mahasiswa dan dosen dibuka dari Profil (dan ikon lonceng di Beranda).

- **Bimbingan dan Milestone Tugas Akhir.** Sesi dan milestone fase Proposal
  dan Penelitian tampil bersama, masing-masing dengan badge Jenis.
  Aksi yang ditolak backend (misalnya selama Cuti atau bila mahasiswa tidak
  mengambil mata kuliah Tugas Akhir) menampilkan pesan dari backend apa adanya.
- **Kerja Praktek.**
- **Pengumuman** Seminar Hasil dan Yudisium. Mahasiswa dapat mendaftar dan
  membatalkan pendaftaran sebagai peserta seminar. Detail Seminar Hasil
  (tab Identitas dan Peserta) hanya dibuka dari Pengumuman; dosen pembimbing
  seminar itu dapat mengonfirmasi kehadiran peserta.
- **Notifikasi** push (FCM) dan di aplikasi. Notifikasi untuk modul yang
  tidak ada di mobile membuka daftar Notifikasi.
- **Login Microsoft** (alur OAuth backend) atau email dan kata sandi.
- **Profil** dan Tentang Aplikasi.

**Sengaja hanya ada di web:** Seminar Hasil sebagai penyaji atau penguji
(pendaftaran, dokumen, penilaian, revisi), Sidang, Yudisium, Proposal,
Metode Penelitian, fitur Ketua Departemen, dan fitur Admin selain
Pengumuman dan Notifikasi. Backend tetap mengirim notifikasinya; di mobile
notifikasi itu cukup dibaca di daftar Notifikasi.

## Menjalankan

Prasyarat: Flutter stabil yang memenuhi `environment.sdk` di `pubspec.yaml`
(dicoba dengan Flutter 3.47 / Dart 3.13).

```sh
# Konfigurasi Firebase (tidak ikut di-commit)
cp lib/firebase_options.dart.example lib/firebase_options.dart   # lalu isi
# android/app/google-services.json dan ios/Runner/GoogleService-Info.plist
# diambil dari Firebase console

flutter pub get
flutter run                     # API produksi
```

### Konfigurasi per build (`--dart-define`)

| Kunci | Bawaan | Keterangan |
|---|---|---|
| `API_BASE_URL` | `https://api-neocentral.fathur.site` | URL backend, tanpa `/` di akhir |
| `APP_VERSION` | `1.0.0` | Versi di Tentang Aplikasi; samakan dengan `pubspec.yaml` |
| `MS_CLIENT_ID` | ID aplikasi NeoCentral | Client ID Microsoft Entra (bukan rahasia) |
| `MS_TENANT_ID` | Tenant Universitas Andalas | Tenant ID Microsoft Entra (bukan rahasia) |

Contoh:

```sh
# Backend lokal dari emulator Android (10.0.2.2 = localhost komputer)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Backend lokal dari ponsel di jaringan yang sama
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000

# Build rilis ke server lain
flutter build apk --dart-define=API_BASE_URL=https://api.contoh.ac.id
```

Build debug Android mengizinkan `http://` (untuk backend lokal); build
rilis hanya `https://`.

Login Microsoft membuka `API_BASE_URL/auth/microsoft/login` di halaman web
dalam aplikasi, lalu menukar kode sekali pakai lewat
`POST /auth/microsoft/exchange`. Backend yang dipakai harus sudah
dikonfigurasi untuk login Microsoft versi web (`CLIENT_ID`, `REDIRECT_URI`,
`FRONTEND_URL`).

## Pemeriksaan

```sh
flutter analyze
flutter test
```

## Struktur

```
lib/
  core/            konfigurasi, model, layanan API, utilitas, drawer
  features/
    announcement/  Pengumuman dan Detail Seminar Hasil
    guidance/      Bimbingan dan Milestone (mahasiswa dan dosen)
    internship/    Kerja Praktek
    notifications/ daftar Notifikasi
    shell/         tab bawah, perute notifikasi, awal sesi
    admin/ auth/ profile/ about/ splash/
  shared/widgets/  komponen tampilan bersama
```
