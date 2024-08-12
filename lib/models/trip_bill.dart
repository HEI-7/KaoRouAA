class TripBill {
  final int? id;
  final int? tripId;
  final int? userId; // 付款
  final double? pay; // 金额
  final String? date; // 日期
  final String? type; // 分类
  final String? remark; // 备注
  final String? aaUsers; // 用户

  TripBill({
    this.id,
    this.tripId,
    this.userId,
    this.pay,
    this.date,
    this.type,
    this.remark,
    this.aaUsers,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'userId': userId,
      'pay': pay,
      'date': date,
      'type': type,
      'remark': remark,
      'aaUsers': aaUsers,
    };
  }
}
