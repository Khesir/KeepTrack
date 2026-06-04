import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class TransactionImageService {
  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  static String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return (dot != -1 && dot < path.length - 1) ? path.substring(dot) : '.jpg';
  }

  static Future<Directory> _dir(String transactionId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/KeepTrackBudget/transaction-images/$transactionId');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String?> pickImage(
    String transactionId, {
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xFile == null) return null;
      final dir = await _dir(transactionId);
      final originalName = xFile.name.isNotEmpty ? xFile.name : 'image${_ext(xFile.path)}';
      final dest = File('${dir.path}/${_uuid.v4()}_$originalName');
      await File(xFile.path).copy(dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  static String displayName(String path) {
    final fileName = path.replaceAll('\\', '/').split('/').last;
    // Strip the uuid prefix (36 chars + underscore)
    if (fileName.length > 37 && fileName[36] == '_') return fileName.substring(37);
    return fileName;
  }

  static Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  static Future<void> deleteAll(String transactionId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/KeepTrackBudget/transaction-images/$transactionId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static bool fileExists(String path) => File(path).existsSync();
}
