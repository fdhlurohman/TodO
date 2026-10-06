# 📝 TodO — Aplikasi To-Do List Flutter

Aplikasi to-do list modern dan elegan untuk Android dengan fitur lengkap: kategori berwarna,
prioritas, sub-tugas, pengingat notifikasi, tugas berulang, kalender, timer
Pomodoro, dashboard analitik, dan tema gelap/terang.

Dibangun dengan **Flutter + Provider + Hive + fl_chart + table_calendar +
flutter_local_notifications**.

---

## ✨ Fitur

| Fitur | Keterangan |
|---|---|
| ✅ CRUD Tugas | Tambah, lihat, edit, hapus + pin tugas penting |
| 🚀 Onboarding | Tutorial penggunaan saat pertama kali dibuka, lalu pilih data contoh atau daftar kosong |
| 🏷️ Kategori/Tag | Pekerjaan, Pribadi, Belanja, Kesehatan + kategori kustom (pilih warna & ikon) |
| 🔥 Prioritas | Tinggi / Sedang / Rendah dengan indikator warna (merah/amber/abu) |
| ☑️ Sub-tugas | Pecah tugas jadi checklist dengan progress bar |
| 🔍 Pencarian & Filter | Cari judul/catatan/sub-tugas; filter status, kategori, prioritas; sort deadline/prioritas/terbaru/judul |
| ⏰ Notifikasi Lokal | Pengingat sebelum deadline (5–60 menit), pilihan suara TodO/perangkat/senyap, snooze 10 menit, dan ringkasan harian/mingguan |
| 🗃️ Cadangan | Ekspor/impor JSON; pemulihan dapat menggabungkan atau mengganti data |
| 🔁 Tugas Berulang | Harian, mingguan, bulanan — deadline otomatis bergeser saat selesai |
| 📅 Kalender | Kalender bulanan dengan marker deadline (merah = ada yang terlambat) |
| 🍅 Timer Pomodoro | Fokus 25 mnt → istirahat 5 mnt, istirahat panjang tiap 4 sesi, bisa dihubungkan ke tugas |
| 📊 Analitik | Donut chart tingkat penyelesaian, bar chart 7 hari, distribusi kategori & prioritas |
| 🌗 Tema | Mode gelap/terang, tersimpan permanen |
| 🎨 Logo Kustom | Tinggal timpa file di `assets/logo/` — tidak perlu ubah kode |

---

## 📁 Struktur Folder

```
premium_todo/
├── pubspec.yaml                  # Konfigurasi project + dependency + assets
├── analysis_options.yaml         # Aturan linter
├── README.md
├── assets/
│   └── logo/
│       ├── app_logo.svg          # ← GANTI dengan logo Anda (SVG)
│       ├── app_logo.png          # ← atau PNG (opsional, alternatif)
│       └── README.md             # Panduan ganti logo
└── lib/
    ├── main.dart                 # Entry point: init Hive, notifikasi, provider
    ├── core/
    │   ├── theme/app_theme.dart  # Tema terang & gelap
    │   └── utils/
    │       ├── date_utils.dart   # Format tanggal bahasa Indonesia
    │       └── id_generator.dart # Pembangkit ID unik
    ├── data/
    │   └── hive_repository.dart  # Satu-satunya akses database Hive
    ├── models/
    │   ├── task.dart             # Model utama Task (serialisasi Hive manual)
    │   ├── subtask.dart          # Checklist dalam tugas
    │   ├── category.dart         # Kategori (warna + ikon)
    │   ├── category_presets.dart # Warna/ikon pilihan + kategori bawaan
    │   ├── task_priority.dart    # Enum prioritas
    │   └── recurrence.dart       # Enum pengulangan + hitung siklus berikutnya
    ├── providers/
    │   ├── task_provider.dart    # Logika utama: CRUD, filter, sort, seed
    │   ├── category_provider.dart
    │   ├── theme_provider.dart
    │   └── pomodoro_provider.dart # State timer fokus
    ├── services/
    │   └── notification_service.dart # Notifikasi lokal + penjadwalan
    ├── screens/
    │   ├── first_run_screen.dart # Tutorial pertama + pilihan data awal
    │   ├── home_shell.dart       # Navigasi 4 tab
    │   ├── home_screen.dart      # Beranda: statistik, search, filter, daftar
    │   ├── task_form_screen.dart # Form tambah/edit tugas
    │   ├── calendar_screen.dart  # Kalender bulanan
    │   ├── analytics_screen.dart # Dashboard grafik
    │   ├── pomodoro_screen.dart  # Timer fokus
    │   └── settings_screen.dart  # Tema, kategori, notifikasi
    └── widgets/
        ├── app_logo.dart         # Logo dari assets (SVG→PNG→fallback)
        ├── task_card.dart        # Kartu tugas (swipe = hapus)
        ├── priority_badge.dart
        └── stat_card.dart
```

