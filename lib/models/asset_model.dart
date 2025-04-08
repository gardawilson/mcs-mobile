class AssetData {
  final String assetCode;
  final String username;

  AssetData({
    required this.assetCode,
    required this.username,
  });

  factory AssetData.fromJson(Map<String, dynamic> json) {
    return AssetData(
      assetCode: json['AssetCode'] ?? 'Unknown',  // Beri nilai default jika null
      username: json['Username'] ?? 'No User',    // Beri nilai default jika null
    );
  }
}
