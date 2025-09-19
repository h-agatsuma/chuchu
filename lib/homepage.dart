import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'DetailPage.dart';

//ble
import 'ble/bluetooth_service.dart'; // ← BLE サービスを分離して使う
import 'ble/device_manager.dart'; // ← BLE サービスを分離して使う
//db
import 'db/database_helper1.dart';
import 'db/app_repository.dart';
import 'db/device_dao.dart';
import 'db/initial_data.dart';
import 'db/reception_dao.dart';

//models
import 'models/data.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //bluetooth 接続 権限リクエストメソッド
  Future<void> requestPermissions() async {
    final statusScan = await Permission.bluetoothScan.request();
    final statusConnect = await Permission.bluetoothConnect.request();
    final statusLocation = await Permission.locationWhenInUse.request();

    if (statusScan.isGranted &&
        statusConnect.isGranted &&
        statusLocation.isGranted) {
      context.read<DeviceManager>().startScan();
    } else {
      print('必要な権限が許可されていません');
    }
  }

  //final deviceManager = DeviceManager.instance;

  List<Map<String, dynamic>> _query = []; // 取得データを保持
  final myController = TextEditingController(); //TextField の値を取得、変更、リセットできる

  @override
  void initState() {
    super.initState();
    _initDb();
    // requestPermissions(); //最初に必要な権限をリクエスト
    _queryData(); // ←  初期化時にリスト表示
  }

  Future<void> _initDb() async {
    await DatabaseHelper.instance.database; // ここで DB が無ければ作られる
    debugPrint('DB 初期化完了');
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
        final date = DatabaseHelper.columnDate;
        final address = DatabaseHelper.columnDeviceAddress;
        final name = DatabaseHelper.columnName;
        final feed = DatabaseHelper.columnFeed;
        final battery = DatabaseHelper.columnBattery;

        //DeviceManager からのデータを受け取る
        //探索中かどうか
        final isScanning = deviceManager.isScanning;
        //実際に入っているデータ
        // final devices = deviceManager.getAllData();

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
                  style: TextStyle(fontSize: 18, color: Colors.yellow),
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
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  children: const [
                    SizedBox(width: 40, child: Icon(Icons.bolt)),
                    Expanded(
                      flex: 2,
                      child: Text('Address/Name', textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Bait\nStatus', textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: Text('Battery\nLv', textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('Last\nUpdate', textAlign: TextAlign.center),
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
                            final row = _query[index]; //index 番目の人の情報を格納

                            //検討 アイコンの表示 isReceiving にも関係する変数
                            // final device = devices[index]; //Bluetooth で受信したデバイスのデータ。DB の情報とのマージ必要？

                            //DB から取り出した 16 進数を String 型にする
                            final String battery16 = row[battery]
                                .toString()
                                .toUpperCase();
                            //16 進数を％に計算
                            final int batteryPercent = convertBatteryPercent(
                              battery16,
                            );

                            //更新日時を String 型に変換
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
                                    builder: (context) => DetailPage(
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
                                        // isReceiving が true のときアイコン表示、false のとき透明に
                                        //  child: Opacity(
                                        //    opacity: device.isReceiving ? 1.0 : 0.0,
                                        //    child: Icon(Icons.bolt),
                                        //  ),
                                        child: Icon(Icons.bolt),
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
                                            int.tryParse(
                                                      row[feed].toString(),
                                                    ) ==
                                                    0
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
                                        child: Center(
                                          child: Text(displayString),
                                        ),
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
                //insert メソッド使わない場合は const つけてもエラー出ない
                SizedBox(width: 8),
                // アイコンと文字の間隔
                Text(
                  "Powered by Signpost Co., Ltd.",
                  style: TextStyle(fontSize: 14),
                ),
                Icon(Icons.image, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // 照会
  void _queryData() async {
    final dbHelper = DatabaseHelper.instance;
    final repo = AppRepository(dbHelper);
    //dbHelper.queryAllRows() の戻り値が読み取り専用のため、リストをコピーしてからソートする。
    final rows = await repo.getAllData();
    // List.unmodifiable ではなく、明示的にコピーする
    final allRows = List<Map<String, dynamic>>.from(rows);
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

      if (hasNameA && !hasNameB) return -1; // A が null じゃなくて、B が null なら A を前に
      if (!hasNameA && hasNameB) return 1; // A が null で、B が null じゃないなら B を前に
      return 0; // どちらも同じなら順番変更なし
    });

    setState(() {
      _query = allRows; //_query という配列にデータを格納
    });
  }

  //バッテリーを 16 進数から％に計算
  int convertBatteryPercent(String strBattery) {
    if (strBattery.isEmpty) return 0;
    int raw = int.parse(strBattery, radix: 16); //16 進数の文字列を 10 進数に
    double percent = (raw - 800) / 4; //所定の計算式
    int battery = percent.floor(); //少数切り捨て
    return battery.clamp(0, 100); //範囲を 0 から 100 に
  }
}
