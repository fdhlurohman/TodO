// ============================================================
// MODEL: KATEGORI / TAG TUGAS
// Contoh bawaan: Pekerjaan, Pribadi, Belanja, Kesehatan.
// Setiap kategori punya ikon + warna khas (disimpan sebagai
// nilai int ARGB "0xFFRRGGBB" dan nama ikon Material).
// ============================================================
import 'package:flutter/material.dart';
import 'package:premium_todo/core/utils/id_generator.dart';

class Category {
  String id;
  String name;
  int colorValue; // 0xFFRRGGBB - dipakai chip, marker kalender, grafik
  String iconName; // nama ikon Material, lihat categoryPresets

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconName,
  });

  /// Konversi warna int -> Flutter Color (dengan fallback aman).
  Color get color => Color(colorValue);

  /// IconData dari nama ikon yang tersimpan (fallback: ikon label).
  IconData get icon => _iconFromName(iconName);

  static IconData _iconFromName(String name) {
    return switch (name) {
      'work' => Icons.work_rounded,
      'person' => Icons.person_rounded,
      'shopping_cart' => Icons.shopping_cart_rounded,
      'fitness' => Icons.fitness_center_rounded,
      'home' => Icons.home_rounded,
      'school' => Icons.school_rounded,
      'favorite' => Icons.favorite_rounded,
      'medical' => Icons.medical_services_rounded,
      'travel' => Icons.flight_rounded,
      'star' => Icons.star_rounded,
      'book' => Icons.book_rounded,
      'music' => Icons.music_note_rounded,
      'sports' => Icons.sports_soccer_rounded,
      'code' => Icons.code_rounded,
      'brush' => Icons.brush_rounded,
      'payments' => Icons.payments_rounded,
      _ => Icons.label_rounded,
    };
  }

  /// Map -> Category (dibaca dari Hive).
  factory Category.fromMap(Map<dynamic, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        colorValue: map['color'] as int,
        iconName: map['icon'] as String,
      );

  /// Category -> Map (disimpan ke Hive).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'icon': iconName,
      };

  /// Salin dengan perubahan (immutable-friendly).
  Category copyWith({String? name, int? colorValue, String? iconName}) =>
      Category(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        iconName: iconName ?? this.iconName,
      );

  /// Buat kategori baru dengan id unik.
  factory Category.create({
    required String name,
    required int colorValue,
    required String iconName,
  }) =>
      Category(
        id: genId(),
        name: name,
        colorValue: colorValue,
        iconName: iconName,
      );
}
