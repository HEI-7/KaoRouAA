import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// 数据库版本
const dbVersion = 1;

class DBProvider {
  // 单例模式
  DBProvider();

  static final DBProvider instance = DBProvider();

  // 数据库
  static Database? _database;

  Future<Database> get database async {
    _database ??= await initDB();
    return _database!;
  }

  // 初始化数据库
  Future<Database> initDB() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 数据库路径
    String databasePath = join(await getDatabasesPath(), 'kao_rou_aa.db');
    // await deleteDatabase(databasePath);

    return await openDatabase(
      databasePath,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 创建表
  Future _onCreate(Database db, int version) async {
    // await db.execute("PRAGMA foreign_keys = ON;"); // 打开外键约束

    await db.execute("""
      CREATE TABLE trip (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pic TEXT NOT NULL default ''
      )
    """);

    await db.execute("""
      CREATE TABLE trip_user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER NOT NULL,
        name TEXT NOT NULL,
        avatar TEXT NOT NULL,
        pay REAL NOT NULL default 0.0,
        payAct REAL NOT NULL default 0.0,
        foreign key(tripId) references trip(id) on delete cascade on update cascade
      )
    """);

    await db.execute("""
      CREATE TABLE trip_bill (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        pay REAL NOT NULL default 0.0,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        remark TEXT NOT NULL default '',
        aaUsers TEXT NOT NULL default '',
        foreign key(tripId) references trip(id) on delete cascade on update cascade,
        foreign key(userId) references trip_user(id) on delete cascade on update cascade
      )
    """);

    await db.execute("""
      CREATE TABLE trip_bill_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        pay REAL NOT NULL default 0.0,
        foreign key(billId) references trip_bill(id) on delete cascade on update cascade,
        foreign key(userId) references trip_user(id) on delete cascade on update cascade
      )
    """);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {}
}
