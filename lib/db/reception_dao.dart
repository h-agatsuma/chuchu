import 'package:test3/db/database_helper1.dart';
import 'package:sqflite/sqflite.dart';
import 'package:test3/models/data.dart';

//受信情報
class ReceptionDao{

  final DatabaseHelper dbHelper;
  ReceptionDao(this.dbHelper);

//　該当データが存在するか確認（デバイス名を変更する際、インサート前ではないかチェック）
  Future<bool> checkReception(String address) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'receptionInfo',
      where: 'address = ?',
      whereArgs: [address],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // 登録
  Future<int> insertReception(Map<String, dynamic> row) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableReception,
      row,
    );
  }

  //　受信情報更新
  Future<int> updateReception(Map<String, dynamic> row) async {
    final db = await dbHelper.database;
    String address = row['address'];
    return await db.update(
      DatabaseHelper.tableReception,
      row,
      where: 'address= ?',
      whereArgs: [address],
    );
  }


  //　受信情報削除
  Future<int> deleteReception(String address) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableReception,
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  //受信した情報バッチメソッド
  Future<void> batchInsertReceptions(List<Map<String, dynamic>> rows) async {
    print('[ReceptionDao] batchUpsertReceptions called rows=${rows.length}');
    if (rows.isEmpty) return;
    final db = await dbHelper.database;
    print('[ReceptionDao] DB path=${db.path}');

    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final row in rows) {
          print('[ReceptionDao] adding row keys=${row.keys} address=${row['address']} feed=${row['feed']} battery=${row['battery']} updateDate=${row['updateDate'].runtimeType}:${row['updateDate']}');
          batch.insert(DatabaseHelper.tableReception, row);
        }
        print('[ReceptionDao] committing batch');
        await batch.commit(noResult: true);
        print('[ReceptionDao] commit done');
      });

      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableReception}'));
      print('[ReceptionDao] reception count=$count');

      final sample = await db.query(DatabaseHelper.tableReception, limit: 5);
      print('[ReceptionDao] sample rows=$sample');
    } catch (e, st) {
      print('[ReceptionDao] batchUpsert failed: $e\n$st');
      rethrow;
    }
  }



  Future<List<Map<String, dynamic>>> queryAllReceptions() async {
    final db = await dbHelper.database;
    return await db.query(DatabaseHelper.tableReception);
  }



}