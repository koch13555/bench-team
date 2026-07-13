import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'firebase_options.dart'; // firebase設定ファイル
import 'checkin_page.dart';
import 'friend_screen.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  // プロフィールアイコン
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.grey,
                    ),
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
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // OIT梅田キャンパス（タップでフロア選択へ）
                                _CampusCard(
                                  name: 'OIT 梅田キャンパス',
                                  subtitle: 'Umeda Campus',
                                  isFavorite: true,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        transitionDuration: Duration.zero,
                                        reverseTransitionDuration: Duration.zero,
                                        pageBuilder: (_, __, ___) =>
                                            const FloorSelectPage(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _CampusCard(
                                  name: 'OIT 枚方キャンパス',
                                  subtitle: 'Hirakata Campus',
                                ),
                                const SizedBox(height: 12),
                                _CampusCard(
                                  name: 'OIT 大宮キャンパス',
                                  subtitle: 'Omiya Campus',
                                ),
                                const SizedBox(height: 12),
                                _CampusCard(
                                  name: 'ユニバーサルスタジオジャパン',
                                  subtitle: 'USJ',
                                ),
                                const SizedBox(height: 12),
                                _CampusCard(
                                  name: 'テストキャンパスA',
                                  subtitle: 'Dummy A',
                                ),
                                const SizedBox(height: 12),
                                _CampusCard(
                                  name: 'テストキャンパスB',
                                  subtitle: 'Dummy B',
                                ),
                              ],
                            ),
                          ),
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendScreen()),
                  );
                },
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

