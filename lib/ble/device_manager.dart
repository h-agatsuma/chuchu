import 'package:flutter/material.dart';
import 'bluetooth_service.dart';
import 'dart:async';
import 'package:test3/db/app_repository.dart';
import 'package:test3/models/data.dart';
import 'bluetooth_service.dart';
import 'dart:typed_data'; //Uint8Listに必要
import 'dart:math'; //minに必要

class Device {
  final String id;
  final List<int> manufacturerData;
  bool isReceiving; //データ受信中かどうか。（アイコン用）デフォルトはfalse

  Device({
    required this.id,
    required this.manufacturerData,
    this.isReceiving = false,
  });
}

//生データを渡す
class DeviceManager extends ChangeNotifier {
  //BluetoothServiceクラスのインスタンス生成
  //final BluetoothService _bluetoothService = BluetoothService();

  final BluetoothService _bluetoothService;
  final AppRepository repo;

  final Map<String, Data> _data = {}; // ← Map に変更
  //List<Data> _data = [];
  StreamSubscription<Data>? _deviceSub; //データを流すストリームに対する購読

  bool _isScanning = false; //探索中かどうか

  DeviceManager({
    required BluetoothService bluetoothService,
    required this.repo,
  }) : _bluetoothService = bluetoothService;

  List<Data> get data => _data.values.toList(); // UI 用に List を返す

  bool get isScanning => _isScanning; //他のクラスから「isScanning」がつかえるようにする

  Future<void> loadAll() async {
    final list = await repo.getAllData(); // DBから取得したデータList＜Data＞がlistに入る。

    //既存の Map _data を空にして、キーを d.address、値を item にした MapEntry に、DBから取得したデータの要素を変換して一括で追加する
    _data..clear()..addEntries(list.map((Data item) => MapEntry(item.address, item))); //DBから取得したリストがMapに入る
    notifyListeners();
  }

  //ここから。上の StreamSubscription<Data>? _btSub;に置き換えたいけどエラーでる。manastudioにコードある。
  // StreamSubscription<BleDevice>? _deviceSubscription;

  //UI側で呼ぶ。（ボタンを押したときなど）
  void startScan() {
    _bluetoothService.startScan(); //BluetoothServiceクラスのstartScanメソッドを呼び出す
    _isScanning = true; //探索中にする
    notifyListeners(); //データが変わったことを知らせる

    _deviceSub = _bluetoothService.deviceStream.listen((device) {
      final address = device.address;
      final raw = device.manufacturerData; // List<int> or Uint8List?

      if (raw != null && raw.length >= 3) {
        final  mData = raw.sublist(0, 3);

        // //raw(manufacturerData)がnullのとき、mDataもnull
        // //そうでなければ、3バイトを取り出してUint8Listに変換しmDataに格納
        // //minを使えば、raw.length >= 3よりも簡単に書ける
        // final Uint8List? mData = (raw == null)
        //     ? null
        //     : Uint8List.fromList(raw.sublist(0, min(raw.length, 3)));

        //受信したデバイスの情報を一旦newDeviceに格納

        final newDevice = Data.fromBluetooth(
          address: address,
          name: device.name ?? '',
          manufacturerData: mData ?? <int>[],
          batteryBigEndian: true,
          // isReceiving: true,
        );
        //_data[address] = newDevice;　確定したときに使うコード

        //_data[address] に保存してあるそのアドレスの既存の Data インスタンス（または null）。比較のために定義
        final oldDevice = _data[address];

        //そのデバイスの既存の情報がない場合と、既存のfeed,batteryと取得した新しいデータが異なる場合
        //新しいデータを_devicesに格納

        final bool shouldUpdate = oldDevice == null ||
            (oldDevice.feed != newDevice.feed) ||
            ((oldDevice.battery - newDevice.battery).abs() < 8);



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
      }

      //2秒待って受信が止まったら、isReceiving=falseにする
      Future.delayed(Duration(seconds: 2), () {
        //２秒後に処理実施
        final updatedDevice = _data[address];
        if (updatedDevice != null) {
          updatedDevice.isReceiving = false;
          notifyListeners();
        }
      });
    });
  }

  void stopScan() {
    _bluetoothService.stopScan();
    _deviceSub?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  //2つのList<int>が同じかどうか判断。完全一致の場合。餌比較
  bool listEqualsFeed(List<int> a, List<int> b) {
    if (a.length != b.length) return false; //長さが違えば内容も違うのでfalse
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false; //内容が違えばfalse
    }
    return true; //内容が一緒ならtrue
  }

  //２つのList<int>の差が8以内かどうか。バッテリーのとき比較
  bool listEqualsBattery(List<int> a, List<int> b, int battery) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > battery) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    stopScan();
    _bluetoothService.dispose();
    super.dispose();
  }
}
