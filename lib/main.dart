import 'package:flutter/material.dart'; //絶対必要
import 'package:test3/db/database_helper1.dart'; //データベースで使った
import 'package:intl/intl.dart'; //時刻で使った
import 'DetailPage.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test3/models/data.dart';
import 'device_manager.dart';
import 'package:test3/DB/app_repository.dart';
import 'bluetooth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //DatabaseHelperクラスのインスタンス取得
  final dbHelper = DatabaseHelper.instance;
  final repo = AppRepository(dbHelper);       // Repository（JOIN等の複雑処理）
  final btService = BluetoothService();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: dbHelper),
        Provider<AppRepository>.value(value: repo),
        Provider<BluetoothService>.value(value: btService),
        ChangeNotifierProvider<DeviceManager>(
          create: (_) => DeviceManager(repo: repo, bt: btService)..loadAll(),
          // dispose: (_, m) => m.dispose(), // DeviceManagerがdisposeを持つなら明示的に
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChuChuCheckApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,

      ),

      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {


  //bluetooth接続　権限リクエストメソッド
  Future<void> requestPermissions() async {
    final statusScan = await Permission.bluetoothScan.request();
    final statusConnect = await Permission.bluetoothConnect.request();
    final statusLocation = await Permission.locationWhenInUse.request();

    if (statusScan.isGranted && statusConnect.isGranted && statusLocation.isGranted) {
      context.read<DeviceManager>().startScan();
    } else {
      print('必要な権限が許可されていません');
    }
  }


  //final deviceManager = DeviceManager.instance;

  List<Map<String, dynamic>> _query = []; // 取得データを保持
  final myController = TextEditingController(); //TextFieldの値を取得、変更、リセットできる

  @override
  void initState() {
    super.initState();
    // requestPermissions(); //最初に必要な権限をリクエスト
     _queryData(); // ←  初期化時にリスト表示
  }

  @override
  void dispose() {
    context.read<DeviceManager>().stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
        builder: (context, deviceManager, _) {
          // 仮のデータ（あとで DB から取得する想定）
          // final List<Map<String, String>> row = [
          //   {
          //     'macAddress': DatabaseHelper.columnDeviceAddress,
          //     'name': DatabaseHelper.columnName,
          //     'status': DatabaseHelper.columnFeed,
          //     'battery': DatabaseHelper.columnBattery,
          //   },
          //   {
          //     'macAddress': 'F3:46:B4:FF:23:34:84:4A',
          //     'name': "",
          //     'status': 'Noleft',
          //     'battery': '5%',
          //     'update': '25/09/31\n12:00:12',
          //   },
          // ];

          final date = DatabaseHelper.columnDate;
          final address = DatabaseHelper.columnDeviceAddress;
          final name = DatabaseHelper.columnName;
          final feed = DatabaseHelper.columnFeed;
          final battery = DatabaseHelper.columnBattery;

          //DeviceManagerからのデータを受け取る
          //探索中かどうか
          final isScanning = deviceManager.isScanning;
          //実際に入っているデータ
          final devices = deviceManager.devices.values.toList();




          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'ChuChuCheckApp',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
              backgroundColor: Colors.green,
              actions: [
                TextButton(
                  onPressed: () {
                    if (isScanning) {
                      deviceManager.stopScan();
                    } else {
                      deviceManager.startScan();
                    }
                  },
                  child: Text(
                    isScanning ? 'STOP SCANNING' : 'SCAN',
                    style: TextStyle(fontSize:18, color: Colors.yellow),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // ヘッダー行
                Container(
                  color: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  child: Row(
                    children: const [
                      SizedBox(width: 40, child: Icon(Icons.bolt)),
                      Expanded(
                        flex: 2,
                        child: Text(
                            'Address/Name', textAlign: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            'Bait\nStatus', textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text('Battery\nLv', textAlign: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            'Last\nUpdate', textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),

                // データ行
                Expanded(
                  child: _query.isEmpty
                      ? Center(child: Text('データがありません'))
                      : SizedBox(
                    height: 70,
                    child: ListView.separated(
                      //区切り線有りのリスト
                      itemCount: _query.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final row = _query[index]; //index番目の人の情報を格納

                        //検討　アイコンの表示isReceivingにも関係する変数
                        final device = devices[index]; //Bluetoothで受信したデバイスのデータ。DBの情報とのマージ必要？


                        //DBから取り出した16進数をString型にする
                        final String battery16 = row[battery]
                            .toString()
                            .toUpperCase();
                        //16進数を％に計算
                        final int batteryPercent = convertBatteryPercent(
                          battery16,
                        );

                        // final macAddress = DatabaseHelper.columnDeviceAddress;
                        // final name = DatabaseHelper.columnName;
                        // 'status': DatabaseHelper.columnFeed,
                        // 'battery': DatabaseHelper.columnBattery,

                        // final dateTimeString =
                        //     row[DatabaseHelper.columnDate] as String;

                        //更新日時をString型に変換
                        final dateTimeString = row[date] as String;

                        //日時表示用。日付と時刻の間のスペースを改行に置き換える
                        String displayString = dateTimeString.replaceFirst(
                          ' ',
                          '\n',
                        );

                        return InkWell(
                          onLongPress: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailPage(
                                      name: row[name],
                                      macAddress: row[address]!,
                                    ),
                              ),
                            );

                            if (result == true) {
                              _queryData();
                            }
                          },

                          child: SizedBox(
                            height: 70,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),

                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    //isReceivingがtrueのときアイコン表示、falseのとき透明に
                                    child: Opacity(
                                      opacity: device.isReceiving ? 1.0 : 0.0,
                                      child: Icon(Icons.bolt),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      (row[name] != null &&
                                          row[name]!.isNotEmpty)
                                          ? row[name]!
                                          : row[address]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  SizedBox(
                                    width: 80,
                                    child: Center(
                                      child: Text(
                                        int.tryParse(row[feed].toString()) == 0
                                            ? 'NO LEFT'
                                            : 'LEFT',
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    width: 70,
                                    child: Center(
                                      child: Text(
                                        '${batteryPercent.toString()}%',
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    width: 80,
                                    child: Center(child: Text(displayString)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            bottomNavigationBar: Container(
              color: Colors.green, // 背景色
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // 中央寄せ
                children: [
                  //insertメソッド使わない場合はconstつけてもエラー出ない
                  SizedBox(width: 8),
                  // アイコンと文字の間隔
                  Text(
                    "Powered by Signpost Co., Ltd.",
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.image, size: 20),

                  // //テキストフィールド
                  // TextField(controller: myController),
                  // // ボタン群
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          child: Text('登録', style: TextStyle(fontSize: 20)),
                          onPressed: _insert,
                        ),
                        // ElevatedButton(
                        //   child: Text('照会', style: TextStyle(fontSize: 20)),
                        //   onPressed: _queryData,
                        // ),
                        // ElevatedButton(
                        //   child: Text('更新', style: TextStyle(fontSize: 20)),
                        //   onPressed: _update,
                        // ),
                        // ElevatedButton(
                        //   child: Text('削除', style: TextStyle(fontSize: 20)),
                        //   onPressed: _delete,
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  // 登録ボタンクリック
  void _insert() async {
    DateTime now = DateTime.now(); //現在の時刻をDateTime型で取得
    String datetime = DateFormat(
      'yyyy/MM/dd HH:mm:ss',
    ).format(now); //現在時刻をフォーマットしたものをString型の変数に格納

    Map<String, dynamic> rowdev = {
      DatabaseHelper.columnDeviceAddress: '66:BB:CC:DD:EE:FF', // ダミーMACアドレス
      // DatabaseHelper.columnName: 'テストデバイス',
    };

    Map<String, dynamic> rowrec = {
      DatabaseHelper.columnReceptionAddress: '66:BB:CC:DD:EE:FF',
      // ダミーMACアドレス
      DatabaseHelper.columnFeed: 2,
      DatabaseHelper.columnDate: datetime,
      DatabaseHelper.columnBattery: 380,
    };
    await dbHelper.insertDevice(rowdev);
    await dbHelper.insertReception(rowrec);
    print('テストデータを登録しました');
    _queryData();
  }

  // 照会ボタンクリック
  void _queryData() async {
    //dbHelper.queryAllRows()の戻り値が読み取り専用のため、リストをコピーしてからソートする。
    final allRows = List<Map<String, dynamic>>.from(
      await dbHelper.queryAllRows(),
    );
    //final allRows = await dbHelper.queryAllRows();
    //print('全てのデータを照会しました。');
    // for (final row in allRows) {
    //   print('row: $row');
    //   print('keys: ${row.keys}');
    // }

    // 名前あり優先で並べ替え
    allRows.sort((a, b) {
      final nameA = a['name'];
      final nameB = b['name'];

      final hasNameA = nameA != null && nameA.toString().trim().isNotEmpty;
      final hasNameB = nameB != null && nameB.toString().trim().isNotEmpty;

      if (hasNameA && !hasNameB) return -1; // Aがnullじゃなくて、BがnullならAを前に
      if (!hasNameA && hasNameB) return 1; // Aがnullで、BがnullじゃないならBを前に
      return 0; // どちらも同じなら順番変更なし
    });

    setState(() {
      _query = allRows; //_queryという配列にデータを格納
    });
  }

  // 更新ボタンクリック
  void _update() async {
    DateTime now = DateTime.now();
    DateFormat format = DateFormat('yyyy/MM/dd HH:mm:ss');
    String datetime = format.format(now);
    final nameText = myController.text; //更新ボタンが押されたときに、画面で入力されたテキストを取得
    Map<String, dynamic> rowdev = {
      DatabaseHelper.columnDeviceAddress: 'AA:BB:CC:DD:EE:FF', // ダミーMACアドレス
      DatabaseHelper.columnName: nameText, //取得したテキストをDBに登録
    };
    Map<String, dynamic> rowrec = {
      DatabaseHelper.columnReceptionAddress: 'AA:BB:CC:DD:EE:FF',
      // ダミーMACアドレス
      DatabaseHelper.columnFeed: 0,
      DatabaseHelper.columnDate: datetime,
      DatabaseHelper.columnBattery: 80,
    };
    final rowsAffected = await dbHelper.updateDevice(rowdev);
    await dbHelper.updateReception(rowrec);
    print('更新しました。 $rowsAffected 件のデータを更新しました。 ');
  }

  // 削除ボタンクリック
  void _delete() async {
    const address = "AA:BB:CC:DD:EE:FF"; // 削除したいMACアドレス　テスト用
    final rowsDeleted = await dbHelper.deleteDevice(address);
    await dbHelper.deleteReception(address);
    print('削除しました。 $rowsDeleted 件のデータを削除しました。');
  }

  //バッテリーを16進数から％に計算
  int convertBatteryPercent(String strBattery) {
    if (strBattery.isEmpty) return 0;
    int raw = int.parse(strBattery, radix: 16); //16進数の文字列を10進数に
    double percent = (raw - 800) / 4; //所定の計算式
    int battery = percent.floor(); //少数切り捨て
    return battery.clamp(0, 100); //範囲を0から100に
  }
}

// // 照会ボタンクリック
// void _battery() async {
//
//
//   // 名前あり優先で並べ替え
//   allRows.sort((a, b) {
//     final nameA = a['name'];
//     final nameB = b['name'];
//
//     final hasNameA = nameA != null && nameA.toString().trim().isNotEmpty;
//     final hasNameB = nameB != null && nameB.toString().trim().isNotEmpty;
//
//     if (hasNameA && !hasNameB) return -1; // Aがnullじゃなくて、BがnullならAを前に
//     if (!hasNameA && hasNameB) return 1; // Aがnullで、BがnullじゃないならBを前に
//     return 0; // どちらも同じなら順番変更なし
//   });
//
//   setState(() {
//     _query = allRows; //_queryという配列にデータを格納
//   });
// }
