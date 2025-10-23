import 'package:flutter/material.dart';
import 'bluetooth_service.dart';
import 'dart:async';
import 'package:test3/db/app_repository.dart';
import 'package:test3/db/reception_dao.dart';
import 'package:test3/models/data.dart';
import 'package:test3/db/database_helper1.dart';
import 'package:test3/homepage.dart';
import 'bluetooth_service.dart';
import 'dart:typed_data'; //Uint8List に必要
import 'dart:math'; //min に必要

//生データを渡す
class DeviceManager extends ChangeNotifier {
  // 指定のアドレスを持つデータがあるかどうかを返す
  bool contains(String address) {
    return _data.containsKey(address);
  }

  // 指定のアドレスのDataを返す
  Data? getData(String address) {
    return _data[address];
  }

  final BluetoothService _bluetoothService;
  final AppRepository repo;

  final Map<String, Data> _data = {}; // ← Map に変更
  StreamSubscription<Data>? _deviceSub; //データを流すストリームに対する購読

  Map<String, Data> _dbUIMap = {}; // ← UIに表示されている値（Map）を一時的に保持しておく変数

  //_dataインスタンスを参照し、homepageのdbUIMapの値を使えるようにする。
  void updateDbUI(Map<String, Data> newDbUIMap) {
    _dbUIMap = {
      for (final e in newDbUIMap.entries)
        e.key: _data[e.key] ?? e.value,
    };
  }

  bool _isScanning = false; //探索中かどうか

  // 新保存キュー（reception 用の Map）
  final List<Map<String, dynamic>> _saveQueue = [];
  Timer? _flushTimer;
  bool _isFlushing = false;

  DeviceManager({
    required BluetoothService bluetoothService,
    required this.repo,
  }) : _bluetoothService = bluetoothService;

  List<Data> get data => _data.values.toList(); // UI 用に List を返す

  bool get isScanning => _isScanning; //他のクラスから「isScanning」がつかえるようにする
  final Map<String, Data> _dbSnapshot = {}; //DBから取得したデータを格納

  Future<void> loadAll() async {
    final list = await repo.getAllData(); // List<Map<String, dynamic>>
    _dbSnapshot //DBから取得したデータ
      ..clear()
      ..addEntries(
        list.map((Data item) => MapEntry(item.address, item)),
      ); //DB から取得したリストが Map に入る
  }

