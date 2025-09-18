// lib/db/initial_data.dart
import 'package:intl/intl.dart';
//
// final now = DateTime.now();
// final datetime = DateFormat('yyyy/MM/dd HH:mm:ss').format(now);

final List<Map<String, dynamic>> initialDeviceData = [
  {
    'address': 'AA:BB:CC:11:22:33',

  },
  {
    'address': 'DD:EE:FF:44:55:66',

  },
  {
    'address': 'DD:EE:FF:44:55:77',

  },
  {
    'address': 'DD:EE:FF:44:55:88',

  },
  {
    'address': 'DD:EE:FF:44:55:99',

  },
  {
    'address': 'DD:EE:FF:44:55:00',

  },
  {
    'address': 'DD:EE:FF:44:55:55',

  },
  {
    'address': 'DD:EE:FF:44:55:44',

  },
  {
    'address': 'DD:EE:FF:44:55:11',

  }
  // 必要なら追加
];


final List<Map<String, dynamic>> initialReceptionData = [
  {

    'address': 'AA:BB:CC:11:22:33',
    'feed': '0',
    'battery': '4B0',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:66',
    'feed': '2',
    'battery': '4A8',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:77',
    'feed': '0',
    'battery': '4A5',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:88',
    'feed': '2',
    'battery': '350',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:99',
    'feed': '0',
    'battery': '4A4',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:00',
    'feed': '2',
    'battery': '389',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:55',
    'feed': '0',
    'battery': '410',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:44',
    'feed': '0',
    'battery': '389',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  },
  {

    'address': 'DD:EE:FF:44:55:11',
    'feed': '2',
    'battery': '399',
    'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()),
  }

  // 必要なら追加
];
