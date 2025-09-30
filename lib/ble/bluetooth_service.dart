import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:test3/models/data.dart';
import 'package:flutter/foundation.dart';

class BluetoothService {
  final FlutterReactiveBle _ble = FlutterReactiveBle(); //BLE接続のためのコントローラを作成
  StreamSubscription<DiscoveredDevice>? _scanSubscription; //スキャン購読を管理する変数の宣言
  final StreamController<Data> _deviceController = //BleDevice型のデータを流すストリームを作る
      StreamController.broadcast(); //複数の購読者から同時に購読できるストリームを作る

  Stream<Data> get deviceStream =>
      _deviceController.stream; //他のクラスからdleDeviceを受け取れるようにする


  //シミュレーション用
  Timer? _simTimer;
  int _simIndex = 0;

  /// initialList: List<Map<String, dynamic>> の形式（your initial_data.bluetoothData）
  /// interval: 2秒等
  void startSimulatedScan(List<Map<String, dynamic>> initialList, {Duration interval = const Duration(seconds: 2)}) {
    stopScan(); // 実機スキャンが起動していれば止める
    _simTimer?.cancel();
    _simIndex = 0;



    _simTimer = Timer.periodic(interval, (_) {

      if (initialList.isEmpty) return;

      final map = initialList[_simIndex % initialList.length];

      debugPrint('[BLE_SIM] emit index=$_simIndex address=${map['address']} feed=${map['feed']} battery=${map['battery']}');

      _simIndex++;

      // Map -> Data に変換（安全にパース）
      final dataObj = _mapToData(map);
      if (dataObj != null) {
        _deviceController.add(dataObj);
      }
    });
  }

  // 汎用: Map から Data を作る（initial_data の形式に合わせた安全実装）
  Data? _mapToData(Map<String, dynamic> m) {
    try {
      final address = m['address'] as String;
      final name = m['name'] as String? ?? '';
      final updateDateStr = m['updateDate'] as String? ?? '';
      DateTime updateDate;
      if (updateDateStr.isNotEmpty) {
        // initial_data は DateFormat('yyyy/MM/dd HH:mm:ss') を使っている前提
        updateDate = DateFormat('yyyy/MM/dd HH:mm:ss').parse(updateDateStr);
      } else {
        updateDate = DateTime.now();
      }

      // feed が "00"/"01" のような文字列なら 10 進で parse。hex の可能性があるなら radix:16 に変える
      final dynamic feedRaw = m['feed'];
      final int feed = feedRaw is int
          ? feedRaw
          : int.tryParse('$feedRaw') ?? int.tryParse('$feedRaw', radix: 16) ?? 0;

      final dynamic batRaw = m['battery'];
      final int battery = batRaw is int ? batRaw : int.tryParse('$batRaw') ?? 0;

      return Data(
        address: address,
        name: name,
        updateDate: updateDate,
        feed: feed,
        battery: battery,
        manufacturerData: null,
      );
    } catch (e) {
      // 生成に失敗したらログを出して null を返す
      print('mapToData parse error: $e');
      return null;
    }
  }

//シミュレーション用ここまで

  // BluetoothService に依頼して購読を開始
  void startScan() {
    //Bluetooth APIでデバイスを探し、ストリームから一件ずつ受け取る
    _scanSubscription = _ble
        .scanForDevices(withServices: [])
        .listen(
          (device) {
            final mData = device.manufacturerData;

            if (mData != null && mData.isNotEmpty && mData.length >= 3) {
              final manuData = mData.sublist(0, 3); //配列0～3までを新たなリストにする
              final dataObj = Data.fromBluetooth(
                address: device.id,
                name: device.name ?? '',
                manufacturerData: manuData,
              );
              _deviceController.add(dataObj); //データをストリームに追加
            }
          },
          onError: (e) {
            print('スキャンエラー: $e');
          },
        );
  }

  void stopScan() {
    _scanSubscription?.cancel(); //スキャンの購読を中止
    _scanSubscription = null;
    // シミュレータ用タイマーも止める
    _simTimer?.cancel();
    _simTimer = null;

  }

  void dispose() {
    stopScan();
    _deviceController.close();
  }
}
