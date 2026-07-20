import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_db.dart';
import 'dart:async';
import 'firebase_options.dart'; // firebase設定ファイル
import 'checkin_page.dart';
import 'friend_screen.dart';
import 'profile_page.dart';
import 'profile_avatar.dart';
import 'main.dart';
import 'how_to_use_page.dart';
import 'about_page.dart';
import 'feedback_page.dart';
import 'terms_page.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// フレンド画面への遷移を試みる共通処理。
/// ゲスト(匿名ログイン)の場合は「誰がどこに座っているか」を扱う
/// フレンド機能には入れないため、遷移せず案内ダイアログを表示する。
/// (Firebase側のセキュリティルールでも同様に書き込みを拒否する設計が望ましいが、
///  ここではユーザーに分かりやすく理由を伝えるために先回りしてブロックする)
void goToFriendScreen(BuildContext context) {
  final isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
  if (isGuest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲストはご利用いただけません'),
        content: const Text(
          'フレンド機能(誰がどこに座っているかを把握する機能)は、'
          'アカウントを作成した方のみ利用できます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const FriendScreen()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- フレンド申請の通知用 ---
  StreamSubscription<DatabaseEvent>? _friendRequestsSub;
  Set<String> _knownRequestUids = {};

  // --- フレンドが着席したかの通知用 ---
  StreamSubscription<DatabaseEvent>? _friendsListSub;
  final Map<String, StreamSubscription<DatabaseEvent>> _friendLocationSubs = {};
  final Map<String, String?> _lastKnownFriendSeat = {};
  final Map<String, String> _friendNames = {};

  // --- 離席時にQRチェックイン状態を自動でログアウトさせる仕組み ---
  StreamSubscription<DatabaseEvent>? _myLocationSub;
  StreamSubscription<DatabaseEvent>? _myCheckinSub;
  String? _myWatchedSeatId;

  @override
  void initState() {
    super.initState();
    _watchFriendRequests();
    _watchFriendsList();
    _watchMyOwnCheckin();
  }

  @override
  void dispose() {
    _friendRequestsSub?.cancel();
    _friendsListSub?.cancel();
    for (final sub in _friendLocationSubs.values) {
      sub.cancel();
    }
    _myLocationSub?.cancel();
    _myCheckinSub?.cancel();
    super.dispose();
  }

  /// フレンド申請が新しく届いたら通知する
  void _watchFriendRequests() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _friendRequestsSub = appDatabase.ref('friend_requests/$uid').onValue.listen((event) {
      final data = event.snapshot.value;
      final currentUids = <String>{};
      if (data is Map) {
        currentUids.addAll(data.keys.map((k) => k.toString()));
      }
      final newOnes = currentUids.difference(_knownRequestUids);
      for (final fromUid in newOnes) {
        final entry = data is Map ? data[fromUid] : null;
        final fromName = entry is Map ? (entry['fromName']?.toString() ?? '不明なユーザー') : '不明なユーザー';
        NotificationService.instance.showFriendRequestNotification(fromName);
      }
      _knownRequestUids = currentUids;
    });
  }

  /// フレンド一覧を監視し、それぞれの着席状況の監視を開始/終了する
  void _watchFriendsList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _friendsListSub = appDatabase.ref('friends/$uid').onValue.listen((event) {
      final data = event.snapshot.value;
      final currentFriendUids = <String>{};
      if (data is Map) {
        for (final entry in data.entries) {
          final friendUid = entry.key.toString();
          currentFriendUids.add(friendUid);
          final value = entry.value;
          if (value is Map) {
            _friendNames[friendUid] = (value['name'] ?? '名前未設定').toString();
          }
          if (!_friendLocationSubs.containsKey(friendUid)) {
            _watchFriendLocation(friendUid);
          }
        }
      }
      // フレンドでなくなった相手の監視は止める
      final removed = _friendLocationSubs.keys.toSet().difference(currentFriendUids);
      for (final r in removed) {
        _friendLocationSubs[r]?.cancel();
        _friendLocationSubs.remove(r);
        _lastKnownFriendSeat.remove(r);
      }
    });
  }

  /// 特定のフレンドの現在地を監視し、「座っていなかった→座った」の
  /// 変化があった瞬間だけ通知する
  void _watchFriendLocation(String friendUid) {
    _friendLocationSubs[friendUid] =
        appDatabase.ref('user_locations/$friendUid').onValue.listen((event) {
      final data = event.snapshot.value;
      final seatId = data is Map ? data['seatId'] as String? : null;
      final lastSeat = _lastKnownFriendSeat[friendUid];

      if (seatId != null && lastSeat == null) {
        final name = _friendNames[friendUid] ?? '友達';
        NotificationService.instance.showFriendSeatedNotification(name, seatId);
      }
      _lastKnownFriendSeat[friendUid] = seatId;
    });
  }

  /// 自分がチェックインしている座席を監視し、
  /// ESP32のセンサーが離席を検知してcheckinsを削除した(=自分がその席に
  /// いなくなった)ら、user_locationsも自動で片付け、放置リマインド通知も
  /// キャンセルする。これが「離席したらQRチェックイン状態が自動でログアウトする」仕組み。
  void _watchMyOwnCheckin() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _myLocationSub = appDatabase.ref('user_locations/$uid').onValue.listen((event) {
      final data = event.snapshot.value;
      final seatId = data is Map ? data['seatId'] as String? : null;

      if (seatId == _myWatchedSeatId) return;

      // 監視対象の座席が変わったので、古い方の監視は止める
      _myCheckinSub?.cancel();
      _myCheckinSub = null;
      _myWatchedSeatId = seatId;

      if (seatId == null) return;

      _myCheckinSub = appDatabase.ref('checkins/$seatId').onValue.listen((checkinEvent) {
        final checkinData = checkinEvent.snapshot.value;
        final checkinUid = checkinData is Map ? checkinData['uid'] as String? : null;

        // checkins側が消えた(または別人になった) = ESP32が離席を検知した
        if (checkinUid != uid) {
          appDatabase.ref('user_locations/$uid').remove();
          NotificationService.instance.cancel(seatId.hashCode & 0x7fffffff);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
      final user = FirebaseAuth.instance.currentUser;
      final displayName = (user?.displayName?.isNotEmpty ?? false)
          ? user!.displayName!
          : (user?.email ?? 'ゲスト');
    return Scaffold(
      backgroundColor: const Color(0xFF8DF172),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                            child: const _HeaderChip(label: 'ログアウト'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // プロフィールアイコン(タップでプロフィール画面へ)
                  ProfileAvatar(
                    size: 56,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 検索バー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: '検索',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // キャンパス選択エリア（スクロール可能な四角で囲む）
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'キャンパスを選択してください',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // スクロール可能な四角で囲んだキャンパスカード
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: const _CampusListSection(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ステータス情報
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'システム正常稼働中 • 更新 2分前',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ボトムナビゲーション
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ホーム
              _NavItem(
                icon: Icons.home,
                label: 'ホーム',
                isActive: true,
              ),
              // フレンド
              _NavItem(
                icon: Icons.people_outline,
                label: 'フレンド',
                isActive: false,
                onTap: () => goToFriendScreen(context),
              ),
              // QRコード（同じサイズ・同じ色）
              _NavItem(
                icon: Icons.qr_code_scanner,
                label: 'QRコード',
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckinPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  const _HeaderChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// キャンパス1件分の固定データ。idはお気に入り保存時のキーとして使う。
class _CampusInfo {
  final String id;
  final String name;
  final String subtitle;

  const _CampusInfo({required this.id, required this.name, required this.subtitle});
}

final List<_CampusInfo> _allCampuses = [
  const _CampusInfo(id: 'umeda', name: 'OIT 梅田キャンパス', subtitle: 'Umeda Campus'),
  const _CampusInfo(id: 'hirakata', name: 'OIT 枚方キャンパス', subtitle: 'Hirakata Campus'),
  const _CampusInfo(id: 'omiya', name: 'OIT 大宮キャンパス', subtitle: 'Omiya Campus'),
  // テスト用ダミーキャンパス(検索・スクロール動作確認用) A〜Z
  for (int i = 0; i < 26; i++)
    _CampusInfo(
      id: 'test_${String.fromCharCode(65 + i)}',
      name: 'テストキャンパス${String.fromCharCode(65 + i)}',
      subtitle: 'Dummy ${String.fromCharCode(65 + i)}',
    ),
];

/// キャンパス一覧を表示するセクション。
/// お気に入り(★)は Realtime Database の `users/{uid}/favoriteCampuses` に
/// 保存し、お気に入りにした項目が一覧の上位に来るよう並び替える。
class _CampusListSection extends StatefulWidget {
  const _CampusListSection();

  @override
  State<_CampusListSection> createState() => _CampusListSectionState();
}

class _CampusListSectionState extends State<_CampusListSection> with RouteAware {
  final _searchController = TextEditingController();
  String _query = '';

  // お気に入りの並び順は、画面を開いた時点・他の画面から戻ってきた時点でのみ
  // 確定させる(お気に入りボタンを押した瞬間には並び替えない)。
  List<_CampusInfo>? _order;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
    _refreshOrder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  /// 他の画面(座席詳細やチェックイン画面など)から戻ってきた時に呼ばれる。
  /// ここで初めてお気に入りの並び順を更新する。
  @override
  void didPopNext() {
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final favoriteIds = <String>{};
    if (uid != null) {
      final snapshot = await appDatabase.ref('users/$uid/favoriteCampuses').get();
      final data = snapshot.value;
      if (data is Map) {
        favoriteIds.addAll(data.keys.map((k) => k.toString()));
      }
    }
    final sorted = [..._allCampuses]
      ..sort((a, b) {
        final aFav = favoriteIds.contains(a.id);
        final bFav = favoriteIds.contains(b.id);
        if (aFav == bFav) return 0;
        return aFav ? -1 : 1;
      });
    if (mounted) {
      setState(() => _order = sorted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final order = _order ?? _allCampuses;
    final query = _query.toLowerCase();
    final visible = query.isEmpty
        ? order
        : order
            .where((c) =>
                c.name.toLowerCase().contains(query) ||
                c.subtitle.toLowerCase().contains(query))
            .toList();

    return Column(
      children: [
        // 検索バー(名前・英語表記の部分一致で絞り込み)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'キャンパスを検索',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
            ),
          ),
        ),
        Expanded(
          child: uid == null
              ? _buildList(context, visible, const <String>{}, null)
              : StreamBuilder<DatabaseEvent>(
                  // 星の見た目(ON/OFF)はリアルタイムに反映するが、
                  // 並び順(visible)はここでは変更しない。
                  stream: appDatabase.ref('users/$uid/favoriteCampuses').onValue,
                  builder: (context, snapshot) {
                    final favData = snapshot.data?.snapshot.value;
                    final favoriteIds = <String>{};
                    if (favData is Map) {
                      favoriteIds.addAll(favData.keys.map((k) => k.toString()));
                    }
                    return _buildList(context, visible, favoriteIds, uid);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<_CampusInfo> items,
    Set<String> favoriteIds,
    String? uid,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('見つかりませんでした', style: TextStyle(color: Colors.grey)),
            ),
          for (int i = 0; i < items.length; i++) ...[
            _CampusCard(
              name: items[i].name,
              subtitle: items[i].subtitle,
              isFavorite: favoriteIds.contains(items[i].id),
              onFavoriteTap: uid == null
                  ? null
                  : () => _toggleFavorite(uid, items[i].id, favoriteIds.contains(items[i].id)),
              onTap: items[i].id == 'umeda'
                  ? () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          pageBuilder: (_, __, ___) => const FloorSelectPage(),
                        ),
                      );
                    }
                  : null,
            ),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(String uid, String campusId, bool currentlyFavorite) async {
    final ref = appDatabase.ref('users/$uid/favoriteCampuses/$campusId');
    if (currentlyFavorite) {
      await ref.remove();
    } else {
      await ref.set(true);
    }
  }
}


class _CampusCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const _CampusCard({
    required this.name,
    required this.subtitle,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // お気に入りの星(常に表示。タップでON/OFF切り替え)
            Positioned(
              top: -4,
              left: -4,
              child: GestureDetector(
                onTap: onFavoriteTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Icon(Icons.business, color: Color(0xFF7AD961), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF1A1C1C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isActive ? const Color(0xFF106E00) : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF106E00) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}


/// ===== カラーパレット =====
/// 元デザイン (すわほui-1.png) からピクセル抽出した値
class AppColors {
  static const Color mainGreen = Color(0xFF8DF172); // メインの緑
  static const Color lightGreen = Color(0xFFB3FF9E); // 薄い緑（ボタン・選択メニュー項目）
  static const Color bgGray = Color(0xFFF5F5F5); // ページ背景グレー
  static const Color gridGray = Color(0xFFD9D9D9); // フロアマップのグリッド（設備など）
  static const Color overlayGray = Color(0xFFEBEBEB); // ドロワー表示時のコンテンツオーバーレイ
  static const Color skeletonGray = Color(0xFFE0E0E0); // ローディング用バー

  // --- 座席の状態色 ---
  // --- 座席の状態色 ---
  static const Color seatVacant = Colors.blue; // 空席（白から青に変更）
  static const Color seatVacantBorder = Color(0xFFBDBDBD);
  static const Color seatOccupied = Color(0xFFEF5350); // 使用中
  static const Color seatOccupiedBorder = Color(0xFFD32F2F);
}

/// =========================================================
/// 座席・設備の状態管理（モデル）
/// memo.dart から人名・部署名などの個人情報を除いた、
/// 座席そのものの情報（コンセント有無などのアメニティ・着席状態）のみを保持する。
/// =========================================================

/// フロアの外形線(壁)や、部屋の内側の仕切り線を頂点リストから描画するPainter。
/// フロアマップ画像の太い青線を再現するためのもの。
/// [outlines] は複数の線のリスト。各要素は「閉じた多角形にするか」を
/// closed で指定できる(部屋の枠は閉じる、途中で終わる仕切り線は閉じない)。
class _FloorWallPainter extends CustomPainter {
  final List<_WallPath> outlines;

  _FloorWallPainter(this.outlines);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E6BE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.miter;

    for (final wall in outlines) {
      if (wall.points.isEmpty) continue;
      final path = Path()..moveTo(wall.points.first.dx, wall.points.first.dy);
      for (final p in wall.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      if (wall.closed) path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloorWallPainter oldDelegate) =>
      oldDelegate.outlines != outlines;
}

/// 壁の1本分の線データ。[closed]がtrueなら始点と終点をつないで多角形として閉じる。
class _WallPath {
  final List<Offset> points;
  final bool closed;
  const _WallPath(this.points, {this.closed = true});
}

/// 6F「フロアマップ.png」の壁(外形線)の頂点座標。
/// 画像を目視でトレースした概算値のため、細かい凹凸は簡略化している箇所がある。
/// 実機で見て気になる箇所があれば座標を調整する。
final List<_WallPath> floor6FWallOutlines = [
  // --- 外周の壁 ---
  const _WallPath([
    Offset(175, 175),
    Offset(355, 175),
    Offset(355, 15),
    Offset(735, 15),
    Offset(735, 175),
    Offset(785, 175),
    Offset(785, 320),
    Offset(955, 320),
    Offset(955, 1210),
    Offset(750, 1210),
    Offset(750, 1430),
    Offset(650, 1430),
    Offset(650, 1520),
    Offset(175, 1520),
  ]),
  // --- 受付カウンターの内側の枠線 ---
  const _WallPath([
    Offset(345, 180),
    Offset(645, 180),
    Offset(645, 235),
    Offset(345, 235),
  ]),
  // --- 倉庫の部屋の枠線 ---
  const _WallPath([
    Offset(170, 1010),
    Offset(290, 1010),
    Offset(290, 1140),
    Offset(170, 1140),
  ]),
  // --- グループ席ホールと倉庫・メディアデーク側を区切る仕切り線(閉じない) ---
  _WallPath(const [
    Offset(175, 1010),
    Offset(630, 1010),
    Offset(630, 1150),
  ], closed: false),
];
enum FloorItemType {
  seat, // タップして着席/退席できる座席
  facility, // 受付・棚・パーティションなどタップ不可の設備
  label, // 「入口」などのテキストラベル
}

/// 座席そのものの情報（着席状態・アメニティ）
/// 人名・部署名などの個人情報は持たない。
class SeatInfo {
  final String name; // 例: 'デスク A-1'
  final List<String> amenities; // 例: ['電源', '窓際']
  final int capacity; // 座れる人数
  bool isOccupied; // 現在誰かが使用中かどうか（個人を特定しない単純な真偽値）
  bool isProhibited; // 現在使用禁止かどうか
  int? prohibitedStart; // Firebaseから取得した禁止開始時間
  int? prohibitedEnd;   // Firebaseから取得した禁止終了時間

  SeatInfo({
    required this.name,
    required this.amenities,
    this.capacity = 1,
    this.isOccupied = false,
    this.isProhibited = false,
    this.prohibitedStart,
    this.prohibitedEnd,
  });

  bool get hasPower => amenities.contains('電源');
}

/// =========================================================
/// 1. 最初のフロア選択画面
/// 「フロアを選択してください」 + 6F / 9F ボタン
/// タップすると即座に該当フロアの画面に遷移する
/// =========================================================
class FloorSelectPage extends StatelessWidget {
  const FloorSelectPage({super.key});

  void _goToFloor(BuildContext context, String floor) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero, // 動画では遷移はカットのように見えるため瞬時に切り替え
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => FloorMapPage(floor: floor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainGreen,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'ホーム',
                isActive: false,
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'フレンド',
                isActive: false,
                onTap: () => goToFriendScreen(context),
              ),
              _NavItem(
                icon: Icons.qr_code_scanner,
                label: 'QRコード',
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckinPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'フロアを選択してください',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              _FloorButton(
                label: '6F',
                onTap: () => _goToFloor(context, '6F'),
              ),
              const SizedBox(height: 16),
              _FloorButton(
                label: '9F',
                onTap: () => _goToFloor(context, '9F'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloorButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FloorButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightGreen,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          width: 140,
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// =========================================================
/// 2. フロアマップ画面（6F / 9F 共通）
/// 上部: ハンバーガーメニュー
/// 中央: フロアマップ（グリッド状のアイコン）— ローディングの
///       フェードアニメーションあり
/// 下部: 緑色のフロア表示バー
/// 左からDrawer（ハンバーガーメニュー）がスライドインする
///
/// 座席（FloorItemType.seat）をタップすると、着席状態を
/// ボトムシートで確認・変更できる（memo.dart の座席管理ロジックを統合）。
/// =========================================================
class FloorMapPage extends StatefulWidget {
  final String floor;
  const FloorMapPage({super.key, required this.floor});

  @override
  State<FloorMapPage> createState() => _FloorMapPageState();
}

class _FloorMapPageState extends State<FloorMapPage> {
  late String _currentFloor;
  bool _isLoading = true;

  // 自分が今チェックインしている座席のID(例: 'seat_01')。
  // どこにもチェックインしていなければ null。
  String? _myCurrentSeatId;
  StreamSubscription<DatabaseEvent>? _myLocationSub;

  // 'seat_01' のような文字列を、SeatInfoリストのインデックス(0始まり)に変換する。
  // ESP32側は座席番号を1始まりで送っているため、-1 して0始まりに揃える。
  int? get _mySeatIndex {
    final seatId = _myCurrentSeatId;
    if (seatId == null) return null;
    final match = RegExp(r'seat_(\d+)').firstMatch(seatId);
    if (match == null) return null;
    final seatNumber = int.tryParse(match.group(1)!);
    if (seatNumber == null) return null;
    return seatNumber - 1;
  }

  // フロアごとの座席状態を保持する（着席/退席で更新される）。
  // 6F のみ座席データを持つ。9F は座席機能なし（見た目のみ）。
  late Map<String, List<SeatInfo>> _seatsByFloor;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _seatsByFloor = {
      '6F': _buildInitial6FSeats(),
    };
    _startLoadingAnimation();
  

    _listenToFirebase();
    _listenToMyLocation();
  }
  int _currentHour = 9;

  // 災害用モード（フェーズフリー機能）: ON/OFFは手動で切り替える
  bool _isDisasterMode = false;

  void _toggleDisasterMode() {
    setState(() => _isDisasterMode = !_isDisasterMode);
  }

  // --- 自分が今どの座席にいるか(user_locations)をリアルタイム監視する処理 ---
  void _listenToMyLocation() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final database = appDatabase;

    _myLocationSub =
        database.ref('user_locations/$myUid').onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      setState(() {
        if (data == null) {
          _myCurrentSeatId = null;
        } else {
          final map = Map<String, dynamic>.from(data as Map);
          _myCurrentSeatId = map['seatId'] as String?;
        }
      });
    });
  }

  @override
  void dispose() {
    _myLocationSub?.cancel();
    super.dispose();
  }

  // --- ★変更: Firebase監視処理 ---
  void _listenToFirebase() {
    final database = appDatabase;
    
    // 1. Firebaseから現在の「時間」を取得
    database.ref('system/current_hour').onValue.listen((event) {
      if (event.snapshot.value != null) {
        int newHour = int.tryParse(event.snapshot.value.toString()) ?? 9;
        if (mounted) {
          setState(() {
            _currentHour = newHour;
            _updateAllSeatsProhibition(); // 時間が変わったら全席の禁止状態を再計算
          });
        }
      }
    });

    // 2. 座席ごとの利用状況と禁止設定を取得
    final seatsRef = database.ref('seats');
    seatsRef.onChildAdded.listen(_handleSeatEvent);
    seatsRef.onChildChanged.listen(_handleSeatEvent);
  }

  // --- ★変更: Firebaseから座席ごとの禁止時間を読み取る ---
  void _handleSeatEvent(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      
      final seatNumber = int.tryParse(data['seat_number']?.toString() ?? '');
      final occupied = data['occupied'] == true; 

      // 座席個別の禁止時間を取得
      final pStart = int.tryParse(data['prohibited_start']?.toString() ?? '');
      final pEnd = int.tryParse(data['prohibited_end']?.toString() ?? '');

      if (seatNumber != null && seatNumber >= 1 && seatNumber <= 7) {
        int chairIndex = seatNumber - 1; 

        if (mounted) {
          setState(() {
            final seats = _seatsByFloor['6F'];
            if (seats != null && chairIndex >= 0 && chairIndex < seats.length) {
              
              // 取得した禁止時間をセット
              seats[chairIndex].prohibitedStart = pStart;
              seats[chairIndex].prohibitedEnd = pEnd;
              
              _checkProhibitionForSeat(seats[chairIndex]);

              // 禁止されていなければ着席状態を反映
              if (!seats[chairIndex].isProhibited) {
                seats[chairIndex].isOccupied = occupied;
              } else {
                seats[chairIndex].isOccupied = false; // 禁止なら強制離席
              }
            }
          });
        }
      }
    }
  }

  // --- 個別の座席が禁止時間帯かどうか判定する ---
  void _checkProhibitionForSeat(SeatInfo seat) {
    if (seat.prohibitedStart != null && seat.prohibitedEnd != null) {
      seat.isProhibited = (_currentHour >= seat.prohibitedStart! && _currentHour < seat.prohibitedEnd!);
    } else {
      seat.isProhibited = false;
    }
  }

  void _updateAllSeatsProhibition() {
    final seats = _seatsByFloor['6F'];
    if (seats == null) return;
    for (var seat in seats) {
      _checkProhibitionForSeat(seat);
      if (seat.isProhibited) seat.isOccupied = false;
    }
  }
  /// フロアマップのスケルトン→実体のフェード切り替えを
  /// ループ再生する（動画内で繰り返し見られたローディング表現）
  void _startLoadingAnimation() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  void _changeFloor(String floor) {
    setState(() {
      _currentFloor = floor;
    });
    _startLoadingAnimation();
    Navigator.of(context).pop(); // ドロワーを閉じる
  }

  /// 座席タップ時：ボトムシートで詳細を表示し、着席/退席を行う。
  /// 災害用モード中は「かまどベンチの使い方」を表示する。
  void _handleSeatTap(FloorMapItem item) {
    if (_isDisasterMode) {
      final kamadoInfo =
          item.seatIndex != null ? kamadoBenchInfoBySeatIndex[item.seatIndex] : null;
      if (kamadoInfo == null) return; // かまどベンチ以外はタップ不可（念のためのガード）

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => KamadoBenchDetailSheet(info: kamadoInfo),
      );
      return;
    }

    final seats = _seatsByFloor[_currentFloor];
    if (seats == null) return;
    final seatIndex = item.seatIndex;
    if (seatIndex == null || seatIndex >= seats.length) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SeatDetailSheet(seat: seats[seatIndex]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seats = _seatsByFloor[_currentFloor];

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: FloorDrawer(
        currentFloor: _currentFloor,
        onFloorSelected: _changeFloor,
      ),
      drawerScrimColor: Colors.black.withOpacity(0.08),
      
      // ↓ここから追加
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.home_outlined, size: 26, color: Colors.grey),
                    SizedBox(height: 2),
                    Text('ホーム', style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => goToFriendScreen(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.people_outline, size: 26, color: Colors.grey),
                    SizedBox(height: 2),
                    Text('フレンド', style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckinPage()),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.qr_code_scanner, size: 26, color: Colors.grey),
                    SizedBox(height: 2),
                    Text('QRコード', style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // ↑ここまで追加
      
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（ハンバーガーメニュー・災害用モード切替）
            Container(
              width: double.infinity,
              height: 48,
              color: AppColors.mainGreen,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isDisasterMode ? Icons.warning : Icons.warning_amber_outlined,
                      color: _isDisasterMode ? Colors.yellowAccent : Colors.white,
                    ),
                    tooltip: '災害用モード切替',
                    onPressed: _toggleDisasterMode,
                  ),
                ],
              ),
            ),
            // 災害用モード中であることを知らせるバナー
            if (_isDisasterMode)
              Container(
                width: double.infinity,
                color: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: const Text(
                  '災害用モード：オレンジ色の座席がかまどベンチです',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            // フロアマップ本体
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isLoading
                    ? _FloorMapSkeleton(
                        key: ValueKey('skeleton-$_currentFloor'),
                        floor: _currentFloor,
                      )
                    : _FloorMapContent(
                        key: ValueKey('content-$_currentFloor'),
                        floor: _currentFloor,
                        seats: seats,
                        onSeatTap: _handleSeatTap,
                        mySeatIndex: _mySeatIndex,
                        isDisasterMode: _isDisasterMode,
                      ),
              ),
            ),
            // フッター（現在のフロア表示）
            Container(
              width: double.infinity,
              height: 56,
              color: AppColors.mainGreen,
              alignment: Alignment.center,
              child: Text(
                _currentFloor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 6F の座席データを初期生成する（個人情報なし・占有/空席の2状態のみ）。
/// _floor6FItems の中で type が seat のアイテムの並び順と対応させる。
List<SeatInfo> _buildInitial6FSeats() {
  final List<SeatInfo> seats = [];

  // 左側のグループ席（7席・ESP32センサーで実際に管理、seat_01〜seat_07）
  // 最大4人まで利用可能なグループ席。
  for (int i = 1; i <= 7; i++) {
    seats.add(SeatInfo(
      name: 'グループ席 A-$i',
      amenities: i % 2 == 0 ? ['窓際', '電源'] : ['電源'],
      capacity: 4,
      isOccupied: false, // センサーが反応するまでは空席として表示する
    ));
  }

  // 中央のグループ席テーブル（5行 x 7列 = 35席）。最大2人まで利用可能。
  for (int r = 1; r <= 5; r++) {
    for (int c = 1; c <= 7; c++) {
      seats.add(SeatInfo(
        name: 'グループ席 B-$r-$c',
        amenities: const ['グループ利用可'],
        capacity: 2,
        isOccupied: false,
      ));
    }
  }

  // 右側の個人学習席（4席）。1人用。
  for (int i = 1; i <= 4; i++) {
    seats.add(SeatInfo(
      name: '個人学習席 $i',
      amenities: const ['ソファ席', '電源'],
      capacity: 1,
      isOccupied: false,
    ));
  }

  // グリッド下のグループ席(2卓)。最大10人程度まで利用可能な大型テーブル。
  // 見た目上は3区画ずつの横長テーブルだが、3つで1つの席として扱う。
  for (int i = 1; i <= 2; i++) {
    seats.add(SeatInfo(
      name: 'グループ席 C-$i',
      amenities: const ['大人数向け'],
      capacity: 10,
      isOccupied: false,
    ));
  }

  return seats;
}

/// フロアマップのスケルトン（ローディング時の薄いプレースホルダー）
/// 実際のフロア（_floor6FItems / _floor9FItems）のシルエットを
/// 薄いグレーで表示することで、ローディング後にスムーズに実体へ繋がるようにする。
class _FloorMapSkeleton extends StatelessWidget {
  final String floor;
  const _FloorMapSkeleton({super.key, required this.floor});

  @override
  Widget build(BuildContext context) {
    final items = floor == '9F' ? floor9FItems : floor6FItems;
    final canvasSize = floor == '9F' ? const Size(792, 720) : const Size(980, 1550);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (viewportSize.width <= 0 || viewportSize.height <= 0) {
          return const SizedBox.expand();
        }

        // 実体表示時と同じロジックで全体フィットのスケールを計算する
        final scaleX = viewportSize.width / canvasSize.width;
        final scaleY = viewportSize.height / canvasSize.height;
        final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.95;

        final dx = (viewportSize.width - canvasSize.width * scale) / 2;
        final dy = (viewportSize.height - canvasSize.height * scale) / 2;

        return Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.white)),
            for (final item in items)
              Positioned(
                left: dx + item.x * scale,
                top: dy + item.y * scale,
                width: item.width * scale,
                height: item.height * scale,
                child: Container(
                  color: AppColors.gridGray.withOpacity(0.4),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// フロアマップの実体（座席配置などのレイアウト表示）
/// floor の値（'6F' / '9F'）に応じて中身を切り替える
///
/// InteractiveViewer でラップすることで、
///  - 横スクロール / 縦スクロール（ドラッグでパン）
///  - ピンチイン・ピンチアウトでのズームイン・ズームアウト
/// に対応している。
///
/// 表示開始時は、フロアマップ全体（canvasWidth x canvasHeight）が
/// 画面の表示エリアにちょうど収まるスケールを自動計算してセットする。
class _FloorMapContent extends StatefulWidget {
  final String floor;
  final List<SeatInfo>? seats; // 座席情報（9F の場合は null = 座席機能なし）
  final ValueChanged<FloorMapItem> onSeatTap;
  final int? mySeatIndex; // 自分が今座っている座席のインデックス(いなければnull)
  final bool isDisasterMode; // 災害用モードON/OFF

  const _FloorMapContent({
    super.key,
    required this.floor,
    required this.seats,
    required this.onSeatTap,
    this.mySeatIndex,
    this.isDisasterMode = false,
  });

  @override
  State<_FloorMapContent> createState() => _FloorMapContentState();
}

class _FloorMapContentState extends State<_FloorMapContent> {
  final TransformationController _controller = TransformationController();
  bool _isFitReady = false; // フィット計算が完了するまで何も描画しないためのフラグ
  Size? _lastFittedSize; // 直前にフィット計算を行ったビューポートサイズ

  // フィット計算で求めたスケールをここに保持し、InteractiveViewer の
  // minScale をこの値より必ず小さく設定する（後述の _fitToScreen 内で更新）。
  // これが固定値（例: 0.3）だと、小さい画面でフィットスケールがそれより
  // 小さくなった際に InteractiveViewer がスケールを minScale に
  // クランプしてしまい、中央寄せの平行移動と噛み合わずマップが
  // 見切れる・パンできなくなる不具合が起きるため、必ず動的に算出する。
  double _fitScale = 1.0;

  /// フロアごとのキャンバスサイズ（_FloorMapCanvas の canvasWidth/canvasHeight と一致させる）
  Size get _canvasSize => switch (widget.floor) {
        '9F' => const Size(792, 720),
        _ => const Size(980, 1550),
      };

  Widget _buildMapWidget() {
    return switch (widget.floor) {
      '9F' => _FloorMapCanvas(
          canvasWidth: _canvasSize.width,
          canvasHeight: _canvasSize.height,
          items: floor9FItems,
          seats: widget.seats, // 9F は null なので全てタップ不可表示になる
          onSeatTap: widget.onSeatTap,
          mySeatIndex: widget.mySeatIndex,
          isDisasterMode: widget.isDisasterMode,
        ),
      _ => _FloorMapCanvas(
          canvasWidth: _canvasSize.width,
          canvasHeight: _canvasSize.height,
          items: floor6FItems,
          seats: widget.seats,
          onSeatTap: widget.onSeatTap,
          mySeatIndex: widget.mySeatIndex,
          wallOutline: floor6FWallOutlines,
          isDisasterMode: widget.isDisasterMode,
        ),
    };
  }

  /// 表示可能エリア(viewportSize)にフロアマップ全体(_canvasSize)が
  /// ちょうど収まるスケールを計算し、中央寄せの変換行列をセットする。
  void _fitToScreen(Size viewportSize) {
    if (!mounted) return;
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    final canvas = _canvasSize;

    // 横・縦それぞれの縮小率を計算し、小さい方（=全体が必ず収まる方）を採用
    final scaleX = viewportSize.width / canvas.width;
    final scaleY = viewportSize.height / canvas.height;
    final rawScale = (scaleX < scaleY ? scaleX : scaleY) * 0.95; // 少し余白を持たせる
    // 極端に小さい/不正な値にならないよう下限を設ける
    final scale = rawScale > 0.001 ? rawScale : 0.001;

    // スケール後のサイズが表示エリアの中央に来るような平行移動量を計算
    final dx = (viewportSize.width - canvas.width * scale) / 2;
    final dy = (viewportSize.height - canvas.height * scale) / 2;

    final matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);

    _controller.value = matrix;
    _lastFittedSize = viewportSize;
    // InteractiveViewer の minScale をこのフィットスケールより必ず
    // 小さくするための基準値として保持する（build内で使用）。
    _fitScale = scale;

    if (!_isFitReady) {
      setState(() => _isFitReady = true);
    }
  }

  @override
  void didUpdateWidget(_FloorMapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // フロアが切り替わったら、フィット前の状態に戻して再計算する
    if (oldWidget.floor != widget.floor) {
      setState(() {
        _isFitReady = false;
        _lastFittedSize = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // 初回表示時・フロア切替直後・画面サイズが変わった場合に
        // 全体フィットを(再)計算する。
        // build中に直接setStateやcontroller更新をすると例外になるため
        // addPostFrameCallbackでフレーム確定後に実行する。
        final needsFit = _lastFittedSize == null ||
            (_lastFittedSize!.width - viewportSize.width).abs() > 0.5 ||
            (_lastFittedSize!.height - viewportSize.height).abs() > 0.5;

        if (needsFit) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitToScreen(viewportSize);
          });
        }

        // フィット計算が完了するまでは何も描画しない。
        // InteractiveViewer自体をツリーに含めないことで、
        // スケール未調整の状態（左上の一部が拡大されたような見た目、
        // あるいは古いレイアウトの残像）が一瞬でも表示されることを防ぐ。
        if (!_isFitReady) {
          return const SizedBox.expand();
        }

        return ClipRect(
          child: InteractiveViewer(
            transformationController: _controller,
            // ★最重要: constrained: false にする。
            // デフォルト(true)では、InteractiveViewer は child を
            // 「画面の表示領域(viewport)のサイズに強制的に合わせて」
            // レイアウトしてしまう。つまり _FloorMapCanvas が指定した
            // 747x687 / 792x720 という実サイズが無視され、画面サイズ
            // （スマホでは393dp程度など）に押し込められてしまい、
            // Stack のデフォルトクリップ挙動によって画面幅を超える
            // 右側の座席・設備がすべて見えなくなっていた。
            // これが「PCの大きい画面では問題ないが、スマホや
            // 小さいウィンドウでは要素が欠落する」という現象の原因。
            // constrained: false にすると、InteractiveViewer は
            // child本来のサイズ(canvasWidth x canvasHeight)をそのまま
            // 使うようになり、表示領域より大きい分はズーム・パンで
            // 見せる、という今回やりたい動作に正しく合致する。
            constrained: false,
            // パン（ドラッグでの横・縦スクロール）を有効化
            panEnabled: true,
            // ピンチでのズームイン・ズームアウトを有効化
            scaleEnabled: true,
            // minScale は「フィット時のスケール」より必ず小さい値にする。
            // 固定値（例: 0.3）にしていると、画面が小さい（スマホの
            // エミュレータや、Chromeでウィンドウを縮めた場合など）で
            // フィットスケールがその固定値を下回った際に、
            // InteractiveViewer が表示スケールを minScale まで
            // 強制的に引き上げてしまい、_fitToScreen で計算した
            // 中央寄せの平行移動と噛み合わなくなって
            // マップが見切れる・正しくパンできない不具合が発生していた。
            // フィットスケールの半分を minScale にすることで、
            // どんな画面サイズでもフィット時の表示はクランプされず、
            // かつそこからさらにズームアウトもできるようにする。
            minScale: (_fitScale / 2).clamp(0.01, 1.0),
            maxScale: _fitScale * 4,
            // constrained: false の場合、boundaryMargin は
            // 「child(canvasSize)の外側にどれだけ余白を許すか」を
            // 表す。ズームアウトしてもキャンバスの端が見えなくなら
            // ないよう、画面サイズ分の余白を確保しておく。
            boundaryMargin: EdgeInsets.symmetric(
              horizontal: viewportSize.width,
              vertical: viewportSize.height,
            ),
            child: _buildMapWidget(),
          ),
        );
      },
    );
  }
}

/// フロアマップ上の1要素（座席・設備・ラベルなど）の配置情報
/// x, y, width, height は元画像のピクセル座標そのまま使う。
///
/// type が seat の場合のみタップ可能で、seatIndex で対応する
/// SeatInfo（着席状態・アメニティ）を参照する。
class FloorMapItem {
  final double x;
  final double y;
  final double width;
  final double height;
  final String? label; // 「入口」のようなテキストラベルがある場合に指定
  final FloorItemType type;
  final int? seatIndex; // type が seat の場合の、対応する SeatInfo リスト内インデックス

  const FloorMapItem({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.label,
    this.type = FloorItemType.facility,
    this.seatIndex,
  });
}

/// =========================================================
/// 災害用モード（フェーズフリー機能）
///
/// 既存座席の一部を「かまどベンチ」として指定し、災害用モード中は
/// 色を変えて表示する。タップすると使い方（テキスト＋画像）を表示する。
///
/// 対象にしたい座席が決まったら、下の kamadoBenchInfoBySeatIndex の
/// キー（seatIndex）を変更してください。seatIndexは floor6FItems 内の
/// 各 FloorMapItem のコメントを参照してください。
/// =========================================================
class KamadoBenchInfo {
  final String title;
  // assets フォルダに置いた画像のパス（例: 'assets/kamado/kamado_1.png'）。
  // pubspec.yaml の flutter: assets: に登録が必要。
  // まだ画像を用意していない場合は null のままでよい（アイコン表示になる）。
  final String? imageAssetPath;
  final List<String> usageSteps; // A. かまどを使用する（手順）
  final List<String> storageSteps; // B. ユニットベンチを収納する（手順）
  final List<String> cautions; // 使用上の注意

  const KamadoBenchInfo({
    required this.title,
    this.imageAssetPath,
    required this.usageSteps,
    required this.storageSteps,
    required this.cautions,
  });
}

// 防災かまどベンチ（コトブキ製）の取扱説明書に基づく標準の手順・注意事項。
// 複数のかまどベンチで同じ内容を使い回すための共通定数。
const List<String> _kamadoStandardUsageSteps = [
  '安全のため、作業は必ず2人以上でおこなってください。専用レンチを準備します。',
  '専用レンチでビスをゆるめ、上部のユニットベンチ（座面）を取り外します。',
  'ユニットベンチの補助脚を引き出します。',
  '内部の風防・炭置きパネルを確認し、風防はSフックでグリルに掛け、炭置きはグリルの下にセットします。',
  '炭置きの上に炭をセットして着火し、グリルの上に鍋・やかんを置いて調理します（設置場所が砂・土でない場合はレンガ等を敷いてから加熱してください）。',
];

const List<String> _kamadoStandardStorageSteps = [
  'グリルの上に風防・炭置きパネルを重ねて収納し、その上にSフックを置きます。',
  'ユニットベンチ（座面）は補助脚を折りたたんでから、脚を本体にセットします（脚をグリルの隙間に通してください）。',
  'ユニットベンチと本体を専用レンチ・ビスで固定して完成です。',
];

const List<String> _kamadoStandardCautions = [
  '加熱時は引火の恐れが無いように、製品の周りに十分なスペースを確保してください。',
  '設置場所が砂・土でない場合は、レンガ等を敷いた上で加熱をおこなってください。',
  '加熱後すぐに水をかけると製品が破損する恐れがあります。製品の温度が十分に下がってから清掃してください。',
  '消火後も製品はしばらく高温です。温度が下がるまで近づいたり、手を触れたりしないでください。',
];

// 暫定で、中央グリッドの数席をかまどベンチに指定しています。
// 実際にどの座席をかまどベンチにするか決まったら、
// このMapのキー（seatIndex）を変更してください。
const Map<int, KamadoBenchInfo> kamadoBenchInfoBySeatIndex = {
  7: KamadoBenchInfo(
    title: 'かまどベンチ 1',
    imageAssetPath: 'assets/kamado/kamado_1.png',
    usageSteps: _kamadoStandardUsageSteps,
    storageSteps: _kamadoStandardStorageSteps,
    cautions: _kamadoStandardCautions,
  ),
  8: KamadoBenchInfo(
    title: 'かまどベンチ 2',
    imageAssetPath: 'assets/kamado/kamado_2.png',
    usageSteps: _kamadoStandardUsageSteps,
    storageSteps: _kamadoStandardStorageSteps,
    cautions: _kamadoStandardCautions,
  ),
};

/// 「フロアマップ.png」(実際の図書館フロア図)を元にした座標データ。
///
/// 個人学習席(7)→グループ席グリッド(42)→個人学習ソファー(4) の順に
/// seatIndex を割り振り、_buildInitial6FSeats() の生成順と対応させている。
/// 実際にESP32センサーで着席検知できるのは個人学習席(seatIndex 0-6, seat_01〜07)のみ。
/// それ以外(グループ席・ソファー)はアプリ上でタップして手動チェックインする
/// 仮想の座席として扱う。
///
/// 注記: 座標は画像を目視で概算した値のため、実機で確認しながら
/// 微調整が必要な場合があります。スクリーンショットを送ってもらえれば調整します。
const List<FloorMapItem> floor6FItems = [
  // --- 左側の個人学習席（7個・ESP32センサー対応） seatIndex 0-6 ---
  FloorMapItem(x: 175, y: 275, width: 65, height: 65, type: FloorItemType.seat, seatIndex: 0),
  FloorMapItem(x: 175, y: 365, width: 65, height: 65, type: FloorItemType.seat, seatIndex: 1),
  FloorMapItem(x: 175, y: 455, width: 65, height: 65, type: FloorItemType.seat, seatIndex: 2),
  FloorMapItem(x: 175, y: 545, width: 65, height: 65, type: FloorItemType.seat, seatIndex: 3),
  FloorMapItem(x: 175, y: 635, width: 65, height: 65, type: FloorItemType.seat, seatIndex: 4),
  FloorMapItem(x: 175, y: 725, width: 65, height: 65, type: FloorItemType.seat, seatIndex: 5),
  FloorMapItem(x: 175, y: 810, width: 65, height: 65, type: FloorItemType.seat, seatIndex: 6),

  // --- 中央のグループ席テーブル（7列 x 6行 = 42個・アプリ内タップで手動チェックイン） seatIndex 7-48 ---
  FloorMapItem(x: 300, y: 370, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 7),
  FloorMapItem(x: 375, y: 370, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 8),
  FloorMapItem(x: 450, y: 370, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 9),
  FloorMapItem(x: 525, y: 370, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 10),
  FloorMapItem(x: 600, y: 370, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 11),
  FloorMapItem(x: 675, y: 370, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 12),
  FloorMapItem(x: 750, y: 370, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 13),

  FloorMapItem(x: 300, y: 450, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 14),
  FloorMapItem(x: 375, y: 450, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 15),
  FloorMapItem(x: 450, y: 450, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 16),
  FloorMapItem(x: 525, y: 450, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 17),
  FloorMapItem(x: 600, y: 450, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 18),
  FloorMapItem(x: 675, y: 450, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 19),
  FloorMapItem(x: 750, y: 450, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 20),

  FloorMapItem(x: 300, y: 530, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 21),
  FloorMapItem(x: 375, y: 530, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 22),
  FloorMapItem(x: 450, y: 530, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 23),
  FloorMapItem(x: 525, y: 530, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 24),
  FloorMapItem(x: 600, y: 530, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 25),
  FloorMapItem(x: 675, y: 530, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 26),
  FloorMapItem(x: 750, y: 530, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 27),

  FloorMapItem(x: 300, y: 610, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 28),
  FloorMapItem(x: 375, y: 610, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 29),
  FloorMapItem(x: 450, y: 610, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 30),
  FloorMapItem(x: 525, y: 610, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 31),
  FloorMapItem(x: 600, y: 610, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 32),
  FloorMapItem(x: 675, y: 610, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 33),
  FloorMapItem(x: 750, y: 610, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 34),

  FloorMapItem(x: 300, y: 690, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 35),
  FloorMapItem(x: 375, y: 690, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 36),
  FloorMapItem(x: 450, y: 690, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 37),
  FloorMapItem(x: 525, y: 690, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 38),
  FloorMapItem(x: 600, y: 690, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 39),
  FloorMapItem(x: 675, y: 690, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 40),
  FloorMapItem(x: 750, y: 690, width: 30, height: 30, type: FloorItemType.seat, seatIndex: 41),

  // --- 個人学習ソファー（4個） seatIndex 42-45 ---
  FloorMapItem(x: 810, y: 430, width: 45, height: 45, type: FloorItemType.seat, seatIndex: 42),
  FloorMapItem(x: 810, y: 490, width: 45, height: 45, type: FloorItemType.seat, seatIndex: 43),
  FloorMapItem(x: 810, y: 550, width: 45, height: 45, type: FloorItemType.seat, seatIndex: 44),
  FloorMapItem(x: 810, y: 610, width: 45, height: 45, type: FloorItemType.seat, seatIndex: 45),

  // --- グリッド下の個人学習テーブル（2卓、各3区画） seatIndex 46-47 ---
  // 見た目は3枚の横長パーツだが、同じseatIndexを共有させることで
  // 「3区画で1つのテーブル」としてどこをタップしても同じ席として扱われる。
  FloorMapItem(x: 265, y: 895, width: 175, height: 28, type: FloorItemType.seat, seatIndex: 46),
  FloorMapItem(x: 265, y: 940, width: 175, height: 28, type: FloorItemType.seat, seatIndex: 46),
  FloorMapItem(x: 265, y: 985, width: 175, height: 28, type: FloorItemType.seat, seatIndex: 46),
  FloorMapItem(x: 530, y: 895, width: 175, height: 28, type: FloorItemType.seat, seatIndex: 47),
  FloorMapItem(x: 530, y: 940, width: 175, height: 28, type: FloorItemType.seat, seatIndex: 47),
  FloorMapItem(x: 530, y: 985, width: 175, height: 28, type: FloorItemType.seat, seatIndex: 47),

  // --- ここから下はタップ不可の設備・ラベル ---
  FloorMapItem(x: 355, y: 55, width: 110, height: 90, label: '階段', type: FloorItemType.label),
  FloorMapItem(x: 345, y: 180, width: 300, height: 55, label: '受付カウンター', type: FloorItemType.facility),
  FloorMapItem(x: 735, y: 230, width: 40, height: 90, label: '出入口', type: FloorItemType.label),
  FloorMapItem(x: 805, y: 700, width: 110, height: 170, label: 'ソファコーナー', type: FloorItemType.facility),
  FloorMapItem(x: 825, y: 955, width: 60, height: 230, label: '支援\nカウンター', type: FloorItemType.facility),
  FloorMapItem(x: 30, y: 540, width: 90, height: 90, label: '検索端末', type: FloorItemType.facility),
  FloorMapItem(x: 30, y: 690, width: 90, height: 90, label: '自動貸出\n返却機', type: FloorItemType.facility),
  FloorMapItem(x: 170, y: 1010, width: 120, height: 130, label: '倉庫', type: FloorItemType.facility),
  FloorMapItem(x: 310, y: 1035, width: 90, height: 90, label: '検索端末', type: FloorItemType.facility),
  FloorMapItem(x: 440, y: 1195, width: 110, height: 210, label: 'メディア\nデーク', type: FloorItemType.facility),
  FloorMapItem(x: 825, y: 1215, width: 90, height: 90, label: '検索端末', type: FloorItemType.facility),
  FloorMapItem(x: 725, y: 1275, width: 90, height: 90, label: '自動貸出\n返却機', type: FloorItemType.facility),
  FloorMapItem(x: 650, y: 1430, width: 100, height: 90, label: '出入口', type: FloorItemType.label),
];

/// 9Fimage.png から実測した座標データ
/// 左から3列の座席エリア（各7個）+ 右側の受付/棚/小型設備群 + 入口ラベル
///
/// 9F は座席の着席/退席機能を持たない（要件により見た目のみ）ため、
/// 全アイテムを facility / label として扱い、タップ不可にしている。
const List<FloorMapItem> floor9FItems = [
  // --- 左列（7個） ---
  FloorMapItem(x: 159, y: 121, width: 59, height: 39),
  FloorMapItem(x: 159, y: 191, width: 59, height: 39),
  FloorMapItem(x: 159, y: 260, width: 59, height: 40),
  FloorMapItem(x: 159, y: 330, width: 59, height: 40),
  FloorMapItem(x: 159, y: 400, width: 59, height: 39),
  FloorMapItem(x: 159, y: 470, width: 59, height: 39),
  FloorMapItem(x: 159, y: 540, width: 59, height: 39),

  // --- 中央列（7個） ---
  FloorMapItem(x: 304, y: 121, width: 58, height: 39),
  FloorMapItem(x: 304, y: 191, width: 58, height: 39),
  FloorMapItem(x: 304, y: 260, width: 58, height: 40),
  FloorMapItem(x: 304, y: 330, width: 58, height: 40),
  FloorMapItem(x: 304, y: 400, width: 58, height: 39),
  FloorMapItem(x: 304, y: 470, width: 58, height: 39),
  FloorMapItem(x: 304, y: 540, width: 58, height: 39),

  // --- 右寄りの列（7個） ---
  FloorMapItem(x: 448, y: 120, width: 59, height: 40),
  FloorMapItem(x: 448, y: 190, width: 59, height: 40),
  FloorMapItem(x: 448, y: 260, width: 59, height: 40),
  FloorMapItem(x: 448, y: 330, width: 59, height: 40),
  FloorMapItem(x: 448, y: 400, width: 59, height: 39),
  FloorMapItem(x: 448, y: 469, width: 59, height: 40),
  FloorMapItem(x: 448, y: 539, width: 59, height: 40),

  // --- 右上の大きい矩形（受付や設備など） ---
  FloorMapItem(x: 580, y: 121, width: 78, height: 59),

  // --- 右側の縦長2個（棚・パーティションなど） ---
  FloorMapItem(x: 638, y: 191, width: 20, height: 78),
  FloorMapItem(x: 638, y: 273, width: 20, height: 77),

  // --- 右下の小さい設備群（9個） ---
  FloorMapItem(x: 638, y: 362, width: 20, height: 20),
  FloorMapItem(x: 615, y: 386, width: 20, height: 20),
  FloorMapItem(x: 638, y: 386, width: 20, height: 20),
  FloorMapItem(x: 638, y: 409, width: 20, height: 20),
  FloorMapItem(x: 638, y: 433, width: 20, height: 20),
  FloorMapItem(x: 638, y: 457, width: 20, height: 20),
  FloorMapItem(x: 615, y: 501, width: 20, height: 20),
  FloorMapItem(x: 638, y: 501, width: 20, height: 20),
  FloorMapItem(x: 628, y: 525, width: 20, height: 20),

  // --- 入口ラベル ---
  FloorMapItem(x: 567, y: 635, width: 91, height: 42, label: '入口', type: FloorItemType.label),
];

/// 座標リスト（FloorMapItem）を実際のキャンバス上に配置して描画するウィジェット。
/// Stack + Positioned で、画像から実測したピクセル座標をそのまま使用する。
///
/// seats が渡されている場合、type が seat のアイテムには
/// 対応する SeatInfo の状態（空席=白／使用中=赤）を反映し、タップで
/// onSeatTap を呼び出す。seats が null（9F など）の場合は全てタップ不可。
class _FloorMapCanvas extends StatelessWidget {
  final double canvasWidth;
  final double canvasHeight;
  final List<FloorMapItem> items;
  final List<SeatInfo>? seats;
  final ValueChanged<FloorMapItem> onSeatTap;
  final int? mySeatIndex;
  final List<_WallPath>? wallOutline; // フロア外形線(壁)+内側の仕切り線。無ければ描画しない。
  final bool isDisasterMode;

  const _FloorMapCanvas({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.items,
    required this.seats,
    required this.onSeatTap,
    this.mySeatIndex,
    this.wallOutline,
    this.isDisasterMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        children: [
          // 背景
          // ※ ズームアウトした際にキャンバスの境界が「灰色の箱」として
          //    浮いて見えてしまうため、ページ全体の背景と同じ白にしている
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          // 壁の輪郭線(青いライン)。実際のフロアマップ画像の外形を再現する。
          if (wallOutline != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _FloorWallPainter(wallOutline!),
              ),
            ),
          // 各アイテム（座席・設備・ラベル）を座標通りに配置
          for (final item in items)
            Positioned(
              left: item.x,
              top: item.y,
              width: item.width,
              height: item.height,
              child: _FloorMapItemView(
                item: item,
                seat: (seats != null && item.seatIndex != null && item.seatIndex! < seats!.length)
                    ? seats![item.seatIndex!]
                    : null,
                onTap: () => onSeatTap(item),
                isMine: item.seatIndex != null && item.seatIndex == mySeatIndex,
                isDisasterMode: isDisasterMode,
                kamadoBenchInfo:
                    item.seatIndex != null ? kamadoBenchInfoBySeatIndex[item.seatIndex] : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// 個々のアイテム（座席 / 設備 / ラベル）の見た目。
/// 座席は状態に応じて色が変わり、タップ可能。
class _FloorMapItemView extends StatelessWidget {
  final FloorMapItem item;
  final SeatInfo? seat;
  final VoidCallback onTap;
  final bool isMine; // 自分が今チェックインしている座席かどうか
  final bool isDisasterMode;
  final KamadoBenchInfo? kamadoBenchInfo;

  const _FloorMapItemView({
    required this.item,
    required this.seat,
    required this.onTap,
    this.isMine = false,
    this.isDisasterMode = false,
    this.kamadoBenchInfo,
  });

  @override
  Widget build(BuildContext context) {
    final bool isKamadoBench = kamadoBenchInfo != null;

    // 座席かつ対応する SeatInfo がある場合のみタップ可能・状態色を反映する。
    // 災害用モード中は「かまどベンチだけ」がタップ可能になる。
    final bool isTappableSeat = isDisasterMode
        ? (item.type == FloorItemType.seat && isKamadoBench)
        : (item.type == FloorItemType.seat && seat != null);

    Color fillColor;
    Color? borderColor;
    double borderWidth = 1;

    if (isDisasterMode) {
      if (item.type == FloorItemType.seat && isKamadoBench) {
        // かまどベンチはオレンジ色で目立たせる
        fillColor = Colors.orange;
        borderColor = Colors.deepOrange;
      } else if (item.type == FloorItemType.seat) {
        // かまどベンチ以外の座席は、災害用モード中はグレーアウトする
        fillColor = Colors.grey.shade300;
        borderColor = Colors.grey.shade400;
      } else {
        fillColor = AppColors.gridGray;
        borderColor = null;
      }
    } else if (isTappableSeat) {
      if (seat!.isProhibited) {
        fillColor = Colors.grey.shade400; // 禁止時はグレー
        borderColor = Colors.grey.shade600;
      } else {
        fillColor = seat!.isOccupied ? AppColors.seatOccupied : AppColors.seatVacant;
        borderColor = seat!.isOccupied ? AppColors.seatOccupiedBorder : AppColors.seatVacantBorder;
      }
    } else {
      fillColor = AppColors.gridGray;
      borderColor = null;
    }

    // 自分の席には、状態色(空席/使用中/禁止)はそのままに、目立つ青枠を上乗せする
    // （災害用モード中は自分の席の強調表示はしない）
    if (isMine && !isDisasterMode) {
      borderColor = const Color(0xFF1565FF);
      borderWidth = 3;
    }

    final content = Container(
      decoration: BoxDecoration(
        color: fillColor,
        border: borderColor != null ? Border.all(color: borderColor, width: borderWidth) : null,
      ),
      alignment: Alignment.center,
      child: item.label != null
          ? Text(
              item.label!,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            )
          : null,
    );

    // 自分の席の右上に小さな目印(自分アイコン)を重ねて表示する
    // （災害用モード中は非表示）
    final displayContent = (isMine && !isDisasterMode)
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              content,
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 11, color: Colors.white),
                ),
              ),
            ],
          )
        : content;

    if (!isTappableSeat) {
      return displayContent;
    }

    return GestureDetector(
      onTap: onTap,
      child: displayContent,
    );
  }
}

/// 災害用モード：かまどベンチの使い方を表示するボトムシート
class KamadoBenchDetailSheet extends StatelessWidget {
  final KamadoBenchInfo info;

  const KamadoBenchDetailSheet({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    info.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 使い方の画像。assets未登録・ファイル未配置の場合はアイコン表示にフォールバックする
              if (info.imageAssetPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    info.imageAssetPath!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _KamadoSection(
                heading: 'A. かまどを使用する',
                steps: info.usageSteps,
                headingColor: Colors.orange.shade800,
              ),
              const SizedBox(height: 20),
              _KamadoSection(
                heading: 'B. ユニットベンチを収納する（使用後）',
                steps: info.storageSteps,
                headingColor: Colors.blueGrey.shade700,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '使用上の注意',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final caution in info.cautions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '・$caution',
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// KamadoBenchDetailSheet内の「見出し＋番号付き手順」を表示する共通パーツ
class _KamadoSection extends StatelessWidget {
  final String heading;
  final List<String> steps;
  final Color headingColor;

  const _KamadoSection({
    required this.heading,
    required this.steps,
    required this.headingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: headingColor),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: headingColor, shape: BoxShape.circle),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// =========================================================
/// 座席詳細ボトムシート（memo.dart の SeatDetailDialog を簡略化）
/// 人名・部署名などの個人情報は表示せず、座席自体の情報のみを表示する。
/// =========================================================
class SeatDetailSheet extends StatelessWidget {
  final SeatInfo seat;

  const SeatDetailSheet({
    super.key,
    required this.seat,
  });

  @override
  Widget build(BuildContext context) {
    final isMeeting = seat.name.startsWith('会議室');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMeeting ? '共有スペース' : '個別ワークスペース',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.seatOccupiedBorder.withOpacity(0.9),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              seat.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSpecRow(
                    '利用状態',
                    seat.isOccupied ? '使用中 🔴' : '空席 🟢',
                  ),
                  const Divider(),
                  _buildSpecRow('座れる人数', '${seat.capacity}人'),
                  const Divider(),
                  _buildSpecRow('電源 (コンセント)', seat.hasPower ? 'あり 🔌' : 'なし ✕'),
                  const Divider(),
                  _buildSpecRow(
                    '主なアメニティ',
                    seat.amenities.isEmpty ? '特になし' : seat.amenities.join(', '),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// =========================================================
/// 3. ドロワー（ハンバーガーメニュー）
/// 1階層目: 「フロア選択」「使い方」 ヘッダーは × ボタン
/// 2階層目（フロア選択タップ後）: 「6F」「9F」一覧 ヘッダーは ← ボタン
/// AnimatedSwitcher で階層間をスライド切り替え
/// =========================================================
class FloorDrawer extends StatefulWidget {
  final String currentFloor;
  final ValueChanged<String> onFloorSelected;

  const FloorDrawer({
    super.key,
    required this.currentFloor,
    required this.onFloorSelected,
  });

  @override
  State<FloorDrawer> createState() => _FloorDrawerState();
}

enum _DrawerView { menu, floorList }

class _FloorDrawerState extends State<FloorDrawer> {
  _DrawerView _view = _DrawerView.menu;

  void _openFloorList() {
    setState(() => _view = _DrawerView.floorList);
  }

  void _backToMenu() {
    setState(() => _view = _DrawerView.menu);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.mainGreen,
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // ヘッダー：× または ← で切り替え
            Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _view == _DrawerView.menu
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _backToMenu,
                    ),
            ),
            // 本体：AnimatedSwitcher でスライドしながら切り替え
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  final inSlide = Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: inSlide,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _view == _DrawerView.menu
                    ? _DrawerMenuList(
                        key: const ValueKey('menu'),
                        onFloorSelectTap: _openFloorList,
                      )
                    : _DrawerFloorList(
                        key: const ValueKey('floorList'),
                        currentFloor: widget.currentFloor,
                        onFloorTap: widget.onFloorSelected,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ドロワー：1階層目「フロア選択」「使い方」など
class _DrawerMenuList extends StatelessWidget {
  final VoidCallback onFloorSelectTap;

  const _DrawerMenuList({super.key, required this.onFloorSelectTap});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウトしますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().signOut();
      // ログアウトするとFirebaseの認証状態が変わり、main.dartのAuthGateが
      // 自動的にLoginPageへ切り替えてくれるので、ここで手動遷移する必要はない。
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _DrawerItem(label: 'フロア選択', onTap: onFloorSelectTap),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(
          label: '使い方',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HowToUsePage()),
            );
          },
        ),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(
          label: 'プロフィール',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(
          label: 'アプリについて',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            );
          },
        ),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(
          label: 'フィードバック',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FeedbackPage()),
            );
          },
        ),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(
          label: '利用規約・プライバシーポリシー',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsPage()),
            );
          },
        ),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(
          label: 'ログアウト',
          onTap: () => _confirmLogout(context),
        ),
      ],
    );
  }
}

/// ドロワー：2階層目「6F」「9F」一覧
class _DrawerFloorList extends StatelessWidget {
  final String currentFloor;
  final ValueChanged<String> onFloorTap;

  const _DrawerFloorList({
    super.key,
    required this.currentFloor,
    required this.onFloorTap,
  });

  @override
  Widget build(BuildContext context) {
    const floors = ['6F', '9F'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final floor in floors) ...[
          _DrawerItem(
            label: floor,
            selected: floor == currentFloor,
            onTap: () => onFloorTap(floor),
          ),
        ],
      ],
    );
  }
}

/// ドロワー共通の項目（タップでハイライトする薄緑の背景）
class _DrawerItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lightGreen : AppColors.mainGreen,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.lightGreen,
        highlightColor: AppColors.lightGreen,
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}