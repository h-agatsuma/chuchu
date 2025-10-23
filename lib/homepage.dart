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

class DataMapProvider with ChangeNotifier {
  final Map<String, Data> _dataMap = {};
  Map<String, Data> get dataMap => _dataMap;

  void updateFromList(List<Data> list) {
    _dataMap.clear();
    for (final d in list) {
      _dataMap[d.address] = d;
    }
    notifyListeners();
  }

  Data? getByAddress(String address) => _dataMap[address];
}

class _MyHomePageState extends State<MyHomePage> {
  List<Data> _dbData = []; // 取得データを保持
  List<Data> _query = []; //ソート後のデータを保持
  final myController = TextEditingController(); //TextField の値を取得、変更、リセットできる
  bool _sortedByName = false;
  late final AppRepository repo;

  @override
  void initState() {
    super.initState();
    repo = AppRepository(DatabaseHelper.instance); // クラスフィールドにセット
    _initDb();
    requestPermissions(); //最初に必要な権限をリクエスト
  }

  //bluetooth 接続 権限リクエストメソッド
  Future<void> requestPermissions() async {
    final statusScan = await Permission.bluetoothScan.request();
    final statusConnect = await Permission.bluetoothConnect.request();
    final statusLocation = await Permission.locationWhenInUse.request();

    if (statusScan.isGranted &&
        statusConnect.isGranted &&
        statusLocation.isGranted) {
      debugPrint('必要な権限が許可されました');
    } else {
      print('必要な権限が許可されていません');
    }
  }

  //データ照会（initStateで使う）
  Future<void> _initDb() async {
    await DatabaseHelper.instance.database; // ここで DB が無ければ作られる
    debugPrint('DB 初期化完了');

    final rows = await repo.getAllData(); //照会メソッドを呼び出す

    //マウントされていない＝ウィジェットが画面上にないときはreturn。setStateを呼ばない。
    if (!mounted) return;
    setState(() {
      _dbData = rows;
      _query = List<Data>.from(_dbData);
      _sortedByName = false; // 起動時はソートなしなのでfalse
    });
  }

