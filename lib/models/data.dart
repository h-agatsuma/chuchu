import 'dart:typed_data';
import 'package:intl/intl.dart';

class Data {
  final String address;
  final String? name;
  final DateTime updateDate;
  final int feed;
  final int battery;
  final Uint8List? manufacturerData;

  Data({required this.address, this.name, required this.updateDate, required this.feed, required this.battery, this.manufacturerData});

  //「Map（DB の行や JSON など）から Data のインスタンスを作る」ためのコンストラクタ。読み込み用
  factory Data.fromMap(Map<String, dynamic> m) => Data(address: m['address'] as String, name: m['name'] as String, updateDate: DateFormat('yyyy/MM/dd HH:mm:ss').parse(m['updateDate'] as String), feed: m['feed'] as int, battery: int.parse(m['battery'] as String, radix: 16));

  //Data のインスタンスを Map に変換する⇒DB への挿入、JSON 化に使う。保存・送信用
  Map<String, dynamic> toMap() => {'address': address, 'name': name, 'updateDate': updateDate.toIso8601String(), 'feed': feed, 'battery': battery};

  // factory を追加（受信バイト列から feed/battery を算出する実装は適宜置き換えてください）
  factory Data.fromBluetooth({required String address, required String name, required List<int> manufacturerData, bool batteryBigEndian = true}) {
    final bytes = Uint8List.fromList(manufacturerData); //整数リストから固定長のバイト配列である Uint8List`を生成するためのコンストラクタ
    final Uint8List mData = Uint8List.fromList(bytes.sublist(0, bytes.length >= 3 ? 3 : bytes.length)); //manufacturerData を 3 バイトにする

    //manufacturerData を feed と battery に分割
    final int feed = parseFeed(mData);
    final int battery = parseBattery(mData);

    return Data(address: address, name: name, updateDate: DateTime.now(), feed: feed, battery: battery, manufacturerData: bytes);
  }

  //manufacturerData から feed を取り出す
  static int parseFeed(List<int>? mData) {
    if (mData == null || mData.isEmpty) return 0; //mData が空でないとき、先頭 1 バイトを左に 8 ビットシフト、 & 0xFF でマスクして 0〜255 の範囲に保つ
    return mData[0] & 0xFF;
  }

  //manufacturerData から battery を取り出す
  static int parseBattery(List<int>? mData, {bool bigEndian = true}) {
    if (mData == null || mData.length < 3) return 0;
    final int b1 = mData[1] & 0xFF;
    final int b2 = mData[2] & 0xFF;
    //batteryBigEndian が true のとき上位バイトを左に 8 ビットシフトして、下位バイトとビット合成（OR）して 16 ビット整数を作る。
    // false のときバイトの順序を入れ替えて結合する
    return bigEndian ? (b1 << 8) | b2 : (b2 << 8) | b1;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Data && other.address == address);

  @override
  int get hashCode => address.hashCode;
}
