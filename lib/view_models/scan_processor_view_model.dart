import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/scanned_result_model.dart';

/// Tahapan proses supaya UI bisa tampilkan indikator
enum ScanStage { checking, submitting }

class ScanProcessorViewModel extends ChangeNotifier {
  bool isSaving = false;
  String saveMessage = '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    debugPrint('🔐 Token retrieved: $token');
    return token;
  }

  /// onStage dipakai UI untuk menyalakan indikator per tahap
  Future<void> processScannedCode(
      String scannedCode,
      String noSO, {
        Function(ScanResult)? onResult,
        Function(ScanStage)? onStage,
      }) async {
    isSaving = true;
    saveMessage = 'Mengecek data...';
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        onResult?.call(ScanResult(
          success: false,
          statusCode: 401,
          message: 'Token tidak ditemukan. Silakan login ulang.',
        ));
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 👉 Tahap CHECKING
      onStage?.call(ScanStage.checking);

      // 1) /check
      final checkUrl = Uri.parse(ApiConstants.scanAssetCheck(noSO));
      final checkBody = jsonEncode({'AssetCode': scannedCode});

      final checkResponse = await http
          .post(checkUrl, headers: headers, body: checkBody)
          .timeout(const Duration(seconds: 15));
      final checkJson = jsonDecode(checkResponse.body);

      // Sukses validasi (HTTP 200, status "OK")
      if (checkResponse.statusCode == 200 && checkJson['status'] == 'OK') {
        final assetCode = checkJson['data']?['assetCode'] ?? scannedCode;
        final assetName = checkJson['data']?['assetName'] ?? '';

        // 👉 Tahap SUBMITTING
        onStage?.call(ScanStage.submitting);

        // 2) /submit
        final submitUrl = Uri.parse(ApiConstants.scanAssetSubmit(noSO));
        final submitBody = jsonEncode({
          'AssetCode': assetCode,
          'AssetName': assetName,
        });

        final submitResponse = await http
            .post(submitUrl, headers: headers, body: submitBody)
            .timeout(const Duration(seconds: 15));
        final submitJson = jsonDecode(submitResponse.body);

        onResult?.call(ScanResult(
          success: submitResponse.statusCode == 201,
          statusCode: submitResponse.statusCode,
          message: submitJson['message'] ?? 'Gagal menyimpan asset',
        ));
      } else {
        // Gagal validasi: kirim pesan dari /check
        onResult?.call(ScanResult(
          success: false,
          statusCode: checkResponse.statusCode,
          message: checkJson['message'] ?? 'Validasi gagal',
        ));
      }
    } catch (e) {
      onResult?.call(ScanResult(
        success: false,
        statusCode: 500,
        message: 'Terjadi kesalahan: $e',
      ));
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
