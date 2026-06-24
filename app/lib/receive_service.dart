import 'package:firebase_database/firebase_database.dart';

class ReceiveService {
  final DatabaseReference _database = 
      FirebaseDatabase.instance.ref('seats');

  // 全座席のデータをリアルタイムで受け取る
  Stream<Map<String, dynamic>> getSeatStream() {
    return _database.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};
      
      // Firebaseから取得したデータをMapに変換
      final Map<String, dynamic> seats = {};
      (data as Map).forEach((key, value) {
        seats[key] = {
          'occupied': value['occupied'] ?? false,
          'startTime': value['startTime'] ?? '',
        };
      });
      return seats;
    });
  }

  // 座席の使用時間を計算する
  String getElapsedTime(String startTime) {
    if (startTime.isEmpty) return '0分';
    
    final start = DateTime.parse(startTime);
    final elapsed = DateTime.now().difference(start);
    
    if (elapsed.inHours > 0) {
      return '${elapsed.inHours}時間${elapsed.inMinutes % 60}分';
    }
    return '${elapsed.inMinutes}分';
  }
}