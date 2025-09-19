import 'package:flutter/material.dart'; //絶対必要
import 'db/database_helper1.dart'; //データベースで使った
import 'package:intl/intl.dart'; //時刻で使った

import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test3/models/data.dart';
import 'package:test3/db/app_repository.dart';

import 'DetailPage.dart';
import 'homepage.dart';

import 'ble/device_manager.dart';
import 'ble/bluetooth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //DatabaseHelper クラスのインスタンス取得
  final dbHelper = DatabaseHelper.instance;
  final repo = AppRepository(dbHelper); // Repository（JOIN 等の複雑処理）
  final btService = BluetoothService();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: dbHelper),
        Provider<AppRepository>.value(value: repo),
        Provider<BluetoothService>.value(value: btService),
        ChangeNotifierProvider<DeviceManager>(
          create: (_) => DeviceManager(repo: repo, bluetoothService: btService)//..loadAll(),
          // dispose: (_, m) => m.dispose(), // DeviceManager が dispose を持つなら明示的に
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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),

      home: MyHomePage(),
    );
  }
}
