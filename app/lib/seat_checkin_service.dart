import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_db.dart';
import 'notification_service.dart';

/// QRコードを読み取って座席にチェックインする処理を扱うサービスクラス
///
/// 座席は `/seats/{seatId}` と同じ seatId(例: 'seat_01')で管理する。
/// フロアはこの構造には含めない(現状は6Fのみ座席機能を持つため)。
///
/// チェックインすると、以下2箇所を同時に更新する:
///  - checkins/{seatId}       … その席に「誰が」座っているか(表示名つき)
///  - user_locations/{myUid}  … 自分が「今どの席にいるか」(フレンド画面用の逆引き)
class SeatCheckinService {
  final _db = appDatabase;
  final _auth = FirebaseAuth.instance;

  String get _myUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('ログインしていません');
    return uid;
  }

  /// 表示名が未設定の場合はメールアドレスを、それも無ければ「ゲスト」を使う
  String get _myDisplayName {
    final user = _auth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user?.email ?? 'ゲスト';
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

  /// 指定した座席に、現在チェックインしている人がいれば取得する。
  /// チェックイン前の確認画面(「今この席に誰がいるか」表示)に使う。
  /// 誰もいなければ null を返す。
  Future<SeatOccupant?> getCurrentOccupant(String seatId) async {
    final snapshot = await _db.ref('checkins/$seatId').get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return SeatOccupant(
      uid: data['uid'] as String,
      displayName: (data['displayName'] ?? '利用者') as String,
    );
  }

  /// 指定した座席に、自分(ログイン中のユーザー)をチェックインさせる
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

    final updates = <String, dynamic>{
      'checkins/$seatId': {
        'uid': myUid,
        'displayName': _myDisplayName,
        'checkedInAt': ServerValue.timestamp,
      },
      'user_locations/$myUid': {
        'seatId': seatId,
        'updatedAt': ServerValue.timestamp,
      },
    };
    await _db.ref().update(updates);

    // 3分放置(ESP32側の自動離席判定と同じ時間)で「まだ使いますか?」を通知する。
    // ローカル通知のため、アプリが完全に終了していると届かない場合がある。
    NotificationService.instance.scheduleCheckinReminder(
      id: _notificationIdFor(seatId),
      seatId: seatId,
      delay: const Duration(minutes: 3),
    );
  }

  /// seatIdから通知ID(int)を決定的に生成する。
  /// 同じ座席なら常に同じIDになるため、checkOut時に確実にキャンセルできる。
  int _notificationIdFor(String seatId) => seatId.hashCode & 0x7fffffff;

  /// 自分から自主的にチェックアウトする(QRを使わない、アプリ内ボタン用)
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

    final updates = <String, dynamic>{
      'checkins/$seatId': null,
      'user_locations/$myUid': null,
    };
    await _db.ref().update(updates);
  }
}

/// 座席に現在チェックインしている人の情報
class SeatOccupant {
  final String uid;
  final String displayName;

  SeatOccupant({required this.uid, required this.displayName});
}
