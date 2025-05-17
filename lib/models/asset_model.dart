class AssetData {
  final String assetCode;
  final String username;
  final String assetName;


  AssetData({
    required this.assetCode,
    required this.username,
    required this.assetName,
  });

  factory AssetData.fromJson(Map<String, dynamic> json) {
    return AssetData(
      assetCode: json['AssetCode'] ?? 'Unknown',  // Beri nilai default jika null
      username: json['Username'] ?? 'No User',    // Beri nilai default jika null
      assetName: json['AssetName'] ?? 'Unknown',    // Beri nilai default jika null
    );
  }
}
