import 'package:flutter/material.dart';
import 'DetailPage.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChuChuCheckApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 仮のデータ（あとで DB から取得する想定）
    final List<Map<String, String>> data = [
      {
        'macAddress':'F3:46:B4:FF:23:34:84:4A',
        'name': 'chuchu1',
        'status': 'left',
        'battery': '100%',
        'update': '25/09/01\n12:00:23',
      },
      {
        'macAddress':'F3:46:B4:FF:23:34:84:4A',
        'name': "",
        'status': 'Noleft',
        'battery': '5%',
        'update': '25/09/31\n12:00:12',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChuChuCheckApp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          TextButton(
            onPressed: () {
              debugPrint("SCAN ボタン押下");
            },
            child: const Text(
              "SCAN",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.yellow
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ヘッダー行
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: const [
                SizedBox(width: 40, child: Icon(Icons.bolt)),
                Expanded(flex: 2, child: Text('Address/Name',textAlign: TextAlign.center,)),
                Expanded(child: Text('Bait\nStatus',textAlign: TextAlign.center,)),
                Expanded(child: Text('Battery\nLv',textAlign: TextAlign.center,)),
                Expanded(flex: 2, child: Text('Last\nUpdate',textAlign: TextAlign.center,)),
              ],
            ),
          ),
          // データ行
          ...data.map((item) {
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(
                      name: item['name'],
                      macAddress: item['macAddress']!,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 40, child:Icon(Icons.bolt)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        (item['name'] != null && item['name']!.isNotEmpty)
                            ? item['name']!
                            : item['macAddress']!,
                        overflow: TextOverflow.ellipsis,),
                    ),
                    Expanded(
                      child: Center(child: Text(item['status']!)),
                    ),
                    Expanded(
                      child: Center(child: Text(item['battery']!)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: Text(item['update']!)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.green, // 背景色
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end, // 中央寄せ
          children: const [
            SizedBox(width: 8), // アイコンと文字の間隔
            Text(
              "Powered by Signpost Co., Ltd.",
              style: TextStyle(fontSize: 14),
            ),
            Icon(Icons.image, size: 20)
          ],
        ),
      ),
    );
  }
}
