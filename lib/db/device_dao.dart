import 'package:test3/db/database_helper1.dart';
import 'package:sqflite/sqflite.dart';

//デバイス情報
class DeviceDao {
  final DatabaseHelper dbHelper;

  DeviceDao(this.dbHelper);

  Future<int> upsertDevice(Map<String, dynamic> row) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      final address = row['address'];

      // UPDATE する際は id を更新しないようにコピーを作る
      final updateRow = Map<String, dynamic>.from(row);
      updateRow.remove('id');

      final updatedCount = await txn.update(
        DatabaseHelper.tableDevice,
        updateRow,
        where: 'address = ?',
        whereArgs: [address],
      );

      if (updatedCount > 0) {
        // 更新済みならその行の id を返す
        final q = await txn.query(
          DatabaseHelper.tableDevice,
          columns: ['id'],
          where: 'address = ?',
          whereArgs: [address],
          limit: 1,
        );
        return q.first['id'] as int;
      } else {
        // 存在しなければ挿入（この時点で id が発番される）
        return await txn.insert(DatabaseHelper.tableDevice, row);
      }
    });
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
