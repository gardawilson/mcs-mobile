import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get changePassword => '$baseUrl/api/change-password';
  static String get login => '$baseUrl/api/login';
  static String get listNoSO => '$baseUrl/api/no-stock-opname';
  static String get masterCompany => '$baseUrl/api/master-company';
  static String scanAssetCheck(String noSO) => '$baseUrl/api/no-stock-opname/$noSO/check';
  static String scanAssetSubmit(String noSO) => '$baseUrl/api/no-stock-opname/$noSO/submit';
  static String listAssets(String selectedNoSO) => '$baseUrl/api/no-stock-opname/$selectedNoSO';
}
