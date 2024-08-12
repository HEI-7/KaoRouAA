class Trip {
  final int? id;
  final String name; // 旅程
  final String? pic; // 图片

  Trip({
    this.id,
    required this.name,
    this.pic,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'pic': pic,
    };
  }
}
