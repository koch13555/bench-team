import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_db.dart';
import 'notification_service.dart';
import 'notification_settings.dart';

/// QRコードを読み取って座席にチェックインする処理を扱うサービスクラス
///
/// 座席は `/seats/{seatId}` と同じ seatId(例: 'seat_01')で管理する。
/// フロアはこの構造には含めない(現状は6Fのみ座席機能を持つため)。
///
/// チェックインすると、以下2箇所を同時に更新する:
///  - checkins/{seatId}/{uid} … その席に「誰が」座っているか(1席に複数人OK)
///  - user_locations/{myUid}  … 自分が「今どの席にいるか」(フレンド画面用の逆引き)
///
/// 重要: 以前は checkins/{seatId} が1人分のオブジェクトだったため、
/// 2人目がチェックインすると1人目の記録を上書きしてしまっていた。
/// グループ席(定員2人以上)で複数人が同時にチェックインできるよう、
/// checkins/{seatId} を「uidごとのマップ」に変更している。
/// ESP32側は今まで通り checkins/{seatId} 全体をDELETEするだけでよい
/// (センサーがグループ全体の離席を検知した際、そこにいた全員分を
///  まとめてクリアする形になる)。
class SeatCheckinService {
  final _db = appDatabase;
  final _auth = FirebaseAuth.instance;

  /// 実際にESP32センサーで管理している座席(グループ席A)の定員。
  /// ここに無い座席IDは、定員チェックを行わない(無制限)。
  static const Map<String, int> _seatCapacities = {
    'seat_01': 4,
    'seat_02': 4,
    'seat_03': 4,
    'seat_04': 4,
    'seat_05': 4,
    'seat_06': 4,
    'seat_07': 4,
  };

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

  /// 指定した座席に、現在チェックインしている人たち全員を取得する。
  /// チェックイン前の確認表示(「今この席に何人いるか」)に使う。
  Future<List<SeatOccupant>> getCurrentOccupants(String seatId) async {
    final snapshot = await _db.ref('checkins/$seatId').get();
    if (!snapshot.exists) return [];

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return data.entries.map((entry) {
      final value = Map<String, dynamic>.from(entry.value as Map);
      return SeatOccupant(
        uid: entry.key.toString(),
        displayName: (value['displayName'] ?? '利用者') as String,
      );
    }).toList();
  }

  /// 指定した座席に、自分(ログイン中のユーザー)をチェックインさせる。
  /// 定員が分かっている座席(グループ席A)で既に満席の場合はエラーを投げる。
  Future<void> checkIn({required String seatId}) async {
    final myUid = _myUid;

    final existing = await _db.ref('checkins/$seatId').get();
    final currentOccupants = existing.exists
        ? Map<dynamic, dynamic>.from(existing.value as Map)
        : <dynamic, dynamic>{};

    final capacity = _seatCapacities[seatId];
    if (capacity != null &&
        !currentOccupants.containsKey(myUid) &&
        currentOccupants.length >= capacity) {
      throw StateError('この座席は満席です(定員$capacity人)');
    }

    final updates = <String, dynamic>{
      'checkins/$seatId/$myUid': {
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
    // 設定画面でOFFにされている場合はスキップする。
    if (NotificationSettings.instance.checkinReminderEnabled) {
      NotificationService.instance.scheduleCheckinReminder(
        id: _notificationIdFor(seatId),
        seatId: seatId,
        delay: const Duration(minutes: 3),
      );
    }
  }

  /// seatIdから通知ID(int)を決定的に生成する。
  /// 同じ座席なら常に同じIDになるため、checkOut時に確実にキャンセルできる。
  int _notificationIdFor(String seatId) => seatId.hashCode & 0x7fffffff;

  /// 自分から自主的にチェックアウトする(QRを使わない、アプリ内ボタン用)
  /// ※通常は人感センサ側の離席検知で自動的に消えるが、
  ///   本人が明示的に「離席」を押せるようにする保険として用意
  /// 他の人が同じ座席に残っていても、自分の分だけを消す。
  Future<void> checkOut({required String seatId}) async {
    final myUid = _myUid;

    final updates = <String, dynamic>{
      'checkins/$seatId/$myUid': null,
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
