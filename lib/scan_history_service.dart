import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryService {
  static const _key = 'scan_history';

  static Future<void> saveScan({
    required String crop,
    required String disease,
    required String confidence,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    final entry = jsonEncode({
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'date': date,
    });
    existing.insert(0, entry); // newest first
    if (existing.length > 50) existing.removeLast(); // keep last 50
    await prefs.setStringList(_key, existing);
  }

  static Future<List<Map<String, String>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list
        .map((e) => Map<String, String>.from(jsonDecode(e)))
        .toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}