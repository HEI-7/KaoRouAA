import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'package:kao_rou_aa/models/trip.dart';
import 'package:kao_rou_aa/models/trip_user.dart';
import 'package:kao_rou_aa/models/trip_bill.dart';
import 'package:kao_rou_aa/models/trip_bill_detail.dart';
import 'package:kao_rou_aa/services/database_service.dart';

class TripProvider extends DBProvider {
  // 继承
  static final TripProvider instance = TripProvider();

  Future<Database> get _db async => super.database;

  // trip
  Future<void> insertTrip(Trip trip) async {
    final db = await _db;
    await db.insert('trip', trip.toMap());
  }

  Future<void> deleteTripCascade(int id) async {
    final db = await _db;
    final batch = db.batch();

    batch.rawDelete(
      'delete from trip_bill_detail where userId in (select id from trip_user where tripId = ?)',
      [id],
    );
    batch.rawDelete(
      'delete from trip_bill where tripId = ?',
      [id],
    );
    batch.rawDelete(
      'delete from trip_user where tripId = ?',
      [id],
    );
    batch.delete(
      'trip',
      where: 'id = ?',
      whereArgs: [id],
    );
    await batch.commit();
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await _db;
    await db.update(
      'trip',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<List<Trip>> listTrip() async {
    final db = await _db;
    final List<Map<String, Object?>> tripMaps = await db.query(
      'trip',
      orderBy: 'id desc',
    );

    return [
      for (final {
            'id': id as int,
            'name': name as String,
            'pic': pic as String,
          } in tripMaps)
        Trip(id: id, name: name, pic: pic)
    ];
  }

  // trip user
  Future<void> insertTripUser(TripUser tripUser) async {
    final db = await _db;
    await db.insert('trip_user', tripUser.toMap());
  }

  Future<bool> deleteTripUserCascade(int id) async {
    final db = await _db;

    // 判断能否删除
    final List results = await db.rawQuery(
      """
        select * from trip_bill_detail where userId = ?
      """,
      [id],
    );
    if (results.isNotEmpty) {
      return false;
    }

    await db.delete(
      'trip_user',
      where: 'id = ?',
      whereArgs: [id],
    );
    return true;
  }

  Future<void> updateTripUser(TripUser tripUser) async {
    final db = await _db;
    await db.update(
      'trip_user',
      tripUser.toMap(),
      where: 'id = ?',
      whereArgs: [tripUser.id],
    );
  }

  Future<List<TripUser>> listTripUser(int tripId) async {
    final db = await _db;
    final List<Map<String, Object?>> tripUserMaps = await db.query(
      'trip_user',
      where: 'tripId = ?',
      whereArgs: [tripId],
    );

    return [
      for (final {
            'id': id as int,
            'name': name as String,
            'avatar': avatar as String,
            'pay': pay as double,
            'payAct': payAct as double,
          } in tripUserMaps)
        TripUser(id: id, name: name, avatar: avatar, pay: pay, payAct: payAct),
    ];
  }

  // trip bill
  Future<int> insertTripBill(TripBill tripBill) async {
    final db = await _db;
    return await db.insert('trip_bill', tripBill.toMap());
  }

  Future<void> deleteTripBillCascade(int id) async {
    final db = await _db;
    final batch = db.batch();

    batch.rawDelete(
      'delete from trip_bill_detail where billId = ?',
      [id],
    );
    batch.delete(
      'trip_bill',
      where: 'id = ?',
      whereArgs: [id],
    );
    await batch.commit();
  }

  Future<void> updateTripBill(TripBill tripBill) async {
    final db = await _db;
    await db.update(
      'trip_bill',
      tripBill.toMap(),
      where: 'id = ?',
      whereArgs: [tripBill.id],
    );
  }

  Future<List<TripBill>> listTripBill(int tripId, int userId, bool aaList) async {
    final db = await _db;
    final List<Map<String, Object?>> tripBillMaps;

    if (userId == 0) {
      tripBillMaps = await db.query(
        'trip_bill',
        where: 'tripId = ?',
        whereArgs: [tripId],
        orderBy: 'date desc, id desc',
      );
    } else {
      String queryStr = 'tripId = ? and userId = ?';
      if (aaList) {
        queryStr = 'tripId = ? and id in (select billId from trip_bill_detail where userId = ?)';
      }

      tripBillMaps = await db.query(
        'trip_bill',
        // where: 'tripId = ? and userId = ?',
        // where: 'tripId = ? and id in (select billId from trip_bill_detail where userId = ?)',
        where: queryStr,
        whereArgs: [tripId, userId],
        orderBy: 'date desc, id desc',
      );
    }

    return [
      for (final {
            'id': id as int,
            'userId': userId as int,
            'pay': pay as double,
            'date': date as String,
            'type': type as String,
            'remark': remark as String,
            'aaUsers': aaUsers as String,
          } in tripBillMaps)
        TripBill(
          id: id,
          userId: userId,
          pay: pay,
          date: date,
          type: type,
          remark: remark,
          aaUsers: aaUsers,
        ),
    ];
  }

  // trip bill detail
  Future<void> batchTripBillDetail(int billId, List<TripBillDetail> objs) async {
    final db = await _db;
    final batch = db.batch();

    // 删除旧的
    batch.delete(
      'trip_bill_detail',
      where: 'billId = ?',
      whereArgs: [billId],
    );
    // 创建新的
    for (var obj in objs) {
      batch.insert('trip_bill_detail', obj.toMap());
    }
    await batch.commit();
  }

  // 查询总计
  Future<double> queryTripPay(int tripId) async {
    final db = await _db;
    final List<Map<String, Object?>> results = await db.rawQuery(
      'select sum(payAct) as payAct from trip_user where tripId = ?',
      [tripId],
    );

    if (results[0]['payAct'] == null) {
      return 0;
    }
    return results[0]['payAct'] as double;
  }

  // 计算费用
  Future<void> calculateTripBillToUser(int tripId) async {
    final db = await _db;
    await db.rawUpdate(
      """
        update trip_user
        set pay = ifnull((
          select sum(trip_bill_detail.pay) from trip_bill_detail where userId = trip_user.id
        ), 0), payAct = ifnull((
          select sum(trip_bill.pay) from trip_bill where userId = trip_user.id
        ), 0)
        where tripId = ?
      """,
      [tripId],
    );
  }
}
