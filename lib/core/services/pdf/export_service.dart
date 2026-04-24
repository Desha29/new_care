import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// خدمة التصدير - Export Service
/// تصدير البيانات إلى CSV
class ExportService {
  static ExportService? _instance;

  ExportService._();

  static ExportService get instance {
    _instance ??= ExportService._();
    return _instance!;
  }

  /// تصدير إلى CSV - Export to CSV
  /// يأخذ قائمة من الخرائط ويحولها إلى ملف CSV
  Future<String> exportToCsv({
    required String fileName,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final buffer = StringBuffer();

    // إضافة BOM لدعم العربية في Excel
    buffer.write('\uFEFF');

    // كتابة العناوين
    buffer.writeln(headers.map(_escapeCsvField).join(','));

    // كتابة الصفوف
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvField).join(','));
    }

    // حفظ الملف
    final dir = await getApplicationSupportDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final filePath = p.join(exportDir.path, '${fileName}_$timestamp.csv');
    final file = File(filePath);
    await file.writeAsString(buffer.toString(), encoding: utf8);

    return filePath;
  }

  /// تصدير قائمة خرائط مباشرة - Export from list of maps
  Future<String> exportMapsToCsv({
    required String fileName,
    required List<Map<String, dynamic>> data,
    List<String>? columnOrder,
  }) async {
    if (data.isEmpty) {
      throw Exception('لا توجد بيانات للتصدير');
    }

    final headers = columnOrder ?? data.first.keys.toList();
    final rows = data.map((map) {
      return headers.map((h) => (map[h] ?? '').toString()).toList();
    }).toList();

    return exportToCsv(
      fileName: fileName,
      headers: headers,
      rows: rows,
    );
  }

  /// جلب مجلد التصدير - Get exports directory
  Future<String> getExportsPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'exports');
  }

  /// جلب قائمة الملفات المصدرة - List exported files
  Future<List<ExportedFile>> listExports() async {
    final exportPath = await getExportsPath();
    final dir = Directory(exportPath);
    if (!await dir.exists()) return [];

    final files = await dir
        .list()
        .where((f) => f is File && f.path.endsWith('.csv'))
        .cast<File>()
        .toList();

    final exports = <ExportedFile>[];
    for (final file in files) {
      final stat = await file.stat();
      exports.add(ExportedFile(
        path: file.path,
        name: p.basename(file.path),
        size: stat.size,
        createdAt: stat.modified,
      ));
    }

    exports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return exports;
  }

  /// حذف ملف مصدر - Delete exported file
  Future<void> deleteExport(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// تهريب حقل CSV - Escape CSV field
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

/// معلومات الملف المصدر - Exported File Info
class ExportedFile {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;

  const ExportedFile({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
