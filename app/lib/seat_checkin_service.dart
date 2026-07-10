//libの中に置く

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// QRコードを読み取って座席にチェックインする処理を扱うサービスクラス
///
/// 座席は `/seats/{seatId}` と同じ seatId（例: 'seat_01'）で管理する。
/// フロアはこの構造には含めない（現状は6Fのみ座席機能を持つため）。
class SeatCheckinService {
  final _db = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;

  String get _myUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('ログインしていません');
    return uid;
  }

  /// テーブルのQRコード文字列(例: benchapp://checkin?seat=seat_01)を
  /// 解析し、seatIdを取り出す。形式が不正な場合はnullを返す。
  static String? parseCheckinQr(String rawValue) {
    final uri = Uri.tryParse(rawValue);
    if (uri == null || uri.host != 'checkin') return null;

    final seatId = uri.queryParameters['seat'];
    if (seatId == null || seatId.isEmpty) return null;

    return seatId;
  }

  /// 指定した座席に、自分（ログイン中のユーザー）をチェックインさせる
  Future<void> checkIn({required String seatId}) async {
    final myUid = _myUid;

    // すでに他の人がチェックイン中でないか確認
    final existing = await _db.ref('checkins/$seatId').get();
    if (existing.exists) {
      final existingUid = (existing.value as Map)['uid'];
      if (existingUid != myUid) {
        throw StateError('この座席にはすでに別の人がチェックインしています');
      }
    }

    await _db.ref('checkins/$seatId').set({
      'uid': myUid,
      'checkedInAt': ServerValue.timestamp,
    });
  }

  /// 自分から自主的にチェックアウトする（QRを使わない、アプリ内ボタン用）
  /// ※通常は人感センサ側の離席検知で自動的に消えるが、
  ///   本人が明示的に「離席」を押せるようにする保険として用意
  Future<void> checkOut({required String seatId}) async {
    final myUid = _myUid;
    final existing = await _db.ref('checkins/$seatId').get();
    if (existing.exists) {
      final existingUid = (existing.value as Map)['uid'];
      if (existingUid != myUid) {
        throw StateError('自分がチェックインしていない座席は解除できません');
      }
    }
    await _db.ref('checkins/$seatId').remove();
  }
}