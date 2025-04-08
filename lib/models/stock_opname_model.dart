// models/stock_opname.dart

class StockOpname {
  final String noSO;
  final String tgl;

  StockOpname({required this.noSO, required this.tgl});

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      noSO: json['NoSO'],
      tgl: json['Tanggal'],
    );
  }
}
