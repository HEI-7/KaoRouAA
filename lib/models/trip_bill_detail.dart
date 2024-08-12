class TripBillDetail {
  final int? id;
  final int? billId;
  final int? userId; // 平摊
  final double? pay; // 金额

  TripBillDetail({
    this.id,
    this.billId,
    this.userId,
    this.pay,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'billId': billId,
      'userId': userId,
      'pay': pay,
    };
  }
}
