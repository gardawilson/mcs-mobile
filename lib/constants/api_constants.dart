import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get changePassword => '$baseUrl/api/change-password';
  static String get login => '$baseUrl/api/login';
  static String get listNoSO => '$baseUrl/api/no-stock-opname';
  static String scanAsset(String noSO) => '$baseUrl/api/no-stock-opname/$noSO';
  static String listAssets(String selectedNoSO) => '$baseUrl/api/no-stock-opname/$selectedNoSO';
}
