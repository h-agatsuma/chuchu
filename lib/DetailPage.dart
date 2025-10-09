import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; //時刻で使った
import 'db/database_helper1.dart';
import 'db/device_dao.dart';
import 'db/reception_dao.dart';
import 'package:form_field_validator/form_field_validator.dart';

class DetailPage extends StatefulWidget {
  final String macAddress;
  final String? name;

  DetailPage({super.key, required this.macAddress, this.name});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final dbHelper = DatabaseHelper.instance;
  late final deviceDao = DeviceDao(dbHelper);
  late final receptionDao = ReceptionDao(dbHelper);
  late TextEditingController nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    //テキストフィールドの初期表示
    nameController = TextEditingController(
        text: (widget.name != null && widget.name!.isNotEmpty)
            ? widget.name!
            : ""
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
        title: const Text('ChuChuCheckApp', style: TextStyle(color: Colors.white, fontSize: 32)),
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
                const Text("MAC Address:", style: TextStyle(fontSize: 20)),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4, bottom: 100),
                  // ← 値だけインデント
                  child: Text(widget.macAddress, style: const TextStyle(fontSize: 24)),
                ),

                // --- Name ---
                const Text("Device Name:", style: TextStyle(fontSize: 20)),

                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4, bottom: 100),
                  child:Form(
                    autovalidateMode: AutovalidateMode.always,
                    key: _formKey,
                  child: TextFormField(
                    controller: nameController,
                    //maxLength: 30,
                    style: const TextStyle(fontSize: 30),
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(), // 枠線を付ける
                    ),
                    validator: (value) {
                      if (value!=null&&value.length > 31) return '31字以下で入力してください。';
                      if (value!=null&&!RegExp(r'^[a-zA-Z0-9]*$').hasMatch(value)) return '半角英数字で入力してください。';
                      return null;
                    },
                  ),
                ),),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            //バリデーション成功時のみインサート・更新メソッド
                            _insOrReplace();
                          } else {
                            debugPrint('入力エラー');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(150, 80),
                          backgroundColor: const Color(0xFF32CD32),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
            Text("Powered by Signpost Co., Ltd.", style: TextStyle(fontSize: 14)),
            Icon(Icons.image, size: 20),
          ],
        ),
      ),
    );
  }

  // subscribe ボタンクリック
  void _insOrReplace() async {
    final nameText = nameController.text; //テキストフィールドに入力された名前を取得
    Map<String, dynamic> rowdev = {DatabaseHelper.columnDeviceAddress: widget.macAddress, DatabaseHelper.columnName: nameText};
    await deviceDao.upsertDevice(rowdev);

//登録完了フラグを前ページに渡す
    Navigator.pop(context, {
      'updated': true,
      'address': widget.macAddress,
      'name': nameText,
    });

  }

  // unsubscribe ボタンクリック
  void _delete() async {
    await deviceDao.deleteDevice(widget.macAddress);
    print('${widget.macAddress} を削除しました。');
//削除完了フラグを前ページに渡す
    Navigator.pop(context, {
      'deleted': true,
      'address': widget.macAddress,
    });}
}
