// ============================================================
// KATALOG PRESET KATEGORI BAWAAN
// Warna & ikon dipilih agar konsisten dengan palet tema.
// ============================================================
import 'package:flutter/material.dart';
import 'package:premium_todo/models/category.dart';

/// Semua pilihan warna yang bisa dipilih pengguna (dialog kategori).
const List<int> kCategoryColors = [
  0xFF7C4DFF, // ungu  (brand)
  0xFF4F46E5, // indigo
  0xFF3B82F6, // biru
  0xFF06B6D4, // cyan
  0xFF10B981, // hijau
  0xFFF59E0B, // amber
  0xFFEF4444, // merah
  0xFFEC4899, // pink
  0xFF8B5CF6, // violet
  0xFF64748B, // slate
];

/// Semua pilihan ikon yang bisa dipilih pengguna (dialog kategori).
const List<(String, IconData)> kCategoryIcons = [
  ('work', Icons.work_rounded),
  ('person', Icons.person_rounded),
  ('shopping_cart', Icons.shopping_cart_rounded),
  ('fitness', Icons.fitness_center_rounded),
  ('home', Icons.home_rounded),
  ('school', Icons.school_rounded),
  ('favorite', Icons.favorite_rounded),
  ('medical', Icons.medical_services_rounded),
  ('travel', Icons.flight_rounded),
  ('star', Icons.star_rounded),
  ('book', Icons.book_rounded),
  ('music', Icons.music_note_rounded),
  ('sports', Icons.sports_soccer_rounded),
  ('code', Icons.code_rounded),
  ('brush', Icons.brush_rounded),
  ('payments', Icons.payments_rounded),
];

/// Kategori bawaan yang dibuat saat pertama kali aplikasi dijalankan.
/// (Nama & ikon selaras dengan kebutuhan umum: kerja, pribadi, belanja, kesehatan.)
List<Category> defaultCategories() => [
      Category.create(name: 'Pekerjaan', colorValue: 0xFF4F46E5, iconName: 'work'),
      Category.create(name: 'Pribadi', colorValue: 0xFF10B981, iconName: 'person'),
      Category.create(name: 'Belanja', colorValue: 0xFFF59E0B, iconName: 'shopping_cart'),
      Category.create(name: 'Kesehatan', colorValue: 0xFFEC4899, iconName: 'fitness'),
    ];
