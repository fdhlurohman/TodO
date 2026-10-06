# TodO

### Rencanakan hari, selesaikan satu tugas pada satu waktu.

TodO adalah aplikasi produktivitas untuk Android yang membantu Anda mengatur
tugas, memusatkan perhatian, dan melihat progres harian. Data disimpan secara
lokal di perangkat, sehingga tugas tetap dapat dikelola tanpa akun atau server.

![Flutter](https://img.shields.io/badge/Flutter-Dart_3.11%2B-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)
![Versi](https://img.shields.io/badge/versi-1.0.4-6C63FF)

---

## Daftar Isi

- [Fitur](#fitur)
- [Teknologi](#teknologi)
- [Struktur Proyek](#struktur-proyek)
- [Persyaratan](#persyaratan)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Build Rilis](#build-rilis-android)
- [Notifikasi Android](#notifikasi-android)
- [Penyimpanan dan Cadangan](#penyimpanan-dan-cadangan)
- [Menjalankan Pengujian](#menjalankan-pengujian)
- [Privasi dan Lisensi](#privasi-dan-lisensi)

## Fitur

| Area | Kemampuan |
| --- | --- |
| **Manajemen tugas** | Buat, edit, hapus, dan pin tugas; atur deadline, catatan, prioritas, kategori, dan sub-tugas. |
| **Pencarian dan pengurutan** | Cari judul, catatan, atau sub-tugas; filter berdasarkan status, kategori, dan prioritas; urutkan berdasarkan deadline, prioritas, waktu dibuat, atau judul. |
| **Kategori** | Gunakan kategori bawaan atau buat kategori sendiri dengan warna dan ikon pilihan. |
| **Pengingat** | Jadwalkan notifikasi lokal sebelum deadline, pilih suara, dan tunda pengingat. Tersedia pula ringkasan harian dan mingguan. |
| **Tugas berulang** | Atur pengulangan harian, mingguan, atau bulanan. |
| **Kalender** | Lihat tugas berdasarkan tanggal pada kalender bulanan. |
| **Pomodoro** | Gunakan sesi fokus dan istirahat, lalu hubungkan timer dengan tugas. |
| **Analitik** | Pantau progres penyelesaian serta distribusi tugas berdasarkan waktu, kategori, dan prioritas. |
| **Tampilan** | Pilih tema terang atau gelap. |
| **Cadangan** | Ekspor dan pulihkan tugas, kategori, serta pengaturan menggunakan file JSON. |

Saat pertama kali dibuka, aplikasi menampilkan panduan singkat dan pilihan
untuk memulai dengan tugas contoh atau daftar kosong.

## Teknologi

- **Flutter** dan **Dart** untuk aplikasi Android.
- **Provider** untuk pengelolaan state.
- **Hive** untuk penyimpanan lokal.
- **flutter_local_notifications** dan **timezone** untuk pengingat terjadwal.
- **table_calendar** dan **fl_chart** untuk kalender dan visualisasi analitik.
- **file_picker** dan **share_plus** untuk pemilihan serta berbagi file cadangan.

## Struktur Proyek

```text
.
├── android/       # Proyek Android, konfigurasi izin dan notifikasi
├── assets/        # Logo dan aset visual
├── lib/
│   ├── core/      # Tema dan utilitas
│   ├── data/      # Repository Hive dan format cadangan
│   ├── models/    # Model tugas, kategori, prioritas, dan pengulangan
│   ├── providers/ # State dan logika aplikasi
│   ├── screens/   # Beranda, kalender, analitik, Pomodoro, dan pengaturan
│   ├── services/ # Penjadwalan notifikasi
│   └── widgets/   # Komponen UI yang digunakan ulang
├── test/          # Pengujian unit dan widget
└── pubspec.yaml   # Konfigurasi Flutter dan dependensi
```

## Persyaratan

- Flutter SDK dengan **Dart 3.11.0 atau lebih baru**, sesuai batas SDK pada
  `pubspec.yaml`.
- Android Studio atau Android SDK command-line tools.
- Java JDK 17 untuk build Android.
- Emulator Android atau perangkat Android untuk menjalankan aplikasi.

Periksa instalasi Flutter dan perangkat yang tersedia:

```bash
flutter doctor
flutter devices
```

## Menjalankan Aplikasi

Android dan konfigurasi dasar notifikasi sudah tersedia di repository. Tidak
perlu menjalankan `flutter create` atau menambahkan izin/receiver Android secara
manual.

Dari direktori proyek, jalankan:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Pilih emulator atau perangkat Android yang terhubung saat diminta. Untuk
menjalankan aplikasi di perangkat tertentu, gunakan `flutter devices` untuk
melihat ID perangkat, lalu jalankan `flutter run -d <device-id>`.

## Build Rilis Android

Build rilis memerlukan konfigurasi signing milik Anda sendiri. Jangan
menggunakan atau membagikan keystore maupun kata sandinya. Repository sudah
menyediakan [`android/key.properties.example`](./android/key.properties.example)
sebagai templat; file kredensial sebenarnya dan file keystore diabaikan oleh
Git.

1. Buat keystore upload secara lokal jika Anda belum memilikinya:

   ```bash
   keytool -genkeypair -v -keystore android/app/todo-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias todo-upload
   ```

2. Salin templat menjadi `android/key.properties`, lalu isi nilai
   `storeFile`, `storePassword`, `keyAlias`, dan `keyPassword` sesuai keystore.
   Contoh `storeFile` untuk perintah di atas adalah
   `app/todo-upload.jks`. Isi `applicationId` dengan `my.id.fads.todo`.
3. Simpan cadangan keystore dan kredensial dengan aman. Jangan commit atau
   membagikannya.
4. Pilih format rilis sesuai cara distribusi aplikasi:

   ```bash
   # Satu APK untuk instalasi langsung dan pengujian
   flutter build apk --release

   # APK terpisah untuk tiap arsitektur Android
   flutter build apk --release --split-per-abi

   # Android App Bundle untuk diunggah ke Google Play
   flutter build appbundle --release
   ```

### Perbedaan format rilis

| Format | Perintah | Kegunaan |
| --- | --- | --- |
| **APK universal** | `flutter build apk --release` | Satu file APK yang mendukung berbagai arsitektur Android. Praktis untuk dibagikan langsung atau dipasang dan diuji secara manual, tetapi ukuran unduhannya biasanya lebih besar. |
| **APK per-ABI** | `flutter build apk --release --split-per-abi` | Menghasilkan APK terpisah untuk setiap arsitektur, sehingga pengguna hanya perlu mengunduh APK yang sesuai dengan perangkatnya. Cocok untuk distribusi langsung jika Anda dapat menyediakan pilihan APK yang tepat. |
| **Android App Bundle (AAB)** | `flutter build appbundle --release` | Format unggahan untuk Google Play. Google Play membuat APK yang dioptimalkan untuk konfigurasi perangkat masing-masing; file AAB bukan APK untuk dipasang langsung. |

Lokasi hasil build:

| Artefak | Lokasi |
| --- | --- |
| APK universal | `build/app/outputs/flutter-apk/app-release.apk` |
| APK ARM 32-bit (split per ABI) | `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` |
| APK ARM 64-bit (split per ABI) | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` |
| APK x86-64 (split per ABI) | `build/app/outputs/flutter-apk/app-x86_64-release.apk` |
| Android App Bundle | `build/app/outputs/bundle/release/app-release.aab` |

Untuk pemasangan atau berbagi APK secara manual, gunakan APK universal atau
pilih APK per-ABI yang cocok dengan perangkat. Untuk publikasi melalui Google
Play, gunakan AAB.

`applicationId` rilis dikunci ke `my.id.fads.todo` oleh konfigurasi Android.
Pertahankan ID tersebut untuk pembaruan aplikasi yang sama.

## Notifikasi Android

- Izin notifikasi diminta saat fitur notifikasi diaktifkan. Jika izin ditolak,
  tugas tetap tersimpan, tetapi notifikasi tidak dapat ditampilkan.
- Android dapat menunda alarm jika akses alarm tepat waktu tidak tersedia.
- Receiver untuk notifikasi terjadwal dan pemulihan jadwal setelah perangkat
  dimulai ulang sudah terdaftar di manifest Android proyek.
- Pengingat tugas dapat diaktifkan atau dinonaktifkan secara terpisah dari
  ringkasan harian dan mingguan. Jeda pengingat yang tersedia adalah 5, 10, 15,
  30, atau 60 menit.
- Suara dapat menggunakan suara bawaan, suara perangkat, atau mode senyap.
  Pilihan suara dari perangkat tersimpan sebagai URI lokal dan tidak disertakan
  dalam file cadangan.

## Penyimpanan dan Cadangan

TodO menggunakan Hive untuk menyimpan tugas, kategori, dan pengaturan secara
lokal. Aplikasi tidak memerlukan akun dan tidak mengirim data tugas ke server.
File cadangan JSON hanya dibagikan jika Anda memilih ekspor dan menentukan
tujuan berbagi.

Gunakan **Pengaturan → Data & cadangan** untuk mengekspor atau memulihkan data.
Pemulihan dapat menggabungkan data dengan isi perangkat atau menggantinya.
Simpan file cadangan di lokasi yang aman. Menghapus data aplikasi atau
mencopot pemasangan dapat menghapus data lokal; file cadangan yang telah
dibagikan perlu dikelola secara terpisah.

## Menjalankan Pengujian

```bash
flutter test
```

## Privasi dan Lisensi

- Baca [Kebijakan Privasi](./PRIVACY_POLICY.md) untuk informasi tentang
  penyimpanan lokal, notifikasi, ekspor, dan penghapusan data.
- Repository ini belum menyertakan lisensi open-source. Hak penggunaan dan
  redistribusi kode tetap mengikuti izin pemegang hak cipta.
