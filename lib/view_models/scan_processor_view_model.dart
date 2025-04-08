import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';


class ScanProcessorViewModel extends ChangeNotifier {
  bool isSaving = false;
  String saveMessage = '';

  // Fungsi untuk mengambil token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> processScannedCode(
      String scannedCode,
      String noSO, {
        Function(bool, int, String)? onSaveComplete,
      }) async {
    isSaving = true;
    saveMessage = 'Menyimpan...';
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.scanAsset(noSO));
          String? token = await _getToken();

      if (token == null || token.isEmpty) {
        saveMessage = 'Token tidak ditemukan. Silakan login ulang.';
        onSaveComplete?.call(false, 401, saveMessage);
        isSaving = false;
        notifyListeners();
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'AssetCode': scannedCode,
      });

      final response = await http.post(url, headers: headers, body: body);
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 201) {
        saveMessage = responseJson['message'] ?? 'Gagal menyimpan data';
        onSaveComplete?.call(true, response.statusCode, saveMessage);
      } else {
        saveMessage = responseJson['message'] ?? 'Gagal menyimpan data';
        onSaveComplete?.call(false, response.statusCode, saveMessage);
      }
    } catch (e) {
      saveMessage = 'Terjadi kesalahan: $e';
      onSaveComplete?.call(false, 500, saveMessage);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}