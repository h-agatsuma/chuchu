import 'dart:typed_data';

class Data {
  final String address;
  final String? name;
  final DateTime updateDate;
  final int feed;
  final int battery;
  final Uint8List? manufacturerData;


  Data({required this.address, this.name, required this.updateDate,required this.feed,required this.battery,this.manufacturerData});

  //「Map（DBの行やJSONなど）から Data のインスタンスを作る」ためのコンストラクタ。読み込み用
  factory Data.fromMap(Map<String, dynamic> m) => Data(
    address: m['address'] as String,
    name: m['name'] as String,
    updateDate: DateTime.parse(m['date'] as String),
    feed:m['feed'] as int,
    battery:m['battery'] as int,
  );

  //DataのインスタンスをMapに変換する⇒DBへの挿入、JSON化に使う。保存・送信用
  Map<String, dynamic> toMap() => {
    'address': address,
    'name': name,
    'updateDate': updateDate.toIso8601String(),
    'feed' : feed,
    'battery':battery,
  };

  // factory を追加（受信バイト列から feed/battery を算出する実装は適宜置き換えてください）
  factory Data.fromBluetooth({
    required String address,
    required String name,
    required List<int> manufacturerData,
    bool batteryBigEndian = true,
  }) {
    final bytes=Uint8List.fromList(manufacturerData); //整数リストから固定長のバイト配列であるUint8List`を生成するためのコンストラクタ
    final Uint8List mData = Uint8List.fromList(bytes.sublist(0, bytes.length >= 3 ? 3 : bytes.length)); //manufacturerDataを３バイトにする

    //manufacturerDataをfeedとbatteryに分割
    final int feed = parseFeed(mData);
    final int battery = parseBattery(mData);


    return Data(
      address: address,
      name: name,
      updateDate: DateTime.now(),
      feed: feed,
      battery: battery,
      manufacturerData: bytes,
    );
  }

  //manufacturerDataからfeedを取り出す
  static int parseFeed(List<int>? mData) {
    if (mData == null || mData.isEmpty) return 0; //mDataが空でないとき、先頭1バイトを左に８ビットシフト、 & 0xFF でマスクして 0〜255 の範囲に保つ
    return mData[0] & 0xFF;
  }

  //manufacturerDataからbatteryを取り出す
  static int parseBattery(List<int>? mData, {bool bigEndian = true}) {
    if (mData == null || mData.length < 3) return 0;
    final int b1 = mData[1] & 0xFF;
    final int b2 = mData[2] & 0xFF;
    //batteryBigEndianがtrueのとき上位バイトを左に８ビットシフトして、下位バイトとビット合成（OR）して16ビット整数を作る。
    // falseのときバイトの順序を入れ替えて結合する
    return bigEndian ? (b1 << 8) | b2 : (b2 << 8) | b1;
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Data && other.address == address);

  @override
  int get hashCode => address.hashCode;
}
