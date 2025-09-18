// lib/db/initial_data.dart
import 'package:intl/intl.dart';

//
// final now = DateTime.now();
// final datetime = DateFormat('yyyy/MM/dd HH:mm:ss').format(now);

final List<Map<String, dynamic>> initialDeviceData = [
  // {'address': 'AA:BB:CC:11:22:33'},
  // {'address': 'DD:EE:FF:44:55:66'},
  // {'address': 'DD:EE:FF:44:55:77'},
  // {'address': 'DD:EE:FF:44:55:88'},
  // {'address': 'DD:EE:FF:44:55:99'},
  // {'address': 'DD:EE:FF:44:55:00'},
  // {'address': 'DD:EE:FF:44:55:55'},
  // {'address': 'DD:EE:FF:44:55:44'},
  // {'address': 'DD:EE:FF:44:55:11'},
  // 必要なら追加
  {'address': 'F2:DA:8F:A7:C0:52:DB:33', 'name': 'chuchu01'},
  {'address': '65:B3:DE:F2:B4:CA:CE:36', 'name': 'chuchu02'},
  {'address': '05:24:7D:8A:65:C7:70:6F', 'name': ''},
  {'address': '6C:C0:09:59:6D:AE:86:7C', 'name': 'chuchu04'},
  {'address': '52:75:7A:34:AD:45:1C:A7', 'name': ''},
  {'address': '2A:C8:2C:A7:2E:AB:8A:20', 'name': 'chuchu06'},
  {'address': '7E:8C:10:D0:C9:65:83:88', 'name': 'chuchu07'},
  {'address': '5B:72:77:5F:A8:83:F0:E3', 'name': ''},
  {'address': '2E:44:64:70:9F:20:80:0E', 'name': 'chuchu09'},
  {'address': '16:20:AB:39:72:82:16:BE', 'name': 'chuchu10'},
  {'address': '0D:34:D0:D4:AA:52:A5:9C', 'name': ''},
  {'address': '3F:7C:51:64:AB:D5:DF:20', 'name': 'chuchu12'},
  {'address': '35:D6:47:AB:93:4E:4C:57', 'name': ''},
  {'address': 'AA:8B:C4:E3:C0:DA:67:1D', 'name': 'chuchu15'},
  {'address': 'E3:C5:77:6E:E3:E0:7E:38', 'name': ''},
  {'address': '14:09:8F:A1:9D:0B:76:FC', 'name': 'chuchu17'},
];

final List<Map<String, dynamic>> initialReceptionData = [
  // {'address': 'AA:BB:CC:11:22:33', 'feed': '0', 'battery': '4B0', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:66', 'feed': '2', 'battery': '4A8', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:77', 'feed': '0', 'battery': '4A5', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:88', 'feed': '2', 'battery': '350', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:99', 'feed': '0', 'battery': '4A4', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:00', 'feed': '2', 'battery': '389', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:55', 'feed': '0', 'battery': '410', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:44', 'feed': '0', 'battery': '389', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  // {'address': 'DD:EE:FF:44:55:11', 'feed': '2', 'battery': '399', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},

  // 必要なら追加
  {'address': 'F2:DA:8F:A7:C0:52:DB:33', 'feed': '0', 'battery': '4B0', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '65:B3:DE:F2:B4:CA:CE:36', 'feed': '2', 'battery': '4A8', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '05:24:7D:8A:65:C7:70:6F', 'feed': '0', 'battery': '4A5', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '6C:C0:09:59:6D:AE:86:7C', 'feed': '2', 'battery': '350', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '52:75:7A:34:AD:45:1C:A7', 'feed': '0', 'battery': '4A4', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '2A:C8:2C:A7:2E:AB:8A:20', 'feed': '2', 'battery': '389', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '7E:8C:10:D0:C9:65:83:88', 'feed': '0', 'battery': '410', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '5B:72:77:5F:A8:83:F0:E3', 'feed': '0', 'battery': '389', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '2E:44:64:70:9F:20:80:0E', 'feed': '2', 'battery': '4B0', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '16:20:AB:39:72:82:16:BE', 'feed': '2', 'battery': '4A8', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '0D:34:D0:D4:AA:52:A5:9C', 'feed': '2', 'battery': '4A5', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '3F:7C:51:64:AB:D5:DF:20', 'feed': '0', 'battery': '350', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '35:D6:47:AB:93:4E:4C:57', 'feed': '2', 'battery': '4A4', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': 'AA:8B:C4:E3:C0:DA:67:1D', 'feed': '0', 'battery': '389', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': 'E3:C5:77:6E:E3:E0:7E:38', 'feed': '0', 'battery': '410', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
  {'address': '14:09:8F:A1:9D:0B:76:FC', 'feed': '2', 'battery': '389', 'updateDate': DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now())},
];
