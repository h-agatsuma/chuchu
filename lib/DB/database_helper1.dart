import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../initial_data.dart';
import 'package:intl/intl.dart';


class DatabaseHelper {

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static final _databaseName = "MyDatabase.db"; // DB名
  static final _databaseVersion = 1; // スキーマのバージョン指定

  //デバイス情報テーブル
  static final tableDevice = 'deviceInfo'; // テーブル名:deviceInfo
  static final columnDeviceAddress = 'address'; // カラム名：address
  static final columnName = 'name'; // カラム名:name

  //受信情報テーブル
  static final tableReception = 'receptionInfo'; // テーブル名:receptionInfo
  static final columnReceptionAddress = 'address'; // カラム名：address
  static final columnFeed = 'feed'; // カラム名：feed
  static final columnDate = 'updateDate'; // カラム名：updateDate
  static final columnBattery = 'battery'; // カラム名：battery

  Database? db;

  Future<Database> get database async {
    // _databaseがNULLか判定
    // NULLの場合、_initDatabaseを呼び出しデータベースの初期化し、_databaseに返す
    // NULLでない場合、そのまま_database変数を返す
    // これにより、データベースを初期化する処理は、最初にデータベースを参照するときにのみ実行されるようになります。
    // このような実装を「遅延初期化 (lazy initialization)」と呼びます。
    if (db != null) return db!;
    db = await _initDatabase();
    return db!;
  }

  Future<Database> _initDatabase() async {
    // アプリケーションのドキュメントディレクトリのパスを取得
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // 取得パスを基に、データベースのパスを生成
    String path = join(documentsDirectory.path, _databaseName);
    // データベース接続
    return await openDatabase(
      path,
      version: _databaseVersion,
      // テーブル作成メソッドの呼び出し
      onCreate: _onCreate,
      //onUpgrade: _onUpgrade, 変更時に使用
    );
  }

  // テーブル作成
  // 引数:dbの名前
  // 引数:スキーマーのversion
  // スキーマーのバージョンはテーブル変更時にバージョンを上げる（テーブル・カラム追加・変更・削除など）
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableReception (
            $columnReceptionAddress TEXT PRIMARY KEY,
            $columnFeed INTEGER DEFAULT 0,
            $columnDate TEXT NOT NULL DEFAULT '',
            $columnBattery INTEGER DEFAULT 0
          )
          ''');

    await db.execute('''
          CREATE TABLE $tableDevice (
            $columnDeviceAddress TEXT PRIMARY KEY,
            $columnName TEXT NULL
          )
          ''');


    final batch = db.batch();

    for (final row in initialDeviceData) {
      batch.insert(tableDevice, row);
    }
    for (final row in initialReceptionData) {
      batch.insert(tableReception, {
        ...row,
        'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
      });
    }
    await batch.commit(noResult: true);
  }
}