class _CampusCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback? onTap;

  const _CampusCard({
    required this.name,
    required this.subtitle,
    this.isFavorite = false,
    this.onTap,
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
            if (isFavorite)
              const Positioned(
                top: 0,
                left: 0,
                child: Text('★', style: TextStyle(color: Colors.amber, fontSize: 18)),
              ),
            Column(
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
                ),
              ],
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

/// フロアマップ上の1要素（座席・設備など）の種別
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

  // --- 自分が今どの座席にいるか(user_locations)をリアルタイム監視する処理 ---
  void _listenToMyLocation() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://bench-team-app-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

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
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://bench-team-app-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    
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
  void _handleSeatTap(FloorMapItem item) {
    final seats = _seatsByFloor[_currentFloor];
    if (seats == null) return;
    final seatIndex = item.seatIndex;
    if (seatIndex == null || seatIndex >= seats.length) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final seat = seats[seatIndex];
            return SeatDetailSheet(
              seat: seat,
              onToggleOccupied: () {
                setState(() {
                  seat.isOccupied = !seat.isOccupied;
                });
                setSheetState(() {});
              },
            );
          },
        );
      },
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
      bottomNavigationBar: Container(
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
            Column(
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
            Column(
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
          ],
        ),
      ),
      // ↑ここまで追加
      
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（ハンバーガーメニュー）
            Container(
              width: double.infinity,
              height: 48,
              color: AppColors.mainGreen,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
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

  // 左側の列（7席）
  for (int i = 1; i <= 7; i++) {
    seats.add(SeatInfo(
      name: 'デスク A-$i',
      amenities: i % 2 == 0 ? ['窓際', '電源', 'デュアルモニター'] : ['電源'],
      capacity: 1,
      isOccupied: (i * 4 + 3) % 7 == 0 || (i * 4 + 4) % 9 == 0,
    ));
  }

  // 中央グリッド（5行 x 7列 = 35席）
  for (int r = 1; r <= 5; r++) {
    for (int c = 1; c <= 7; c++) {
      final idx = (r - 1) * 7 + c;
      seats.add(SeatInfo(
        name: 'デスク B-$r-$c',
        amenities: c == 1 || c == 7 ? ['通路側', '電源'] : ['電源', 'モニター設置'],
        capacity: 1,
        isOccupied: (idx * 2 + 3) % 7 == 0 || (idx * 2 + 4) % 9 == 0,
      ));
    }
  }

  // 右側の列（4席）
  for (int i = 1; i <= 4; i++) {
    seats.add(SeatInfo(
      name: 'デスク C-$i',
      amenities: const ['高セキュリティ', '電源', '静音エリア'],
      capacity: 1,
      isOccupied: (i * 5 + 3) % 7 == 0 || (i * 5 + 4) % 9 == 0,
    ));
  }

  // 下部の会議室（2室）
  seats.add(SeatInfo(
    name: '会議室 Meeting A',
    amenities: const ['モニター', 'プロジェクター', 'ホワイトボード', 'テレビ会議システム'],
    capacity: 8,
    isOccupied: false,
  ));
  seats.add(SeatInfo(
    name: '会議室 Meeting B',
    amenities: const ['大型ディスプレイ', '電子黒板', 'マイクスピーカー'],
    capacity: 10,
    isOccupied: true,
  ));

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
    final canvasSize = floor == '9F' ? const Size(792, 720) : const Size(747, 687);

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

  const _FloorMapContent({
    super.key,
    required this.floor,
    required this.seats,
    required this.onSeatTap,
    this.mySeatIndex,
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
        _ => const Size(747, 687),
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
        ),
      _ => _FloorMapCanvas(
          canvasWidth: _canvasSize.width,
          canvasHeight: _canvasSize.height,
          items: floor6FItems,
          seats: widget.seats,
          onSeatTap: widget.onSeatTap,
          mySeatIndex: widget.mySeatIndex,
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

/// 6Fimage.png から実測した座標データ
/// （画像を背景差分で解析し、各矩形のx, y, width, heightを抽出したもの）
///
/// 左列(7)→中央グリッド(35)→右列(4)→会議室(2) の順に
/// seatIndex を割り振り、_buildInitial6FSeats() の生成順と対応させている。
const List<FloorMapItem> floor6FItems = [
  // --- 左側の縦に並んだ列（7個・座席） seatIndex 0-6 ---
  FloorMapItem(x: 108, y: 120, width: 45, height: 25, type: FloorItemType.seat, seatIndex: 0),
  FloorMapItem(x: 108, y: 167, width: 45, height: 25, type: FloorItemType.seat, seatIndex: 1),
  FloorMapItem(x: 108, y: 213, width: 45, height: 26, type: FloorItemType.seat, seatIndex: 2),
  FloorMapItem(x: 108, y: 260, width: 45, height: 25, type: FloorItemType.seat, seatIndex: 3),
  FloorMapItem(x: 108, y: 307, width: 45, height: 25, type: FloorItemType.seat, seatIndex: 4),
  FloorMapItem(x: 108, y: 354, width: 45, height: 25, type: FloorItemType.seat, seatIndex: 5),
  FloorMapItem(x: 108, y: 401, width: 45, height: 25, type: FloorItemType.seat, seatIndex: 6),

  // --- 中央の座席グリッド（7列 x 5行 = 35個・座席） seatIndex 7-41 ---
  FloorMapItem(x: 216, y: 170, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 7),
  FloorMapItem(x: 260, y: 170, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 8),
  FloorMapItem(x: 305, y: 170, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 9),
  FloorMapItem(x: 349, y: 170, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 10),
  FloorMapItem(x: 394, y: 170, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 11),
  FloorMapItem(x: 438, y: 170, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 12),
  FloorMapItem(x: 482, y: 170, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 13),

  FloorMapItem(x: 216, y: 209, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 14),
  FloorMapItem(x: 260, y: 209, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 15),
  FloorMapItem(x: 305, y: 209, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 16),
  FloorMapItem(x: 349, y: 209, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 17),
  FloorMapItem(x: 394, y: 209, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 18),
  FloorMapItem(x: 438, y: 209, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 19),
  FloorMapItem(x: 482, y: 209, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 20),

  FloorMapItem(x: 216, y: 248, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 21),
  FloorMapItem(x: 260, y: 248, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 22),
  FloorMapItem(x: 305, y: 248, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 23),
  FloorMapItem(x: 349, y: 248, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 24),
  FloorMapItem(x: 394, y: 248, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 25),
  FloorMapItem(x: 438, y: 248, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 26),
  FloorMapItem(x: 482, y: 248, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 27),

  FloorMapItem(x: 216, y: 287, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 28),
  FloorMapItem(x: 260, y: 287, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 29),
  FloorMapItem(x: 305, y: 287, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 30),
  FloorMapItem(x: 349, y: 287, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 31),
  FloorMapItem(x: 394, y: 287, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 32),
  FloorMapItem(x: 438, y: 287, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 33),
  FloorMapItem(x: 482, y: 287, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 34),

  FloorMapItem(x: 216, y: 326, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 35),
  FloorMapItem(x: 260, y: 326, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 36),
  FloorMapItem(x: 305, y: 326, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 37),
  FloorMapItem(x: 349, y: 326, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 38),
  FloorMapItem(x: 394, y: 326, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 39),
  FloorMapItem(x: 438, y: 326, width: 25, height: 25, type: FloorItemType.seat, seatIndex: 40),
  FloorMapItem(x: 482, y: 326, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 41),

  // --- 右側の縦に並んだ小さい列（4個・座席） seatIndex 42-45 ---
  FloorMapItem(x: 615, y: 187, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 42),
  FloorMapItem(x: 615, y: 216, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 43),
  FloorMapItem(x: 615, y: 245, width: 26, height: 26, type: FloorItemType.seat, seatIndex: 44),
  FloorMapItem(x: 615, y: 275, width: 26, height: 25, type: FloorItemType.seat, seatIndex: 45),

  // --- 下部の会議室2つ（座席扱い） seatIndex 46-47 ---
  FloorMapItem(x: 219, y: 413, width: 89, height: 35, type: FloorItemType.seat, seatIndex: 46),
  FloorMapItem(x: 350, y: 413, width: 89, height: 35, type: FloorItemType.seat, seatIndex: 47),

  // --- 入口ラベル（タップ不可） ---
  FloorMapItem(x: 526, y: 519, width: 115, height: 53, label: '入口', type: FloorItemType.label),
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

  const _FloorMapCanvas({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.items,
    required this.seats,
    required this.onSeatTap,
    this.mySeatIndex,
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

  const _FloorMapItemView({
    required this.item,
    required this.seat,
    required this.onTap,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    // 座席かつ対応する SeatInfo がある場合のみタップ可能・状態色を反映する。
    final bool isTappableSeat = item.type == FloorItemType.seat && seat != null;

    Color fillColor;
    Color? borderColor;
    double borderWidth = 1;
    if (isTappableSeat) {
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
    if (isMine) {
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
    final displayContent = isMine
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

/// =========================================================
/// 座席詳細ボトムシート（memo.dart の SeatDetailDialog を簡略化）
/// 人名・部署名などの個人情報は表示せず、座席自体の情報のみを表示する。
/// =========================================================
class SeatDetailSheet extends StatelessWidget {
  final SeatInfo seat;
  final VoidCallback onToggleOccupied;

  const SeatDetailSheet({
    super.key,
    required this.seat,
    required this.onToggleOccupied,
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
            const SizedBox(height: 20),
            if (seat.isOccupied)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: null,
                icon: const Icon(Icons.block),
                label: const Text(
                  '現在アプリからは操作できません',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onToggleOccupied,
                icon: const Icon(Icons.check),
                label: const Text(
                  'この席を利用する',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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

/// ドロワー：1階層目「フロア選択」「使い方」
class _DrawerMenuList extends StatelessWidget {
  final VoidCallback onFloorSelectTap;

  const _DrawerMenuList({super.key, required this.onFloorSelectTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DrawerItem(label: 'フロア選択', onTap: onFloorSelectTap),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(label: '使い方', onTap: () {}),
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