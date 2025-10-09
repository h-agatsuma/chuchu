import 'package:test3/db/database_helper1.dart';
import 'package:sqflite/sqflite.dart';

//デバイス情報
class DeviceDao {
  final DatabaseHelper dbHelper;

  DeviceDao(this.dbHelper);

  // 登録
  Future<int> upsertDevice(Map<String, dynamic> row) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableDevice,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace, //同じアドレスがあれば更新処理
    );
  }

  //　更新
  Future<int> updateDevice(Map<String, dynamic> row) async {
    final db = await dbHelper.database;
    String address = row['address'];
    return await db.update(
      DatabaseHelper.tableDevice,
      row,
      where: 'address= ?',
      whereArgs: [address],
    );
  }

  //　削除（deviceInfoのデリートフラグ1に変更）
  Future<int> deleteDevice(String address) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.tableDevice,
      {'deleteFlag': 1},
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllDevices() async {
    final db = await dbHelper.database;
    return await db.query(DatabaseHelper.tableDevice);
  }
}
