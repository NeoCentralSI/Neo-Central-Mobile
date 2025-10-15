# Neo Central

Neo Central adalah aplikasi yang memusatkan (centralize) layanan akademik di Departemen Sistem Informasi, Universitas Andalas (UNAND) untuk mahasiswa. Fokus utama layanan saat ini adalah pengelolaan Kerja Praktek (KP) dan Tugas Akhir (TA), dengan dukungan fitur-fitur pendukung seperti autentikasi, notifikasi, dan manajemen profil.

## ✨ Fitur Utama

- Autentikasi & Otorisasi (Multi-role)
	- Login dan pengaturan akses berbasis peran (Mahasiswa, Dosen Pembimbing, Koordinator KP/TA, Admin/TU opsional).
- Beranda (Dashboard)
	- Ringkasan status proses KP/TA, pengumuman, dan tautan cepat sesuai peran.
- Kerja Praktek (KP)
	- Alur KP: pengajuan, unggah dokumen, bimbingan, validasi, penilaian.
	- Logbook KP: pencatatan harian/mingguan, persetujuan pembimbing, historis.
- Tugas Akhir (TA)
	- Alur TA: pengajuan, unggah dokumen, bimbingan, seminar/sidang, penilaian.
	- Summary Progress TA: milestone, status bimbingan, dan timeline kemajuan.
- Kehadiran/Absen
	- Pencatatan kehadiran untuk sesi bimbingan, seminar/sidang, atau kegiatan terkait (sesuai peran dan aktivitas).
- Notifikasi & Reminder
	- Pemberitahuan status proses, jadwal, dan pengingat tenggat (deadline) yang dipersonalisasi per user dan peran.
- Profil
	- Informasi dan preferensi akun pengguna.
- Pengaturan
	- Preferensi aplikasi (tema, bahasa, dll — sesuai implementasi).

Catatan: Detail alur/layanan dapat disesuaikan dengan kebijakan prodi dan backend yang terintegrasi.

## 🏗️ Arsitektur Proyek (Feature-first + Clean)

Struktur folder menggunakan pendekatan feature-first untuk menjaga boundary per fitur tetap jelas dan scalable. Secara umum:

```
lib/
	app/               # Konfigurasi aplikasi (router, tema, dll)
		router/
		theme/
	core/              # Utilitas lintas fitur (tanpa ketergantungan ke UI)
		di/              # Dependency Injection/registrasi service
		network/         # HTTP client, interceptors
		error/           # Failure/Exception umum
		utils/           # Helpers, extensions, constants, config
		config/
	features/
		auth/
			domain/        # entities, repositories (kontrak), usecases
			data/          # models/DTO, datasources (remote/local), repositories (impl)
			presentation/  # providers, pages, widgets
		home/
		kp/
		notifications/
		profiles/
		settings/
		ta/
```

Panduan migrasi dari struktur lama:

- `lib/modules/<feature>/*` → pindah ke `lib/features/<feature>/presentation/...`
- `lib/repositories/*` → kontrak di `lib/features/<feature>/domain/repositories`, implementasi di `lib/features/<feature>/data/repositories`
- `lib/ui/*` → pindah ke `lib/app/router`, `lib/app/theme`, atau komponen reusable ke `lib/core/*`

## 🚀 Menjalankan Aplikasi (Windows)

Prasyarat:
- Flutter SDK terpasang (channel stable)
- Android toolchain/SDK atau emulator (atau iOS device pada macOS)

Langkah cepat:

```powershell
# Di direktori proyek
flutter pub get
flutter run
```

Pilih device/emulator yang tersedia saat diminta. Untuk platform lain (web/desktop), pastikan platform telah di-enable pada Flutter SDK Anda.

## 🔧 Teknologi

- Flutter & Dart
- State management: Provider/Riverpod/BLoC (menyesuaikan implementasi)
- HTTP client dan penyimpanan lokal (sesuai kebutuhan fitur)

## 📌 Roadmap Singkat

- [ ] Penyempurnaan alur KP dan TA end-to-end (milestone, dokumen, validasi)
- [ ] Integrasi notifikasi real-time/status proses + reminder kontekstual per peran
- [ ] Pencatatan kehadiran/absen per kegiatan (bimbingan, seminar/sidang)
- [ ] Peningkatan UX beranda dan profil berbasis peran
- [ ] Penguatan DI, error handling, dan test coverage

## 🧪 Kualitas Kode

- Linting mengacu pada `analysis_options.yaml`
- Direkomendasikan menambahkan unit test untuk use case dan repository per fitur, serta widget test untuk halaman utama

## 📝 Catatan

Repositori ini saat ini menyediakan kerangka (scaffold) struktur feature-first. File placeholder `example.dart` diletakkan pada banyak folder sebagai penanda. Silakan ganti secara bertahap dengan implementasi konkret (entities, usecases, repository impl, provider, pages, widgets) seiring migrasi dari struktur lama.

### Multi-role dan Hak Akses

Aplikasi ini mendukung multi-role dan membatasi akses fitur berdasarkan peran:

- Mahasiswa
	- Lihat dan update logbook KP, lihat summary progres TA.
	- Terima notifikasi dan reminder (jadwal bimbingan, seminar/sidang, deadline dokumen).
	- Absensi pada kegiatan yang relevan.
- Dosen Pembimbing
	- Tinjau/approve logbook KP, update status/milestone TA.
	- Kelola absensi sesi bimbingan/seminar (sesuai kebijakan), kirim catatan.
	- Terima dan kirim notifikasi terkait bimbingan.
- Koordinator KP/TA
	- Monitoring summary progres mahasiswa, penjadwalan, validasi administrasi.
	- Broadcast notifikasi/pengumuman, set reminder global.
- Admin/TU (opsional)
	- Manajemen data referensi, sinkronisasi, audit dasar.

Detail implementasi hak akses mengikuti kebijakan program studi dan integrasi backend yang digunakan.

