import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/company_model.dart';
import '../models/category_model.dart';
import '../models/location_model.dart';
import '../constants/api_constants.dart';

class MasterDataViewModel extends ChangeNotifier {
  List<Company> companies = [];
  List<Category> categories = [];
  List<Location> locations = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchMasterData() async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(ApiConstants.masterCompany), // endpoint sama
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Parse perusahaan
        final List<dynamic> companiesJson = jsonData['companies'];
        companies = companiesJson.map((e) => Company.fromJson(e)).toList();

        // Parse kategori
        final List<dynamic> categoriesJson = jsonData['categories'];
        categories = categoriesJson.map((e) => Category.fromJson(e)).toList();

        // Parse lokasi
        final List<dynamic> locationsJson = jsonData['locations'];
        locations = locationsJson.map((e) => Location.fromJson(e)).toList();

        errorMessage = '';
      } else {
        errorMessage = 'Failed to load data (${response.statusCode})';
      }
    } catch (e) {
      errorMessage = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
