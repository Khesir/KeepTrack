import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:keep_track/core/network/api_client.dart';

class ParsedTransactionItem {
  final double amount;
  final String type;
  final String description;
  final DateTime date;
  final String categoryName;
  final String? entityType;  // "subscription" | "debt_payment" | "lending" | "goal" | null
  final String? entityHint;  // name hint to pre-filter entity picker

  const ParsedTransactionItem({
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.categoryName,
    this.entityType,
    this.entityHint,
  });

  factory ParsedTransactionItem.fromJson(Map<String, dynamic> json) =>
      ParsedTransactionItem(
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        description: json['description'] as String,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        categoryName: json['categoryName'] as String,
        entityType: json['entityType'] as String?,
        entityHint: json['entityHint'] as String?,
      );
}

class ReceiptParserService {
  final Dio _dio = ApiClient.instance;

  Future<List<ParsedTransactionItem>> parseReceiptImage(File imageFile) async {
    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) {
      throw Exception('Image is too large. Please choose a smaller photo (max 5 MB).');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _mimeType(imageFile.path);

    final response = await _dio.post<List<dynamic>>(
      '/transactions/parse-receipt',
      data: {'imageBase64': base64Image, 'mimeType': mimeType},
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    return (response.data as List)
        .map((e) => ParsedTransactionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _mimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}
