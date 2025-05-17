class StockOpname {
  final String noSO;
  final String tgl;
  final List<String> companies;
  final List<String> categories;
  final List<String> locations;

  StockOpname({
    required this.noSO,
    required this.tgl,
    required this.companies,
    required this.categories,
    required this.locations,
  });

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      noSO: json['NoSO'] ?? 'N/A', // Default 'N/A' jika NoSO tidak ada
      tgl: json['Tanggal'] ?? 'N/A', // Default 'N/A' jika Tanggal tidak ada
      companies: json['companies'] != null && (json['companies'] as List).isNotEmpty
          ? List<String>.from(json['companies'])
          : ['N/A'], // Default ['N/A'] jika companies kosong atau tidak ada
      categories: json['categories'] != null && (json['categories'] as List).isNotEmpty
          ? List<String>.from(json['categories'])
          : ['N/A'], // Default ['N/A'] jika categories kosong atau tidak ada
      locations: json['locations'] != null && (json['locations'] as List).isNotEmpty
          ? List<String>.from(json['locations'])
          : ['N/A'], // Default ['N/A'] jika locations kosong atau tidak ada
    );
  }
}