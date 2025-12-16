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
      assetCode: json['AssetCode'] ?? 'Unknown',
      username: json['Username'] ?? 'Unknown',
      assetName: json['AssetName'] ?? 'Unknown',
    );
  }

  AssetData copyWith({
    String? assetCode,
    String? username,
    String? assetName,
  }) {
    return AssetData(
      assetCode: assetCode ?? this.assetCode,
      username: username ?? this.username,
      assetName: assetName ?? this.assetName,
    );
  }
}
