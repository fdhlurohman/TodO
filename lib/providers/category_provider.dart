// ============================================================
// PROVIDER: KATEGORI
// Mengelola daftar kategori/tag: seed bawaan saat pertama kali,
// CRUD, serta proteksi hapus jika masih ada task yang memakai.
// ============================================================
import 'package:flutter/foundation.dart' hide Category;
import 'package:premium_todo/data/hive_repository.dart';
import 'package:premium_todo/models/category.dart';
import 'package:premium_todo/models/category_presets.dart';

class CategoryProvider extends ChangeNotifier {
  final HiveRepository _repo;
  CategoryProvider(this._repo);

  List<Category> _categories = [];

  List<Category> get categories => List.unmodifiable(_categories);

  /// Cari kategori berdasar id (null jika tidak ada).
  Category? byId(String? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Muat dari Hive; jika masih kosong, seed 4 kategori bawaan.
  Future<void> load() async {
    _categories = _repo.getAllCategories();
    if (_categories.isEmpty) {
      for (final c in defaultCategories()) {
        await _repo.saveCategory(c);
      }
      _categories = _repo.getAllCategories();
    }
    notifyListeners();
  }

  Future<void> reload() async {
    _categories = _repo.getAllCategories();
    notifyListeners();
  }

  /// Tambah / perbarui kategori.
  Future<void> save(Category c) async {
    await _repo.saveCategory(c);
    _categories = _repo.getAllCategories();
    notifyListeners();
  }

  /// Hapus kategori. Kembalikan [CategoryDeleteResult] yang menjelaskan
  /// kenapa penghapusan bisa ditolak:
  ///  - notUsed    -> berhasil dihapus
  ///  - inUse      -> masih dipakai tugas
  ///  - lastOne    -> kategori terakhir (harus tetap ada minimal satu)
  Future<CategoryDeleteResult> delete(String id) async {
    if (_categories.length <= 1) return CategoryDeleteResult.lastOne;
    final used = _repo.getAllTasks().any((t) => t.categoryIdRef == id);
    if (used) return CategoryDeleteResult.inUse;
    await _repo.deleteCategory(id);
    _categories = _repo.getAllCategories();
    notifyListeners();
    return CategoryDeleteResult.notUsed;
  }
}

/// Hasil upaya hapus kategori.
enum CategoryDeleteResult { notUsed, inUse, lastOne }
