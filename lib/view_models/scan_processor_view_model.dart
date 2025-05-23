import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/scanned_result_model.dart';
import '../models/bom_part_model.dart';

class ScanProcessorViewModel extends ChangeNotifier {
  bool isSaving = false;
  String saveMessage = '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔐 Token retrieved: $token');
    return token;
  }

  Future<void> processScannedCode(
      String scannedCode,
      String noSO, {
        Function(ScanResult)? onResult,
      }) async {
    isSaving = true;
    saveMessage = 'Mengecek data...';
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        final result = ScanResult(
          success: false,
          statusCode: 401,
          message: 'Token tidak ditemukan. Silakan login ulang.',
        );
        onResult?.call(result);
        isSaving = false;
        notifyListeners();
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final checkUrl = Uri.parse(ApiConstants.scanAssetCheck(noSO));
      final checkBody = jsonEncode({'AssetCode': scannedCode});
      final checkResponse = await http.post(checkUrl, headers: headers, body: checkBody);
      final checkJson = jsonDecode(checkResponse.body);

      if (checkJson['status'] == 'OK') {
        final submitUrl = Uri.parse(ApiConstants.scanAssetSubmit(noSO));
        final submitBody = jsonEncode({
          'AssetCode': checkJson['data']['assetCode'],
          'AssetName': checkJson['data']['assetName'] ?? '',
        });

        final submitResponse = await http.post(submitUrl, headers: headers, body: submitBody);
        final submitJson = jsonDecode(submitResponse.body);

        final result = ScanResult(
          success: submitResponse.statusCode == 201,
          statusCode: submitResponse.statusCode,
          message: submitJson['message'] ?? 'Gagal menyimpan asset',
        );

        onResult?.call(result);
      } else if (checkJson['status'] == 'PENDING') {
        final List<BomPart> parts = (checkJson['data']['parts'] as List)
            .map((e) => BomPart.fromJson(e))
            .toList();

        final result = ScanResult(
          success: false,
          statusCode: 200,
          message: checkJson['message'] ?? 'Checklist diperlukan.',
          parts: parts,
          assetCode: checkJson['data']['assetCode'],
          assetName: checkJson['data']['assetName'] ?? '',
        );

        onResult?.call(result);
      } else {
        final result = ScanResult(
          success: false,
          statusCode: checkResponse.statusCode,
          message: checkJson['message'] ?? 'Validasi gagal',
        );

        onResult?.call(result);
      }
    } catch (e) {
      final result = ScanResult(
        success: false,
        statusCode: 500,
        message: 'Terjadi kesalahan: $e',
      );
      onResult?.call(result);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }


  Future<ScanResult> submitAssetWithParts({
    required String noSO,
    required String assetCode,
    required String assetName,
    required List<Map<String, dynamic>> checklist,
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return ScanResult(
          success: false,
          statusCode: 401,
          message: 'Token tidak ditemukan. Silakan login ulang.',
        );
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final submitUrl = Uri.parse(ApiConstants.scanAssetSubmit(noSO));
      final body = jsonEncode({
        'AssetCode': assetCode,
        'AssetName': assetName,
        'BOMList': checklist,
      });

      final response = await http.post(submitUrl, headers: headers, body: body);
      final json = jsonDecode(response.body);

      return ScanResult(
        success: response.statusCode == 201,
        statusCode: response.statusCode,
        message: json['message'] ?? 'Gagal menyimpan asset',
      );
    } catch (e) {
      return ScanResult(
        success: false,
        statusCode: 500,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }




}