  //UI 側で呼ぶ。（ボタンを押したときなど）
  void startScan({
    bool simulated = false,
    List<Map<String, dynamic>>? simulatedList,
  }) {
    print('[DeviceManager] startScan called simulated=$simulated');

// スキャン開始時に受信状態をリセット（アイコンOFF）
    for (final d in _data.values) {
      d.forceStopReceiving(); // ← updateDateは保持
    }

    if (_deviceSub != null) {
      print('[DeviceManager] already subscribed, returning');
      return;
    }
    if (simulated && simulatedList != null) {
      print('[DeviceManager] calling startSimulatedScan');
      _bluetoothService.startSimulatedScan(simulatedList);
    } else {
      _bluetoothService.startScan(); //BluetoothService クラスの startScan メソッドを呼び出す
    }

    _isScanning = true; //探索中にする
    notifyListeners(); //データが変わったことを知らせる

    // 定期フラッシュタイマー（5秒ごとにまとめて保存する）
    _flushTimer ??= Timer.periodic(
      Duration(seconds: 5),
      (_) => _flushSaveQueue(),
    );

    _deviceSub = _bluetoothService.deviceStream.listen(
      (device) {
        final address = device.address;
        final raw = device.manufacturerData; // List<int> or Uint8List

        Data newDevice;
        // スキャン受信ハンドラ内の if 部分 多分ここのif文いらない。Dataクラスで変換しているのでelseの部分だけで十分。
        if (raw != null && raw.length >= 3) {
          // 先頭3バイトだけ使う
          final List<int> mData = raw.sublist(0, 3);

          // feed: 1バイト目
          final int feed = mData[0] & 0xFF;

          // batteryRaw: 2バイト目（上位）と3バイト目（下位）を結合（ビッグエンディアン想定）
          final int battery = ((mData[1] & 0xFF) << 8) | (mData[2] & 0xFF);

          // Data の生成（Data クラスが次のようなコンストラクタを持つことを前提）
          newDevice = Data(
            address: address,
            name: device.name ?? '',
            updateDate: DateTime.now(),
            feed: feed,
            battery: battery,
            manufacturerData: Uint8List.fromList(mData), // 任意で生データも保持
          );
        } else {
          // simulated データなど、既に feed/battery がある場合はこちらを使う
          newDevice = Data(
            address: device.address,
            name: device.name ?? '',
            updateDate: DateTime.now(),
            feed: device.feed,
            battery: device.battery,
            manufacturerData: device.manufacturerData != null
                ? Uint8List.fromList(device.manufacturerData!)
                : null,
          );
          debugPrint(
            '[DeviceManager] using device.feed/device.battery feed=${newDevice.feed} bat=${newDevice.battery}',
          );
        }

        // ここで既存比較やキュー追加などの処理を続ける
        final oldDevice = _dbSnapshot[address]; //DBから取得したデータ
        final uiDevice = _dbUIMap[address]; //UIに表示されているデータ

        if (oldDevice != null) {
          oldDevice.resumeReceiving(); // 受信再開時に強制停止フラグを解除
          if (newDevice.name == null || newDevice.name!.isEmpty) {
            newDevice.name =
                oldDevice.name; //受信データにデバイス名がなければ、oldDeviceのデバイス名を使用
          }

          if (uiDevice != null) {
            final oldFeed = oldDevice.feed;
            final newFeed = newDevice.feed;
            final uiFeed = uiDevice.feed;

            final oldBattery = oldDevice.battery;
            final newBattery = newDevice.battery;
            final uiBattery = uiDevice.battery;

            debugPrint('oldFeed=$oldFeed, newFeed=$newFeed, uiFeed=$uiFeed');
            debugPrint(
              'oldFeed=$oldBattery, newFeed=$newBattery, uiFeed=$uiBattery',
            );

            // 既存あり: 条件判定
            final bool feedMatch = (oldFeed == newFeed) && (uiFeed != newFeed);
            final bool batteryClose =
                ((oldBattery - newBattery).abs() <= 8) &&
                (uiBattery != newBattery);

            //条件に一致する場合
            if (feedMatch || batteryClose) {
              uiDevice.updateFrom(newDevice, updateBattery: true);
              uiDevice.resumeReceiving();
              notifyListeners();
            } else {
              //日付のみ更新
              uiDevice.updateDate = newDevice.updateDate;
              uiDevice.resumeReceiving();
              notifyListeners();
            }
            _data[address] = uiDevice;

            //新規デバイスの場合そのままUI表示
          } else {
            _data[address] = newDevice;
            notifyListeners();
          }
        }
        // DB保存用キューに入れる等
        _enqueueSave(newDevice);
      },
      onError: (e) {
        debugPrint('scan listen error: $e');
      },
    );
  }

  void stopScan() {
    _bluetoothService.stopScan();
    _deviceSub?.cancel();
    _deviceSub = null;
    _isScanning = false;

    //スキャン停止時は全デバイスの受信を強制停止
    for (final d in _data.values) {
      d.forceStopReceiving();
    }

    notifyListeners();
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  //受信したデータをキューにためておく
  void _enqueueSave(Data d) {
    // reception 用マップを作る（Data に toMapForReception を実装しておく）
    final map = d.toMapForReception();
    debugPrint(
      '[enqueue] address=${d.address} feed=${d.feed} bat=${d.battery}',
    );
    // キューに追加
    _saveQueue.add(map);
    debugPrint('[enqueue] queueSize=${_saveQueue.length}');
    // もしキューが非常に大きくなったら即フラッシュする閾値を設けてもよい
    if (_saveQueue.length >= 100) {
      _flushSaveQueue();
    }
  }

  //溜まったデータをまとめてDBに保存
  Future<void> _flushSaveQueue() async {
    final dbHelper = DatabaseHelper.instance;
    final redao = ReceptionDao(dbHelper);
    if (_isFlushing) return;
    if (_saveQueue.isEmpty) {
      debugPrint('[flush] nothing to flush');
      return;
    }
    _isFlushing = true;

    final items = List<Map<String, dynamic>>.from(_saveQueue);
    _saveQueue.clear();

    try {
      await redao.batchInsertReceptions(items);
      debugPrint('[flush] batchInsertReceptions OK');
      //await loadAll(notify: false); // ←oldDevice更新（UIは更新しない）
      await loadAll();
    } catch (e, st) {
      debugPrint('flushSaveQueue failed: $e\n$st');
      // 失敗したら再度キューに戻すかログ保存する方が良い
      _saveQueue.insertAll(0, items); // 前方に戻して再トライの機会を作る
    } finally {
      _isFlushing = false;
    }
  }

  @override
  void dispose() {
    stopScan();
    // _bluetoothService.dispose();
    _flushSaveQueue();
    super.dispose();
  }
}
