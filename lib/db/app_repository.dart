import 'package:test3/db/database_helper1.dart';
import 'package:test3/models/data.dart';
import 'package:sqflite/sqflite.dart';

//テーブルをまたぐ処理・モデル変換
class AppRepository {
  final DatabaseHelper dbHelper;

  AppRepository(this.dbHelper);

  //UI一覧表示 登録済みデバイスと最新データ+未登録の受信デバイス
  Future<List<Data>> getAllData() async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery('''
SELECT *
FROM (
  SELECT d.id, d.address, d.name, r.feed, r.battery, r.updateDate
  FROM deviceInfo d
  LEFT JOIN (
    SELECT address, feed, battery, updateDate
    FROM receptionInfo
    WHERE (address, updateDate) IN (
      SELECT address, MAX(updateDate)
      FROM receptionInfo
      GROUP BY address
    )
  ) r ON d.address = r.address

  UNION ALL

  SELECT NULL as id, r.address, NULL as name, r.feed, r.battery, r.updateDate
  FROM receptionInfo r
  WHERE r.address NOT IN (SELECT address FROM deviceInfo)
    AND r.updateDate > datetime('now', '-5 minutes')
    AND (address, updateDate) IN (
      SELECT address, MAX(updateDate)
      FROM receptionInfo
      GROUP BY address
    )
) sub
ORDER BY
  id IS NULL,
  id,
  updateDate DESC;

  ''');
    return rows.map((r) => Data.fromMap(r)).toList(); //Data 型使用
  }

  // デバイスと受信情報、両方のテーブルにインサート・更新を行う
  //途中で失敗したときに片方だけ書かれるということがない。
  Future<void> upsertDeviceAndReception(
    Map<String, dynamic> deviceRow,
    Map<String, dynamic> receptionRow,
  ) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        DatabaseHelper.tableDevice,
        deviceRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        DatabaseHelper.tableReception,
        receptionRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
