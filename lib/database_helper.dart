import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'initial_data.dart';
import 'package:intl/intl.dart';
import 'package:test3/models/data.dart';

class notDatabaseHelper {
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

  // DatabaseHelper クラスを定義
  notDatabaseHelper._privateConstructor();

  // DatabaseHelper._privateConstructor() コンストラクタを使用して生成されたインスタンスを返すように定義
  // DatabaseHelper クラスのインスタンスは、常に同じものであるという保証
  static final notDatabaseHelper instance = notDatabaseHelper._privateConstructor();

  // Databaseクラス型のstatic変数_databaseを宣言
  // クラスはインスタンス化しない
  static Database? _database;

  // databaseメソッド定義
  // 非同期処理
  Future<Database> get database async {
    // _databaseがNULLか判定
    // NULLの場合、_initDatabaseを呼び出しデータベースの初期化し、_databaseに返す
    // NULLでない場合、そのまま_database変数を返す
    // これにより、データベースを初期化する処理は、最初にデータベースを参照するときにのみ実行されるようになります。
    // このような実装を「遅延初期化 (lazy initialization)」と呼びます。
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // データベース接続
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
    await insertInitialData(db);
  }


  Future<List<Map<String, dynamic>>> rawQueryAll() async {
    final db = await database; // ← ここで必ず非 null の Database を取得

    return await db.rawQuery('''
    SELECT d.address, d.name, r.feed, r.updateDate, r.battery
    FROM deviceInfo d
    INNER JOIN receptionInfo r
    ON d.address = r.address
    ''');
  }

  //Dataに変換して返すメソッド。UIやDeviceManagerはこれを使う
  Future<List<Data>> getAllData() async {
    final rows = await rawQueryAll();
    return rows.map((r) => Data.fromMap(r)).toList();
  }

  //初期データ　batch
  Future<void> insertInitialData(Database db) async {
    final batch = db.batch();

    for (final row in initialDeviceData) {
      batch.insert(tableDevice, row);
    }

    // 受信情報テーブルに初期データ
    for (final row in initialReceptionData) {
      batch.insert(tableReception, {
        ...row,
        'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
      });
    }
    await batch.commit(noResult: true);
    print('初期データを挿入しました');
  }

  // カラム追加したりテーブル名変更したりするときはここに書く
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   if (oldVersion < 2) {
  //     await db.execute('ALTER TABLE $tableReception RENAME COLUMN UpdateDate to updateDate');
  //   }
  // }

  // デバイス情報登録
  Future<int> insertDevice(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      tableDevice,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace, //同じアドレスがあれば更新処理
    );
  }

  // 受信情報情報登録（同じアドレスがあれば更新処理）
  Future<int> insertReception(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      tableReception,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace, //同じアドレスがあれば更新処理
    );
  }

  //登録のみの場合（更新処理無し）
  // Future<int> insert(Map<String, dynamic> row) async {
  //   Database? db = await instance.database;
  //   return await db!.insert(table, row);
  // }

  // 照会処理
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await instance.database;
    return await db.rawQuery('''
    SELECT d.address, d.name, r.feed, r.updateDate, r.battery
    FROM deviceInfo d
    INNER JOIN receptionInfo r
    ON d.address = r.address
    ''');
  }

  // // レコード数を確認
  //   Future<int?> queryRowCount() async {
  //     Database? db = await instance.database;
  //     return Sqflite.firstIntValue(await db!.rawQuery('SELECT COUNT(*) FROM ${table}'));
  //   }


  //　デバイス情報更新
  Future<int> updateDevice(Map<String, dynamic> row) async {
    final db = await instance.database;
    String address = row[columnDeviceAddress];
    return await db.update(
      tableDevice,
      row,
      where: '$columnDeviceAddress= ?',
      whereArgs: [address],
    );
  }

  //　受信情報更新
  Future<int> updateReception(Map<String, dynamic> row) async {
    final db = await instance.database;
    String address = row[columnReceptionAddress];
    return await db.update(
      tableReception,
      row,
      where: '$columnReceptionAddress= ?',
      whereArgs: [address],
    );
  }

  //　デバイス情報削除
  Future<int> deleteDevice(String address) async {
    final db = await instance.database;
    return await db.delete(
      tableDevice,
      where: '$columnDeviceAddress = ?',
      whereArgs: [address],
    );
  }

  //　受信情報削除
  Future<int> deleteReception(String address) async {
    final db = await instance.database;
    return await db.delete(
      tableReception,
      where: '$columnReceptionAddress = ?',
      whereArgs: [address],
    );
  }
}
