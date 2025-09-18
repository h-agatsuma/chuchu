import 'package:test3/db/database_helper1.dart';
import 'package:test3/models/data.dart';
import 'package:sqflite/sqflite.dart';


//テーブルをまたぐ処理・モデル変換
class AppRepository {
  final DatabaseHelper dbHelper;

  AppRepository(this.dbHelper);

  Future<List<Data>> getAllData() async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery('''
    SELECT d.address, d.name, r.feed, r.updateDate, r.battery
    FROM deviceInfo d
    INNER JOIN receptionInfo r
    ON d.address = r.address
    ''');
    return rows.map((r) => Data.fromMap(r)).toList();
  }

  // デバイスと受信情報、両方のテーブルにインサート・更新を行う
  //途中で失敗したときに片方だけ書かれるということがない。
  Future<void> upsertDeviceAndReception(Map<String, dynamic> deviceRow, Map<String, dynamic> receptionRow) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(DatabaseHelper.tableDevice, deviceRow, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert(DatabaseHelper.tableReception, receptionRow, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }




}
