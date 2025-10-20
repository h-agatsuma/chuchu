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
  // int _seqCounter = 0;
  // final List<Data> _incomingQueue = [];
  //
  // bool _processingQueue = false; //付け足した

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

//homepageのdbUIMapの値を使えるようにする。
  void updateDbUI(Map<String, Data> newDbUIMap) {
    _dbUIMap = newDbUIMap;
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
//
// // 受信ハンドラ内で newDevice を作った直後に seq を振る代わりに enqueue する
//   void _onDeviceRawReceived(Data newDevice) {
//     newDevice.seq = ++_seqCounter;
//     _enqueueIncoming(newDevice);
//   }
//
//   void _enqueueIncoming(Data d) {
//     _incomingQueue.add(d);
//     if (!_processingQueue) {
//       _processIncomingQueue();
//     }
//   }
//
// // 逐次処理ループ：FIFOで1件ずつ適用する
//   Future<void> _processIncomingQueue() async {
//     _processingQueue = true;
//     bool hasChanged = false; // 変更フラグ
//
//     try {
//       while (_incomingQueue.isNotEmpty) {
//         final newDevice = _incomingQueue.removeAt(0);
//         final address = newDevice.address;
//         final oldDevice = _data[address];
//
//         if (oldDevice == null) {
//           // 新規は構造変化 → 追加して親に通知
//           _data[address] = newDevice;
//           notifyListeners();
//         } else {
//           // 既存インスタンスを差し替えずに更新（UI 用 target を使う）
//           final target = _dbUIMap[address] ?? oldDevice;
//
//           final oldFeed = oldDevice.feed;
//           final newFeed = newDevice.feed;
//           final uiFeed = _dbUIMap[address]?.feed;
//
//           final oldBattery = oldDevice.battery;
//           final newBattery = newDevice.battery;
//           final uiBattery = _dbUIMap[address]?.battery;
//
//           debugPrint('oldFeed=$oldFeed, newFeed=$newFeed, uiFeed=$uiFeed');
//           debugPrint('oldBattery=$oldBattery, newBattery=$newBattery, uiBattery=$uiBattery');
//
//           final bool feedMatch = (oldFeed == newFeed) && (uiFeed != newFeed);
//           final bool batteryClose =
//               ((oldBattery - newBattery).abs() <= 8) &&
//                   (uiBattery != newBattery);
//
//           if (feedMatch || batteryClose) {
//             // if (target != null) {
//             //   final changed = target.updateFrom(newDevice); // Data が notify する
//             //   //if (changed) notifyListeners();
//             //   if (changed) hasChanged = true;
//             // }
//             if (target.feed != newFeed || target.battery != newBattery) {
//               final changed = target.updateFrom(newDevice);
//               if (changed) hasChanged = true;
//             }
//           } else {
//             if (target != null) {
//               final changed = target.updateDateOnly(
//                   newDevice.updateDate,
//                   newSeq: newDevice.seq
//               ); // Data が notify する
//               if (changed) hasChanged = true;
//               //if (changed) notifyListeners();
//             } else {
//
//               debugPrint(
//                 '[DeviceManager] Not showing update for $address (filter)',
//               );
//             }
//             _data[address] = newDevice;
//           }
//         }
//
//         // DB保存キューは従来どおり
//         _enqueueSave(newDevice);
//
//       }
//     } finally {
//       _processingQueue = false;
//       if (hasChanged)  notifyListeners();
//
//     }
//   }

  Future<void> loadAll({bool notify = true}) async {
    final list = await repo.getAllData(); // List<Map<String, dynamic>>
//既存の Map _data を空にして、キーを d.address、値を item にした MapEntry に、DB から取得したデータの要素を変換して一括で追加する
_data
..clear()
..addEntries(
list.map((Data item) => MapEntry(item.address, item)),
); //DB から取得したリストが Map に入る
    notifyListeners();
//     for (final item in list) {
//       final existing = _data[item.address];
//       final uiTarget = _dbUIMap[item.address] ?? existing;
//       if (existing != null) {
// // UI を壊さないように静かに上書き（notify を false）
//         existing.updateFrom(item);
//       } else {
// // 新規はそのまま追加（必要なら notify 制御）
//         _data[item.address] = item;
//       }
//     }
//     if (notify) notifyListeners();
  }

//UI 側で呼ぶ。（ボタンを押したときなど）
  void startScan({
    bool simulated = false,
    List<Map<String, dynamic>>? simulatedList,
  }) {
    print('[DeviceManager] startScan called simulated=$simulated');
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
        final oldDevice = _data[address];


        if (oldDevice != null &&
            (newDevice.name == null || newDevice.name!.isEmpty)) {
          newDevice.name = oldDevice.name;
        }
        if (oldDevice == null) {
          // 新規：常に追加して UI 表示
          _data[address] = newDevice;

          notifyListeners();
          //shouldNotifyUI = true;
        } else {

          final oldFeed = oldDevice.feed;
          final newFeed = newDevice.feed;
          final uiFeed = _dbUIMap[address]?.feed;

          final oldBattery = oldDevice.battery;
          final newBattery = newDevice.battery;
          final uiBattery = _dbUIMap[address]?.battery;


          // // 既存あり: 条件判定 _dbUI:画面に表示されているデータ
          final bool feedMatch = (oldFeed == newFeed)&&(uiFeed != newFeed);
          final bool batteryClose = ((oldBattery - newBattery).abs() <= 8)&&(uiBattery!=newBattery);


          debugPrint('oldFeed=$oldFeed, newFeed=$newFeed, uiFeed=$uiFeed');
          debugPrint('oldFeed=$oldBattery, newFeed=$newBattery, uiFeed=$uiBattery');


          if (feedMatch || batteryClose) {
            final target = _dbUIMap[address];
            if (target != null) {
              target.updateFrom(newDevice);
            }
          } else {
            // どちらも満たさない: UI は更新しない（でも内部的に値を置き換えたい場合は別途扱う）
            debugPrint('[DeviceManager] Not showing update for $address (filter)');
          }
          _data[address] = newDevice;
          debugPrint('→ _data[address] に newDevice を保存: feed=${newDevice.feed},battery=${newDevice.battery}');
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
    _flushTimer?.cancel();
    _flushTimer = null;

// //スキャン停止時は全デバイスの受信を強制停止
//     for (final d in _data.values) {
//       d.forceStopReceiving();
//     }
    notifyListeners();
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
      await loadAll(notify: false); // ←oldDevice更新（UIは更新しない）
      //notifyListeners();
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