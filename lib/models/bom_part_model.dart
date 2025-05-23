class BomPart {
  final int id;
  final String level;
  final String name;

  BomPart({required this.id, required this.level, required this.name});

  factory BomPart.fromJson(Map<String, dynamic> json) {
    return BomPart(
      id: json['id'],
      level: json['level'],
      name: json['part'],
    );
  }
}
