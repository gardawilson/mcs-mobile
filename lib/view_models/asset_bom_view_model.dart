import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/asset_bom_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';


class AssetBOMViewModel extends ChangeNotifier {
  bool isLoading = true;
  String errorMessage = '';
  List<AssetBOMItem> bomList = [];
  Map<String, TextEditingController> qtyControllers = {};

  Map<String, TextEditingController> remarkControllers = {};

  Map<String, bool> remarkVisibility = {};

  Map<String, bool> _expandedSections = {};
  Map<String, bool> _loadingSections = {};


  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔐 Token retrieved: $token');
    return token;
  }


  void toggleRemarkVisibility(String id) {
    remarkVisibility[id] = !(remarkVisibility[id] ?? false);
    notifyListeners();
  }

  bool isRemarkVisible(String id) => remarkVisibility[id] ?? false;

  void updateRemark(String id, String newRemark) {
    final index = bomList.indexWhere((item) => item.id == id);
    if (index != -1) {
      bomList[index].remark = newRemark;
      remarkControllers[id]?.text = newRemark;
      notifyListeners();
    }
  }

  void initControllers() {
    qtyControllers.clear();
    remarkControllers.clear();
    remarkVisibility.clear();

    for (var item in bomList) {
      qtyControllers[item.id] = TextEditingController(
        text: item.qtyFound.isNotEmpty ? item.qtyFound : '',
      );
      remarkControllers[item.id] = TextEditingController(
        text: item.remark ?? '',
      );
      remarkVisibility[item.id] = false;
    }
  }

  Future<void> fetchBOM(String noSO, String assetCode) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstants.partBOM(assetCode, noSO));

      print('🔄 Fetching BOM from: $url');

      final response = await http.get(url);

      print('✅ Response status: ${response.statusCode}');
      print('🧾 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];

        final List<AssetBOMItem> hierarchicalList =
        items.map((json) => AssetBOMItem.fromJson(json)).toList();

        // Flatten ke bomList
        bomList = _flattenBOM(hierarchicalList);

        print('✅ Parsed ${bomList.length} BOM items (flattened)');
      } else {
        errorMessage = 'Gagal memuat data: ${response.reasonPhrase}';
      }
    } catch (e, stack) {
      errorMessage = 'Terjadi kesalahan: $e';
      print('❗ Exception: $e');
      print(stack);
    }

    isLoading = false;
    initControllers();
    notifyListeners();
  }

  List<AssetBOMItem> _flattenBOM(List<AssetBOMItem> items) {
    List<AssetBOMItem> flatList = [];

    void _flatten(List<AssetBOMItem> list) {
      for (var item in list) {
        flatList.add(item);
        if (item.parts.isNotEmpty) {
          _flatten(item.parts);
        }
      }
    }

    _flatten(items);
    return flatList;
  }


  void updateQtyFound(String id, String newQty) {
    final index = bomList.indexWhere((item) => item.id == id);
    if (index != -1) {
      bomList[index].qtyFound = newQty.trim().isEmpty ? '0' : newQty;
      qtyControllers[id]?.text = newQty.trim().isEmpty ? '0' : newQty;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getBOMToSubmit() {
    return bomList
        .where((item) => item.level != 'relationship')
        .map((item) => {
      'id': item.id,
      'qty_found': item.qtyFound,
    })
        .toList();
  }

  Future<bool> submitBOM(String noSO, String assetCode) async {
    final url = Uri.parse(ApiConstants.submitBOM);
    final body = {
      'noSO': noSO,
      'assetCode': assetCode,
      'data': bomList
          .where((item) => item.level != 'relationship')
          .map((item) => {
        'idBOM': item.id,
        'qtyFound': item.qtyFound.isEmpty ? '0' : item.qtyFound,
        'remark': item.remark.isEmpty ? '' : item.remark,
      })
          .toList(),
    };

    try {

      String? token = await _getToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📤 Submit response code: ${response.statusCode}');
      print('📨 Submit response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        errorMessage = 'Gagal submit data: ${response.reasonPhrase}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan saat submit: $e';
      notifyListeners();
      return false;
    }
  }


  bool isSectionExpanded(String sectionHeader) {
    return _expandedSections[sectionHeader] ?? false; // Default collapsed
  }

  bool isSectionLoading(String sectionHeader) {
    return _loadingSections[sectionHeader] ?? false;
  }

  void toggleSectionExpansion(String sectionHeader) {
    _expandedSections[sectionHeader] = !(_expandedSections[sectionHeader] ?? false);
    notifyListeners();
  }

  void setSectionLoading(String sectionHeader, bool isLoading) {
    _loadingSections[sectionHeader] = isLoading;
    notifyListeners();
  }


}
