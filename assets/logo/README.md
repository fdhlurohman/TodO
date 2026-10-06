# 🎨 Cara Mengganti Logo Aplikasi

## Opsi 1 — Logo SVG (direkomendasikan)
1. Siapkan logo Anda dalam format `.svg`.
2. Timpa file ini: `assets/logo/app_logo.svg` (nama file **harus sama**).
3. Jalankan ulang aplikasi. Selesai — widget `AppLogo` otomatis memakainya.

## Opsi 2 — Logo PNG
1. Siapkan logo Anda dalam format `.png` (disarankan 512×512 px atau lebih).
2. Letakkan sebagai: `assets/logo/app_logo.png`.
3. Jalankan ulang aplikasi. Jika kedua file ada, **SVG diprioritaskan**.
   (Hapus `app_logo.svg` bila ingin memakai PNG.)

## Opsi 3 — Ikon Launcher (ikon di home screen Android)
Ikon launcher berbeda dari logo in-app. Setelah `flutter create .`:
- Ganti `ic_launcher.png` di
  `android/app/src/main/res/mipmap-*/`
  (mdpi 48px, hdpi 72px, xhdpi 96px, xxhdpi 144px, xxxhdpi 192px)
- Atau gunakan package [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons).

> Tidak mengganti apa pun juga aman: aplikasi akan memakai placeholder
> centang bawaan (lihat `lib/widgets/app_logo.dart`).
