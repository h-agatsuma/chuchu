import 'package:flutter/material.dart';
import 'package:test3/db/database_helper1.dart';
import 'package:intl/intl.dart'; //時刻で使った

class DetailPage extends StatefulWidget {
  final String macAddress;
  final String? name;

  DetailPage({super.key, required this.macAddress, this.name});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final dbHelper = DatabaseHelper.instance;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    //テキストフィールドの初期表示
    nameController = TextEditingController(
      text: (widget.name != null && widget.name!.isNotEmpty)
          ? widget.name!
          : "",
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChuChuCheckApp',
          style: TextStyle(color: Colors.white, fontSize: 32),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 左揃え
              children: [
                // --- MAC Address ---
                const Text("macAddress:", style: TextStyle(fontSize: 20)),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4, bottom: 100),
                  // ← 値だけインデント
                  child: Text(
                    widget.macAddress,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                // --- Name ---
                const Text("name:", style: TextStyle(fontSize: 20)),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4, bottom: 100),
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 30),
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(), // 枠線を付ける
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _insOrReplace, //インサート・更新メソッド
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(150, 80),
                          backgroundColor: const Color(0xFF32CD32),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        child: const Text('Subscribe'),
                      ),
                      const SizedBox(width: 20), // ボタン間の余白
                      ElevatedButton(
                        onPressed: _delete, //デリートメソッド
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(150, 80),
                          backgroundColor: const Color(0xFF999966),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        child: const Text('Unsubscribe'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            Icon(Icons.image, size: 20),
          ],
        ),
      ),
    );
  }

  // subscribeボタンクリック
  void _insOrReplace() async {
    DateTime now = DateTime.now(); //現在の時刻をDateTime型で取得
    String datetime = DateFormat(
      'yyyy/MM/dd HH:mm:ss',
    ).format(now);
    final nameText = nameController.text; //テキストフィールドに入力された名前を取得

    Map<String, dynamic> rowdev = {
      DatabaseHelper.columnDeviceAddress: widget.macAddress,
      DatabaseHelper.columnName: nameText,
    };

    Map<String, dynamic> rowrec = {
      DatabaseHelper.columnReceptionAddress: widget.macAddress,
      DatabaseHelper.columnFeed: 0, //テストデータ
      DatabaseHelper.columnDate: datetime,
      DatabaseHelper.columnBattery: 330, //テストデータ
    };
    await dbHelper.insertDevice(rowdev);
    await dbHelper.insertReception(rowrec);
    print('テストデータを登録しました');

    Navigator.pop(context, true); //登録完了フラグを前ページに渡す
  }

  // unsubscribeボタンクリック
  void _delete() async {
    await dbHelper.deleteDevice(widget.macAddress);
    await dbHelper.deleteReception(widget.macAddress);
    print('${widget.macAddress} を削除しました。');
    Navigator.pop(context, true); //登録完了フラグを前ページに渡す
  }
}
