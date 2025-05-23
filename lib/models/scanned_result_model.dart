import 'bom_part_model.dart';

class ScanResult {
  final bool success;
  final int statusCode;
  final String message;
  final String? assetCode;
  final String? assetName;
  final List<BomPart>? parts;

  ScanResult({
    required this.success,
    required this.statusCode,
    required this.message,
    this.assetCode,
    this.assetName,
    this.parts,
  });
}