  // 長押しされたときのメソッド
  Future<void> _openDetailAndApply(Data data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailPage(name: data.name, macAddress: data.address),
      ),
    );

    //result：detailPageから渡される「更新されたかどうか」「アドレス」「名前」の情報
    //名前と日時を変更
    if (result is Map) {
      final address = result['address'] as String?;
      if (address == null) return;

      if (result['updated'] == true) {
        final newName = result['name'] as String? ?? '';

        final idx = _dbData.indexWhere((d) => d.address == address);
        if (idx != -1) {
          setState(() {
            _dbData[idx].name = newName;
            if (_sortedByName) {
              _query = _nameSort(List<Data>.from(_dbData));
            } else {
              _query = List<Data>.from(_dbData);
            }
          });
        } else {
          await _refreshData();
        }

        // ライブ表示があるなら DeviceManager 側の Data も更新
        final deviceManager = context.read<DeviceManager>();
        if (deviceManager.contains(address)) {
          final liveData = deviceManager.getData(address);
          if (liveData != null) {
            final tmp = Data(
              address: address,
              name: newName,
              updateDate: liveData.updateDate,
              feed: liveData.feed,
              battery: liveData.battery,
              manufacturerData: liveData.manufacturerData,
            );
            liveData.updateFrom(tmp); // Data.notifyListeners() が行を更新
          }
        }
      }

      //DetailPageで削除されたとき
      if (result['deleted'] == true) {
        final addrDel = address;
        setState(() {
          _dbData.removeWhere((d) => d.address == addrDel);
          _query = _sortedByName
              ? _nameSort(List<Data>.from(_dbData))
              : List<Data>.from(_dbData);
        });
        // 必要なら deviceManager.removeDevice(addrDel) を呼ぶ実装を作る
      }
    }
  }

  //汎用の再取得メソッド 詳細画面から戻ってきたときにも使う
  Future<void> _refreshData() async {
    final rows = await repo.getAllData();
    if (!mounted) return;

    // 常に原データを更新
    _dbData = rows;

    if (_sortedByName) {
      // ソート適用して表示用にセット
      _query = _nameSort(List<Data>.from(_dbData));
    } else {
      // DBの順（最新）で表示
      _query = List<Data>.from(_dbData);
    }

    setState(() {});
  }

  //ソート
  List<Data> _nameSort(List<Data> allRows) {
    final indexed = allRows
        .asMap()
        .entries
        .toList(); // MapEntry<int, Data> インデックスと値がセットになったリスト

    // 名前あり優先で並べ替え　インデックス：元の順番（元の順に戻すなら使用）
    indexed.sort((a, b) {
      final nameA = (a.value.name ?? '').trim();
      final nameB = (b.value.name ?? '').trim();

      final hasNameA = nameA.isNotEmpty;
      final hasNameB = nameB.isNotEmpty;

      if (hasNameA && !hasNameB) return -1; // A が null じゃなくて、B が null なら A を前に
      if (!hasNameA && hasNameB) return 1; // A が null で、B が null じゃないなら B を前に
      if (!hasNameA && !hasNameB) return 0; // 両方名前なしなら同順位

      // 両方名前あり -> アルファベット順（大文字小文字を区別しない）
      final cmp = nameA.toLowerCase().compareTo(nameB.toLowerCase());
      if (cmp != 0) return cmp; //アルファベット順でソートする
      return a.key.compareTo(b.key); //同じ名前はインデックス順でソートする
    });

    //リストの中のvalue(中身)だけをリストにして渡す
    return indexed.map((e) => e.value).toList();
  }

  //ボタンによる切替メソッド
  void _toggleSortByName() {
    setState(() {
      if (!_sortedByName) {
        _query = _nameSort(List<Data>.from(_dbData));
        _sortedByName = true; //ボタンが押されたときfalseならtrueに変える
      } else {
        _query = List<Data>.from(_dbData);
        _sortedByName = false; //trueならfalseに変える
      }
    });
  }

  @override
  void dispose() {
    context.read<DeviceManager>().stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        debugPrint('[UI] Consumer rebuild count=${deviceManager.data.length}');

        //DeviceManager からのデータを受け取る
        //探索中かどうか
        final isScanning = deviceManager.isScanning;

        //マージ後もソートがつかえるようにする。_sortedByNameがtrueのとき、ソートする。
        final baseDbList = _sortedByName
            ? _nameSort(List<Data>.from(_dbData))
            : List<Data>.from(_dbData);
        final dbUI = _mergeDbAndLive(baseDbList, deviceManager.data,deviceManager);

        // Mapを作成（addressをキーにしたMap）
        final Map<String, Data> dbUIMap = {for (var d in dbUI) d.address: d};
        //UIに表示しているデータをdeviceManagerでも使えるようにする
       deviceManager.updateDbUI(dbUIMap);

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
                    print('[UI] スキャン停止');
                    deviceManager.stopScan();
                  } else {
                    print('[UI] スキャン開始');
                    deviceManager.startScan(
                      simulated: true,
                      simulatedList: bluetoothData,
                    ); //テスト用にリストとtrue渡す
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
                  children: [
                    SizedBox(width: 40, child: Icon(Icons.bolt)),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _toggleSortByName, //ソート切替ボタンが押されたら
                        child: Text(
                          'Address/Name',
                          textAlign: TextAlign.center,
                        ),
                      ),
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
                child: ListView.separated(
                  itemCount: dbUI.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final row = dbUI[index];
                    final isLive = deviceManager.contains(row.address);
                    if (isLive) {
                      final live = deviceManager.getData(row.address)!;
                      return ChangeNotifierProvider.value(
                        key: ValueKey(live.address),
                        value: live,
                        child: Consumer<Data>(
                          builder: (context, d, _) {
                            return _buildRow(
                              context,
                              d,
                              true,
                              () => _openDetailAndApply(d),
                            );
                          },
                        ),
                      );
                    } else {
                      return _buildRow(
                        context,
                        row,
                        false,
                        () => _openDetailAndApply(row),
                      );
                    }
                  },
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

  //DBデータとBLEデータをマージ
  List<Data> _mergeDbAndLive(List<Data> dbData, List<Data> liveData, DeviceManager manager) {
    final dbAddresses = dbData.map((d) => d.address).toSet();
    final Map<String, Data> result = {
      for (var d in dbData) d.address: d, // DBのデータがベース
    };

    final now = DateTime.now();
    for (var ld in liveData) {
      if (dbAddresses.contains(ld.address)) {
        //result[ld.address] = ld; // BLE受信データで上書き
        final ble = manager.getData(ld.address); // BLE 側のインスタンスを使う
        if (ble != null) result[ld.address] = ble;
      } else {
        // 未登録だが受信が5分以内なら表示
        if (now.difference(ld.updateDate).inMinutes <= 5) {
          //result[ld.address] = ld;
          final ble = manager.getData(ld.address);
          if (ble != null) result[ld.address] = ble;
        }
      }
    }
    return result.values.toList();
  }
}

Widget _buildRow(
  BuildContext context,
  Data data,
  bool isLive, [
  VoidCallback? onLongPress,
]) {
  final batteryPercent = ((data.battery - 800) / 4).floor().clamp(
    0,
    100,
  ); //バッテリー ％に計算
  final displayString = DateFormat(
    'yyyy/MM/dd\nHH:mm:ss',
  ).format(data.updateDate);

  return InkWell(
    onLongPress: onLongPress,
    child: SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Icon(
                Icons.bolt,
                color: (isLive && data.isReceiving) ? Colors.black : Colors.transparent, //データ未受信の際はアイコン透明に。
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                (data.name?.isNotEmpty ?? false) ? data.name! : data.address,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 80,
              child: Center(child: Text(data.feed == 0 ? 'LEFT' : 'NO LEFT')),
            ),
            SizedBox(width: 70, child: Center(child: Text('$batteryPercent%'))),
            SizedBox(width: 80, child: Center(child: Text(displayString))),
          ],
        ),
      ),
    ),
  );
}

// BLE 受信中（ChangeNotifierProviderで通知あり）
class DataRowWidget extends StatelessWidget {
  const DataRowWidget({super.key});

  @override
  Widget build(BuildContext context) {

    final data = context.watch<Data>();
    debugPrint('Widget build: listening data=${data.hashCode}');

    return _buildRow(context, data, true);
  }
}

// DBのみ（通知なし）
class StaticDataRow extends StatelessWidget {
  final Data data;

  const StaticDataRow({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return _buildRow(context, data, false, () async {
      // 詳細画面を開けるようにする（必要なら）
      final homeState = context.findAncestorStateOfType<_MyHomePageState>();
      if (homeState != null) await homeState._openDetailAndApply(data);
    });
  }
}
