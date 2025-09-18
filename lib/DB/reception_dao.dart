import 'package:test3/db/database_helper1.dart';
import 'package:sqflite/sqflite.dart';

//受信情報
class ReceptionDao{

  final DatabaseHelper dbHelper;
  ReceptionDao(this.dbHelper);

  // 登録（同じアドレスがあれば更新処理）
  Future<int> insertReception(Map<String, dynamic> row) async {
    final db = await dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableReception,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace, //同じアドレスがあれば更新処理
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


  Future<List<Map<String, dynamic>>> queryAllReceptions() async {
    final db = await dbHelper.database;
    return await db.query(DatabaseHelper.tableReception);
  }



}