---

## 🔧 Persyaratan

1. **Flutter SDK 3.38.4+** — cek dengan `flutter doctor`
   (panduan instalasi: https://docs.flutter.dev/get-started/install)
2. **Android Studio** (untuk Android SDK) atau minimal command-line tools
3. **Java JDK 17**
4. Perangkat Android / emulator untuk testing

---

## 🚀 Cara Setup dari Nol

```bash
# 1. Masuk ke folder project
cd premium_todo

# 2. Buat file platform Android (wajib sekali saja).
#    Perintah ini membuat folder android/ tanpa menimpa kode yang ada.
flutter create . --platforms=android --org com.example --project-name premium_todo

# 3. Tambahkan izin notifikasi di android/app/src/main/AndroidManifest.xml
#    (letakkan di dalam tag <manifest>, sebelum tag <application>):
#      <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
#      <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
#      <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
#    Daftarkan ScheduledNotificationReceiver dan ScheduledNotificationBootReceiver
#    di dalam <application> agar alarm terjadwal diproses dan dipulihkan setelah reboot.

# 4. Ambil semua dependency
flutter pub get

# 5. (Opsional) Cek kualitas kode
flutter analyze

# 6. Jalankan di emulator / perangkat yang terhubung
flutter run
```

> ⚠️ Saat pertama kali menjalankan `flutter create .`, pastikan nama project
> tetap `premium_todo` (sudah diatur flag `--project-name` di atas) agar
> import `package:premium_todo/...` tetap valid.

---

## 📱 Build APK Produksi

Untuk build release, siapkan `android/key.properties` dari
[`android/key.properties.example`](./android/key.properties.example), isi dengan
application ID tetap `my.id.fads.todo` dan signing key milikmu. Jangan mengubah
application ID setelah rilis pertama karena Android memerlukannya untuk mengenali
pembaruan sebagai aplikasi yang sama. File `key.properties` dan keystore diabaikan
Git; jangan membagikan atau memasukkannya ke repository.
Jika belum memiliki keystore, buat secara lokal:

```powershell
keytool -genkeypair -v -keystore android/app/todo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias todo-upload
```

Salin `android/key.properties.example` menjadi `android/key.properties`, lalu
isi `storePassword`, `keyPassword`, dan `keyAlias` sesuai keystore yang dibuat.
Jangan kirim kata sandi atau file keystore ke orang lain.

```bash
# APK versi Release (hasil: build/app/outputs/flutter-apk/app-release.apk)
flutter build apk --release

# APK per-ABI (ukuran lebih kecil, hasil 3 file terpisah)
flutter build apk --release --split-per-abi

# App Bundle untuk Google Play (.aab)
flutter build appbundle --release
```

Lokasi hasil build:

| Jenis | Lokasi file |
|---|---|
| APK gabungan | `build/app/outputs/flutter-apk/app-release.apk` |
| APK arm64 | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` |
| App Bundle | `build/app/outputs/bundle/release/app-release.aab` |

Install ke perangkat:

```bash
flutter install
# atau manual:
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎨 Mengganti Logo Aplikasi

1. **Logo dalam aplikasi** — timpa `assets/logo/app_logo.svg`
   (atau taruh `app_logo.png`), lalu restart aplikasi. Selesai.
2. **Ikon launcher Android** — setelah `flutter create .`:
   - Ganti `ic_launcher.png` di `android/app/src/main/res/mipmap-*/`
   - Atau pakai package [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)

Panduan lengkap: `assets/logo/README.md`.

---

## 🔔 Catatan Notifikasi (Android 13+)

- Izin `POST_NOTIFICATIONS` diminta saat pengingat tugas atau ringkasan
  harian/mingguan diaktifkan, bukan saat aplikasi baru dibuka.
- Jika izin ditolak, tugas tetap tersimpan tetapi notifikasinya tidak dijadwalkan.
- Android menggunakan alarm tepat waktu jika izin "Alarms & reminders" sudah aktif.
  Jika belum, aplikasi memakai alarm inexact yang mungkin ditunda oleh Android;
  aplikasi tidak membuka Pengaturan alarm secara paksa saat setiap tugas disimpan.
- Receiver notifikasi terjadwal dan boot wajib tercantum di
  `android/app/src/main/AndroidManifest.xml`; tanpa receiver, notifikasi terjadwal
  tidak akan ditampilkan dan tidak dipulihkan setelah perangkat dimulai ulang.
- Pilihan jeda pengingat di Pengaturan berlaku untuk semua tugas. Formulir tambah
  dan edit menampilkan jeda yang sama, dan perubahan jeda menjadwalkan ulang tugas.
- Pengingat tugas memiliki sakelar aktif/nonaktif tersendiri. Ringkasan harian dan
  tinjauan mingguan tetap dikontrol oleh sakelar masing-masing.
- Suara notifikasi dapat memakai suara TodO, suara audio yang dipilih dari perangkat,
  atau mode senyap. Pilihan file perangkat disimpan sebagai URI lokal Android; ekspor
  cadangan tidak menyertakan URI tersebut karena hanya berlaku di perangkat asal.
- Pengingat normal berbunyi sesuai jeda yang dipilih. Jika tugas dibuat kurang
  dari jeda itu sebelum deadline, pengingat dijadwalkan tepat pada deadline.
  Pengingat tidak dijadwalkan bila deadline sudah lewat.

---

## 🗃️ Penyimpanan Data

- Database: **Hive** (NoSQL lokal, offline-first, tanpa setup server)
- Lokasi box: `tasks`, `categories`, `settings`
- Data aplikasi tersimpan lokal dan tidak dikirim otomatis ke internet.
  Cadangan hanya dibagikan jika pengguna memilih ekspor dan tujuan berbagi.
- Hapus data aplikasi = reset semua tugas.
- Saat pertama kali membuka TodO, pengguna melihat panduan singkat sebelum
  memilih memakai tugas contoh atau memulai dengan daftar kosong. Panduan
  ditampilkan satu kali.
- Pilihan pengingat per tugas dan ringkasan harian/mingguan disimpan di perangkat.
- Gunakan **Pengaturan → Data & cadangan** untuk ekspor atau memulihkan file JSON.
  Saat memulihkan, pilih gabungkan atau ganti data. Simpan file cadangan di tempat aman.
- Tutorial penggunaan dapat dibuka kembali dari **Pengaturan → Tentang**.

---

## 🧪 Menjalankan Test

```bash
flutter test
```

---

## 🔐 Kebijakan Privasi

Draf kebijakan privasi tersedia di [`PRIVACY_POLICY.md`](./PRIVACY_POLICY.md).
Sebelum mengunggah aplikasi, ganti placeholder email kontak dengan alamat publik
yang kamu kelola, lalu terbitkan dokumen tersebut di URL publik dan cantumkan
tautannya pada halaman unduhan.

---

## 📄 Lisensi

Repository ini belum menyertakan lisensi open-source. Jangan menganggap kode
boleh digunakan ulang atau didistribusikan tanpa izin pemegang hak cipta.
