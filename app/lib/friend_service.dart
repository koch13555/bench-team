import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_db.dart';

/// 自分宛に届いているフレンド申請1件分のデータ
class FriendRequest {
  final String fromUid;
  final String fromName;
  final int timestamp;

  FriendRequest({
    required this.fromUid,
    required this.fromName,
    required this.timestamp,
  });

  factory FriendRequest.fromMap(String fromUid, Map data) {
    return FriendRequest(
      fromUid: fromUid,
      fromName: (data['fromName'] ?? '不明なユーザー').toString(),
      timestamp: (data['timestamp'] ?? 0) as int,
    );
  }
}

/// フレンド1件分のデータ(名前 + 今座っている座席があればそのID)
class FriendStatus {
  final String uid;
  final String name;
  final String? seatId; // nullなら現在どこにもチェックインしていない

  FriendStatus({required this.uid, required this.name, this.seatId});
}

/// フレンド申請・承認・一覧取得を扱うサービスクラス
///
/// 名前の取り扱いについて:
/// このアプリはGoogle/Apple/メールログイン(auth_service.dart)を使っており、
/// 表示名は FirebaseAuth の displayName にすでに入っている。
/// そのため、別途 `users/{uid}/name` ノードを参照する必要はなく、
/// 申請時にその場の displayName をそのまま添えて送る方式にしている。
class FriendService {
  final _db = appDatabase;
  final _auth = FirebaseAuth.instance;

  String get _myUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('ログインしていません');
    return uid;
  }

  String get _myDisplayName {
    final user = _auth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user?.email ?? '名前未設定';
  }

  /// QRコードから読み取った相手のUIDに、フレンド申請を送る
  Future<void> sendFriendRequest(String targetUid) async {
    final myUid = _myUid;
    if (targetUid == myUid) {
      throw StateError('自分自身には申請できません');
    }

    final alreadyFriend = await _db.ref('friends/$myUid/$targetUid').get();
    if (alreadyFriend.exists) {
      throw StateError('すでにフレンドです');
    }

    // targetUid宛の申請ノードに、自分(myUid)からの申請として書き込む
    await _db.ref('friend_requests/$targetUid/$myUid').set({
      'fromName': _myDisplayName,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// 自分宛に届いているフレンド申請の一覧をリアルタイムで受け取る
  Stream<List<FriendRequest>> incomingRequests() {
    final myUid = _myUid;
    return _db.ref('friend_requests/$myUid').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return <FriendRequest>[];
      return data.entries
          .map((e) =>
              FriendRequest.fromMap(e.key as String, Map.from(e.value as Map)))
          .toList();
    });
  }

  /// フレンド申請を承認する。
  /// 双方のfriendsリストに「相手の名前」を添えて同時追加し、申請ノードを削除する。
  Future<void> approveRequest(FriendRequest request) async {
    final myUid = _myUid;
    final updates = <String, dynamic>{
      'friends/$myUid/${request.fromUid}': {'name': request.fromName},
      'friends/${request.fromUid}/$myUid': {'name': _myDisplayName},
      'friend_requests/$myUid/${request.fromUid}': null, // nullを書き込む=削除
    };
    await _db.ref().update(updates);
  }

  /// フレンド申請を拒否する(申請ノードのみ削除)
  Future<void> rejectRequest(String fromUid) async {
    final myUid = _myUid;
    await _db.ref('friend_requests/$myUid/$fromUid').remove();
  }

  /// 自分のフレンド一覧(名前つき)をリアルタイムで受け取る
  Stream<List<FriendStatus>> friendList() {
    final myUid = _myUid;
    return _db.ref('friends/$myUid').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return <FriendStatus>[];
      return data.entries.map((e) {
        final value = Map<String, dynamic>.from(e.value as Map);
        return FriendStatus(
          uid: e.key as String,
          name: (value['name'] ?? '名前未設定').toString(),
        );
      }).toList();
    });
  }

  /// フレンド一覧に、各フレンドの「現在の座席」をあわせて取得する。
  /// user_locations は座席チェックインのたびに更新される軽量な逆引きノード。
  /// ※各フレンドにつき1回ずつ読み取るため、都度呼び出す(pull-to-refreshなど)想定。
  Future<List<FriendStatus>> loadFriendsWithLocation() async {
    final myUid = _myUid;
    final friendsSnapshot = await _db.ref('friends/$myUid').get();
    if (!friendsSnapshot.exists) return [];

    final friendsData = Map<String, dynamic>.from(friendsSnapshot.value as Map);
    final result = <FriendStatus>[];

    for (final entry in friendsData.entries) {
      final uid = entry.key;
      final value = Map<String, dynamic>.from(entry.value as Map);
      final name = (value['name'] ?? '名前未設定').toString();

      final locationSnapshot = await _db.ref('user_locations/$uid').get();
      String? seatId;
      if (locationSnapshot.exists) {
        final locationData = Map<String, dynamic>.from(locationSnapshot.value as Map);
        seatId = locationData['seatId'] as String?;
      }

      result.add(FriendStatus(uid: uid, name: name, seatId: seatId));
    }
    return result;
  }

  /// フレンドを削除する(双方のfriendsリストから削除)
  Future<void> removeFriend(String friendUid) async {
    final myUid = _myUid;
    final updates = <String, dynamic>{
      'friends/$myUid/$friendUid': null,
      'friends/$friendUid/$myUid': null,
    };
    await _db.ref().update(updates);
  }
}
