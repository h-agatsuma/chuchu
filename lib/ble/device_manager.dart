import 'package:flutter/material.dart';
import 'bluetooth_service.dart';
import 'dart:async';
import 'package:test3/db/app_repository.dart';
import 'package:test3/db/reception_dao.dart';
import 'package:test3/models/data.dart';
import 'package:test3/db/database_helper1.dart';
import 'bluetooth_service.dart';
import 'dart:typed_data'; //Uint8List に必要
import 'dart:math'; //min に必要

class Device {
  final String id;
  final List<int> manufacturerData;
  bool isReceiving; //データ受信中かどうか。（アイコン用）デフォルトは false

  Device(
      {required this.id, required this.manufacturerData, this.isReceiving = false});
}

//生データを渡す
class DeviceManager extends ChangeNotifier {
  //BluetoothService クラスのインスタンス生成
  //final BluetoothService _bluetoothService = BluetoothService();

  // 指定のアドレスを持つデータがあるかどうかを返す
  bool contains(String address) {
    //return dataList.any((d) => d.address == address);
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

  bool _isScanning = false; //探索中かどうか


  // 新保存キュー（reception 用の Map）
  final List<Map<String, dynamic>> _saveQueue = [];
  Timer? _flushTimer;
  bool _isFlushing = false;

  DeviceManager(
      {required BluetoothService bluetoothService, required this.repo})
      : _bluetoothService = bluetoothService;

  List<Data> get data => _data.values.toList(); // UI 用に List を返す

  bool get isScanning => _isScanning; //他のクラスから「isScanning」がつかえるようにする

  Future<void> loadAll() async {
    final list = await repo.getAllData(); // List<Map<String, dynamic>>
    //既存の Map _data を空にして、キーを d.address、値を item にした MapEntry に、DB から取得したデータの要素を変換して一括で追加する
    _data
      ..clear()
      ..addEntries(list.map((Data item) =>
          MapEntry(item.address, item))); //DB から取得したリストが Map に入る
    notifyListeners();
  }

  //UI 側で呼ぶ。（ボタンを押したときなど）
  void startScan({bool simulated = false, List<Map<String,dynamic>>? simulatedList}) {
    print('[DeviceManager] startScan called simulated=$simulated');
    if (_deviceSub != null){
      print('[DeviceManager] already subscribed, returning');
      return;
    }
    if (simulated && simulatedList != null) {
      print('[DeviceManager] calling startSimulatedScan');
      _bluetoothService.startSimulatedScan(simulatedList);
    } else {
      _bluetoothService.startScan();  //BluetoothService クラスの startScan メソッドを呼び出す
    }

    _isScanning = true; //探索中にする
    notifyListeners(); //データが変わったことを知らせる

    // 定期フラッシュタイマー（5秒ごとにまとめて保存する）
    _flushTimer ??=
        Timer.periodic(Duration(seconds: 5), (_) => _flushSaveQueue());


    _deviceSub = _bluetoothService.deviceStream.listen((device) {

      final address = device.address;
      final raw = device.manufacturerData; // List<int> or Uint8List


      // //raw(manufacturerData) が null のとき、mData も null
      // //そうでなければ、3 バイトを取り出して Uint8List に変換し mData に格納
      // //min を使えば、raw.length >= 3 よりも簡単に書ける
      // final Uint8List? mData = (raw == null)
      //     ? null
      //     : Uint8List.fromList(raw.sublist(0, min(raw.length, 3)));


      Data newDevice;
// スキャン受信ハンドラ内の if 部分
      if (raw != null && raw.length >= 3) {
        // 先頭3バイトだけ使う
        final List<int> mData = raw.sublist(0, 3);

        // feed: 1バイト目
        final int feed = mData[0] & 0xFF;

        // batteryRaw: 2バイト目（上位）と3バイト目（下位）を結合（ビッグエンディアン想定）
        final int battery = ((mData[1] & 0xFF) << 8) | (mData[2] & 0xFF);

        // // 必要ならパーセントへ変換（なければ batteryRaw をそのまま使ってもOK）
        // final int batteryPercent = computeBatteryPercent(batteryRaw);

        // Data の生成（Data クラスが次のようなコンストラクタを持つことを前提）
        newDevice = Data(
          address: address,
          name: device.name ?? '',
          updateDate: DateTime.now(),
          feed: feed,
          battery: battery,
          manufacturerData: Uint8List.fromList(mData), // 任意で生データも保持
        );
      }else {
        // simulated データなど、既に feed/battery がある場合はこちらを使う
        newDevice = Data(
          address: device.address,
          name: device.name ?? '',
          updateDate: DateTime.now(),
          feed: device.feed,
          battery: device.battery,
          manufacturerData: device.manufacturerData != null ? Uint8List.fromList(device.manufacturerData!) : null,
        );
        debugPrint('[DeviceManager] using device.feed/device.battery feed=${newDevice.feed} bat=${newDevice.battery}');
      }

        // ここで既存比較やキュー追加などの処理を続ける
        final oldDevice = _data[address];

      if (oldDevice != null && (newDevice.name == null || newDevice.name!.isEmpty)) {
        newDevice.name = oldDevice.name;
      }
      if (oldDevice == null) {
        _data[address] = newDevice;
        notifyListeners(); // Map 構造が変わった時だけ通知（追加時）
      } else {
        final changed = oldDevice.updateFrom(newDevice);
        if (changed) {debugPrint('[DeviceManager] Data updated: ${oldDevice.address}');}
        //oldDevice.updateFrom(newDevice);
      }

      // 差がないか8以内ならUI表示
      // final bool shouldShow = true;
      //   // 「差が無かったら確定」の条件再確認！！
      // final bool shouldShow = oldDevice == null ||
      //       (oldDevice.feed == newDevice.feed) ||
      //       ((oldDevice.battery - newDevice.battery).abs() <= 8);
      //
      //   if (shouldShow) {
      //     _data[address] = newDevice;
      //     notifyListeners();
      //     debugPrint('[DeviceManager] updated UI for ${newDevice.address}');
      //   } else {
      //     debugPrint('[DeviceManager] not updating UI for ${newDevice.address}');
      //
      //   }

        // DB保存用キューに入れる等
        _enqueueSave(newDevice);

    }
      ,onError:(e) {
          debugPrint('scan listen error: $e');
        });}
      // if (oldDevice == null ||
      //     !listEqualsFeed(oldDevice.feed, data)) {
      //   _data[address] = newDevice;
      //   notifyListeners();
      // }
      //
      // if (oldDevice == null ||
      //     !listEqualsBattery(oldDevice.manufacturerData, data, 8)) {
      //   _data[address] = newDevice;
      //   notifyListeners();
      // }


      //   //2 秒待って受信が止まったら、isReceiving=false にする
      //   Future.delayed(Duration(seconds: 2), () {
      //     //2 秒後に処理実施
      //     final updatedDevice = _data[address];
      //     if (updatedDevice != null) {
      //       // updatedDevice.isReceiving = false;
      //       notifyListeners();
      //     }
      //   });
      // });
        void stopScan()
    {
      _bluetoothService.stopScan();
      _deviceSub?.cancel();
      _deviceSub = null;
      _isScanning = false;
      _flushTimer?.cancel();
      _flushTimer = null;
      notifyListeners();
    }

    //受信したデータをキューにためておく
    void _enqueueSave(Data d) {
      // reception 用マップを作る（Data に toMapForReception を実装しておく）
      final map = d.toMapForReception();
      debugPrint('[enqueue] address=${d.address} feed=${d.feed} bat=${d.battery}');
      // シンプル実装：キューに追加（重複を避けたいなら address で上書きするロジックに変える）
      _saveQueue.add(map);
      debugPrint('[enqueue] queueSize=${_saveQueue.length}');
      // もしキューが非常に大きくなったら即フラッシュする閾値を設けてもよい
      if (_saveQueue.length >= 100) {
        _flushSaveQueue();
      }
    }

    //溜まったデータをまとめてDBに保存
    Future<void> _flushSaveQueue() async {
    final dbHelper=DatabaseHelper.instance;
    final redao=ReceptionDao(dbHelper);
      if (_isFlushing) return;
      if (_saveQueue.isEmpty){ debugPrint('[flush] nothing to flush');
        return;}
      _isFlushing = true;


      final items = List<Map<String, dynamic>>.from(_saveQueue);
      _saveQueue.clear();

      try {
        await redao.batchUpsertReceptions(items);
        debugPrint('[flush] batchUpsertReceptions OK');
      } catch (e, st) {
        debugPrint('flushSaveQueue failed: $e\n$st');
        // 失敗したら再度キューに戻すかログ保存する方が良い
        _saveQueue.insertAll(0, items); // 前方に戻して再トライの機会を作る
      } finally {
        _isFlushing = false;
      }
    }

    // //2 つの List<int>が同じかどうか判断。完全一致の場合。餌比較
    // bool listEqualsFeed(List<int> a, List<int> b) {
    //   if (a.length != b.length) return false; //長さが違えば内容も違うので false
    //   for (int i = 0; i < a.length; i++) {
    //     if (a[i] != b[i]) return false; //内容が違えば false
    //   }
    //   return true; //内容が一緒なら true
    // }
    //
    // //2 つの List<int>の差が 8 以内かどうか。バッテリーのとき比較
    // bool listEqualsBattery(List<int> a, List<int> b, int battery) {
    //   if (a.length != b.length) return false;
    //
    //   for (int i = 0; i < a.length; i++) {
    //     if ((a[i] - b[i]).abs() > battery) {
    //       return false;
    //     }
    //   }
    //   return true;
    // }

    @override
    void dispose() {
      stopScan();
      // _bluetoothService.dispose();
      _flushSaveQueue();
      super.dispose();
    }
  }
