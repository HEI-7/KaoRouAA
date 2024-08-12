class TripUser {
  final int? id;
  final int? tripId;
  final String name; // 昵称
  final String avatar; // 头像
  final double? pay; // 应付
  final double? payAct; // 实付

  TripUser({
    this.id,
    this.tripId,
    required this.name,
    required this.avatar,
    this.pay,
    this.payAct,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'avatar': avatar,
      // 'pay': pay,
      // 'payAct': payAct,
    };
  }
}
