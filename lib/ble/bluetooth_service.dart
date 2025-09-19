import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:test3/models/data.dart';

class BluetoothService {
  final FlutterReactiveBle _ble = FlutterReactiveBle(); //BLE接続のためのコントローラを作成
  StreamSubscription<DiscoveredDevice>? _scanSubscription; //スキャン購読を管理する変数の宣言
  final StreamController<Data> _deviceController = //BleDevice型のデータを流すストリームを作る
      StreamController.broadcast(); //複数の購読者から同時に購読できるストリームを作る

  Stream<Data> get deviceStream =>
      _deviceController.stream; //他のクラスからdleDeviceを受け取れるようにする

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
  }

  void dispose() {
    stopScan();
    _deviceController.close();
  }
}
