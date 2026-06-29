import 'package:flutter/material.dart';

/// ===== カラーパレット =====
/// 元デザイン (すわほui-1.png) からピクセル抽出した値
class AppColors {
  static const Color mainGreen = Color(0xFF8DF172); // メインの緑
  static const Color lightGreen = Color(0xFFB3FF9E); // 薄い緑（ボタン・選択メニュー項目）
  static const Color bgGray = Color(0xFFF5F5F5); // ページ背景グレー
  static const Color gridGray = Color(0xFFD9D9D9); // フロアマップのグリッド
  static const Color overlayGray = Color(0xFFEBEBEB); // ドロワー表示時のコンテンツオーバーレイ
  static const Color skeletonGray = Color(0xFFE0E0E0); // ローディング用バー
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
        pageBuilder: (_, _, _) => FloorMapPage(floor: floor),
      ),
    );
  }
// lib/models.dart

class UserProfile {
  String name;
  String department;
  String until;

  UserProfile({required this.name, required this.department, required this.until});
}

class Occupant {
  String name;
  String department;
  String until;

  Occupant({required this.name, required this.department, required this.until});
}

class Floor {
  String id;
  String name;
  String description;
  String dept;

  Floor({required this.id, required this.name, required this.description, required this.dept});
}

class Seat {
  String id;
  String name;
  String type;
  String status; // 'vacant' or 'occupied'
  Occupant? occupiedBy;
  List<String> amenities;

  Seat({required this.id, required this.name, required this.type, required this.status, this.occupiedBy, required this.amenities});
}

// lib/mock_data.dart

final List<Occupant> mockOccupants = [
  Occupant(name: '佐藤 健二', department: '営業部', until: '17:00まで'),
  Occupant(name: '鈴木 美咲', department: '営業部', until: '15:30まで'),
  Occupant(name: '高橋 浩', department: '開発第一チーム', until: '18:00まで'),
  Occupant(name: '田中 葵', department: 'マーケティング部', until: '16:00まで'),
  Occupant(name: '伊藤 直人', department: 'カスタマーサクセス', until: '19:00まで'),
];

final List<Floor> floors = [
  Floor(
    id: '6f',
    name: '6階 ラーニングコモンズ',
    description: '6F - Learning Commons',
    dept: 'ラーニングコモンズ・学習支援スペース',
  ),
  Floor(
    id: '9f',
    name: '9階 フロアマップ',
    description: '9F - Floor Map',
    dept: '準備中',
  ),
];

bool _isOccupiedIndex(int index, int seed) {
  return (index * seed + 3) % 7 == 0 || (index * seed + 4) % 9 == 0;
}

List<Seat> generate6FSeats() {
  List<Seat> seats = [];

  // A列 (左側: 7デスク)
  for (int i = 1; i <= 7; i++) {
    bool isOccupied = _isOccupiedIndex(i, 4);
    Occupant? occupant = isOccupied ? mockOccupants[i % mockOccupants.length] : null;
    seats.add(Seat(
      id: '6f-left-$i',
      name: 'デスク A-$i',
      type: 'desk',
      status: isOccupied ? 'occupied' : 'vacant',
      occupiedBy: occupant,
      amenities: i % 2 == 0 ? ['窓際', '電源', 'デュアルモニター'] : ['電源'],
    ));
  }

  // B列 (中央グリッド: 5行x7列 = 35デスク)
  for (int r = 1; r <= 5; r++) {
    for (int c = 1; c <= 7; c++) {
      int idx = (r - 1) * 7 + c;
      bool isOccupied = _isOccupiedIndex(idx, 2);
      Occupant? occupant = isOccupied ? mockOccupants[idx % mockOccupants.length] : null;
      seats.add(Seat(
        id: '6f-center-$r-$c',
        name: 'デスク B-$r-$c',
        type: 'desk',
        status: isOccupied ? 'occupied' : 'vacant',
        occupiedBy: occupant,
        amenities: c == 1 || c == 7 ? ['通路側', '電源'] : ['電源', 'モニター設置'],
      ));
    }
  }

  // C列 (右側: 4デスク)
  for (int i = 1; i <= 4; i++) {
    bool isOccupied = _isOccupiedIndex(i, 5);
    Occupant? occupant = isOccupied ? mockOccupants[(i + 3) % mockOccupants.length] : null;
    seats.add(Seat(
      id: '6f-right-$i',
      name: 'デスク C-$i',
      type: 'desk',
      status: isOccupied ? 'occupied' : 'vacant',
      occupiedBy: occupant,
      amenities: ['高セキュリティ', '電源', '静音エリア'],
    ));
  }

  // 会議室 (下部)
  seats.add(Seat(
    id: '6f-meeting-a',
    name: '会議室 Meeting A (8名室)',
    type: 'meeting',
    status: 'vacant',
    amenities: ['モニター', 'プロジェクター', 'ホワイトボード', 'テレビ会議システム'],
  ));
  seats.add(Seat(
    id: '6f-meeting-b',
    name: '会議室 Meeting B (10名室)',
    type: 'meeting',
    status: 'occupied',
    occupiedBy: Occupant(
      name: 'プロダクト企画チーム会議',
      department: '営業推進チーム',
      until: '16:00まで',
    ),
    amenities: ['大型ディスプレイ', '電子黒板', 'マイクスピーカー'],
  ));

  return seats;
}

Map<String, List<Seat>> loadInitialSeats() {
  return {
    '6f': generate6FSeats(),
    '9f': [],
  };
}

final UserProfile mockUser = UserProfile(
  name: 'あなた（テストユーザー）',
  department: '営業推進チーム',
  until: '18:00',
);

// lib/main.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // グローバルな状態管理
  final Map<String, List<Seat>> _seats = loadInitialSeats();
  UserProfile _userProfile = UserProfile(
    name: mockUser.name,
    department: mockUser.department,
    until: mockUser.until,
  );

  void _updateSeat(String floorId, String seatId, bool setVacant) {
    setState(() {
      final floorSeats = _seats[floorId];
      if (floorSeats == null) return;
      
      final index = floorSeats.indexWhere((s) => s.id == seatId);
      if (index >= 0) {
        if (setVacant) {
          floorSeats[index].status = 'vacant';
          floorSeats[index].occupiedBy = null;
        } else {
          floorSeats[index].status = 'occupied';
          floorSeats[index].occupiedBy = Occupant(
            name: _userProfile.name,
            department: _userProfile.department,
            until: '利用中',
          );
        }
      }
    });
  }

  void _updateProfile(UserProfile newProfile) {
    setState(() {
      _userProfile = newProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEAT Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MainScreen(
        seats: _seats, 
        userProfile: _userProfile, 
        onUpdateSeat: _updateSeat,
        onUpdateProfile: _updateProfile,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Map<String, List<Seat>> seats;
  final UserProfile userProfile;
  final Function(String, String, bool) onUpdateSeat;
  final Function(UserProfile) onUpdateProfile;

  const MainScreen({
    super.key, 
    required this.seats, 
    required this.userProfile,
    required this.onUpdateSeat,
    required this.onUpdateProfile,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _activeFloorId = '6f';

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
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(6)),
              child: const Text('SEAT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Text('Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                        child: Text('SEAT', style: TextStyle(color: Colors.blue.shade600, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.userProfile.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ExpansionTile(
              leading: const Icon(Icons.business),
              title: const Text('フロア選択', style: TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: true,
              children: floors.map((f) => ListTile(
                contentPadding: const EdgeInsets.only(left: 48, right: 16),
                title: Text(f.id == '6f' ? '6F \${f.name}' : '9F \${f.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                selected: _currentIndex == 0 && _activeFloorId == f.id,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 0;
                    _activeFloorId = f.id;
                  });
                },
              )).toList(),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text('その他の機能', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('システム設定', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('フレンド', style: TextStyle(fontWeight: FontWeight.bold)),
              selected: _currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          FloorMapScreen(
            floor: floors.firstWhere((f) => f.id == _activeFloorId, orElse: () => floors[0]),
            seats: widget.seats[_activeFloorId] ?? [],
            userProfile: widget.userProfile,
            onUpdateSeat: widget.onUpdateSeat,
          ),
          SettingsScreen(
            profile: widget.userProfile,
            onProfileChanged: widget.onUpdateProfile,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.blue.shade200),
                const SizedBox(height: 16),
                const Text('フレンド機能は準備中です', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('同僚や友人を追加して、誰がどこに座っているか\n探す機能が今後実装される予定です。', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'フロアマップ'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '設定・管理'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'フレンド'),
        ],
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
// lib/screens/floor_map_screen.dart

class FloorMapScreen extends StatelessWidget {
  final Floor floor;
  final List<Seat> seats;
  final UserProfile userProfile;
  final Function(String, String, bool) onUpdateSeat;

  const FloorMapScreen({
    super.key,
    required this.floor,
    required this.seats,
    required this.userProfile,
    required this.onUpdateSeat,
  });

  void _handleSelectSeat(BuildContext context, Seat seat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeatDetailDialog(
        seat: seat,
        userProfile: userProfile,
        onToggleSeat: () {
          final setVacant = seat.status == 'occupied';
          onUpdateSeat(floor.id, seat.id, setVacant);
          Navigator.pop(context);
        },
        onForceVacate: () {
          onUpdateSeat(floor.id, seat.id, true);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (floor.id != '6f') {
      return const Center(child: Text('マップ準備中', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)));
    }

    final leftSeats = seats.where((s) => s.id.startsWith('6f-left')).toList();
    final centerSeats = seats.where((s) => s.id.startsWith('6f-center')).toList();
    final rightSeats = seats.where((s) => s.id.startsWith('6f-right')).toList();
    final meetings = seats.where((s) => s.id.contains('meeting')).toList();

    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final isOutsideHours = now.hour < 9 || now.hour >= 20;

    final vacantCount = isOutsideHours ? 0 : seats.where((s) => s.status == 'vacant').length;
    final totalCount = seats.length;

    return Column(
      children: [
        // 凡例(Legend)エリア
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                     const Icon(Icons.location_on, color: Colors.blue, size: 16),
                     const SizedBox(width: 4),
                     Text(floor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      children: [
                        const TextSpan(text: '空席: '),
                        TextSpan(text: '$vacantCount', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        TextSpan(text: ' / $totalCount'),
                      ]
                    )
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem(Colors.white, Colors.grey.shade300, '空席'),
                  const SizedBox(width: 8),
                  _buildLegendItem(Colors.red.shade500, Colors.red.shade600, '使用中'),
                  const SizedBox(width: 8),
                  _buildLegendItem(Colors.grey.shade400, Colors.grey.shade500, '使用不可'),
                  const SizedBox(width: 8),
                  _buildLegendItem(Colors.blue, Colors.blue, '自分', textColor: Colors.white),
                ]
              )
            ],
          ),
        ),
        
        // 座席マップエリア
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   // デスクエリア (A列, B列, C列)
                   Expanded(
                     child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           // A列 (左側)
                           _buildColumnRegion(context, 'A 列', leftSeats, MainAxisAlignment.spaceBetween, width: 96),
                           
                           // B列 (中央グリッド)
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 16.0),
                             child: Column(
                               children: [
                                 const Text('B 列 (メインエリア)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                 const SizedBox(height: 8),
                                 Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(5, (rIndex) {
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: rIndex == 4 ? 0 : 8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: List.generate(7, (cIndex) {
                                                final idx = rIndex * 7 + cIndex;
                                                return Padding(
                                                  padding: EdgeInsets.only(right: cIndex == 6 ? 0 : 8.0),
                                                  child: SizedBox(
                                                    width: 32,
                                                    height: 32,
                                                    child: idx < centerSeats.length 
                                                      ? _buildSeatWidget(context, centerSeats[idx])
                                                      : const SizedBox(),
                                                  ),
                                                );
                                              }),
                                            ),
                                          );
                                        }),
                                      ),
                                    )
                                 )
                               ]
                             )
                           ),

                           // C列 (右側)
                           _buildColumnRegion(context, 'C 列', rightSeats, MainAxisAlignment.start, width: 96),
                        ]
                     )
                   ),

                   // 会議室 (下部)
                   if (meetings.isNotEmpty) ...[
                     const SizedBox(height: 16),
                     const Divider(),
                     const SizedBox(height: 8),
                     Row(
                        children: meetings.map((m) => Expanded(
                          child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 4.0),
                             child: _buildMeetingWidget(context, m)
                          )
                        )).toList()
                     )
                   ]
                ]
              )
            ), // end of Container
            ), // end of InteractiveViewer
          ) // end of Padding
        ) // end of Expanded
      ],
    );
  }

  Widget _buildLegendItem(Color bg, Color border, String label, {Color textColor = Colors.black87}) {
    return Row(
      children: [
        Container(
          width: 12, height: 12, 
          decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(2))
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
      ]
    );
  }

  Widget _buildColumnRegion(BuildContext context, String title, List<Seat> colSeats, MainAxisAlignment alignment, {double width = 48}) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: alignment,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: alignment,
              children: colSeats.map((s) => Flexible(
                 child: ConstrainedBox(
                   constraints: const BoxConstraints(maxHeight: 32),
                   child: Padding(
                     padding: const EdgeInsets.symmetric(vertical: 2.0),
                     child: _buildSeatWidget(context, s, isWide: true),
                   ),
                 ),
              )).toList(),
            ),
          )
        ]
      )
    );
  }

  Widget _buildSeatWidget(BuildContext context, Seat seat, {bool isWide = false}) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final isOutsideHours = now.hour < 9 || now.hour >= 20;

    final isMine = seat.occupiedBy?.name == userProfile.name;
    final effectiveStatus = isOutsideHours ? 'unavailable' : seat.status;
    final isOccupied = effectiveStatus == 'occupied';
    final isUnavailable = effectiveStatus == 'unavailable';

    Color bg = Colors.white;
    Color border = Colors.grey.shade300;
    Color text = Colors.black87;

    if (isMine && !isOutsideHours) {
      bg = Colors.blue.shade600;
      border = Colors.blue.shade600;
      text = Colors.white;
    } else if (isUnavailable) {
      bg = Colors.grey.shade400;
      border = Colors.grey.shade500;
      text = Colors.white;
    } else if (isOccupied) {
      bg = Colors.red.shade500;
      border = Colors.red.shade600;
      text = Colors.white;
    }

    String label = isWide 
        ? seat.name.replaceAll('デスク ', '') 
        : seat.id.replaceAll('6f-center-', '').replaceAll('-', '-');

    return GestureDetector(
      onTap: () => _handleSelectSeat(context, seat),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isMine ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: isWide ? 10 : 8, fontWeight: FontWeight.bold, color: text)),
            if (isMine) Text('✓', style: TextStyle(fontSize: 8, color: text, height: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingWidget(BuildContext context, Seat seat) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final isOutsideHours = now.hour < 9 || now.hour >= 20;

    final isMine = seat.occupiedBy?.name == userProfile.name;
    final effectiveStatus = isOutsideHours ? 'unavailable' : seat.status;
    final isOccupied = effectiveStatus == 'occupied';
    final isUnavailable = effectiveStatus == 'unavailable';

    Color bg = Colors.white;
    Color border = Colors.grey.shade300;
    Color text = Colors.black87;

    if (isMine && !isOutsideHours) {
      bg = Colors.blue.shade600;
      border = Colors.blue.shade600;
      text = Colors.white;
    } else if (isUnavailable) {
      bg = Colors.grey.shade400;
      border = Colors.grey.shade500;
      text = Colors.white;
    } else if (isOccupied) {
      bg = Colors.red.shade500;
      border = Colors.red.shade600;
      text = Colors.white;
    }

    final parts = seat.name.split(' ');
    String meetingName = parts.length > 2 ? "\${parts[1]} \${parts[2]}" : seat.name;
    String capacity = RegExp(r'\((.*?)\)').firstMatch(seat.name)?.group(1) ?? '';

    return GestureDetector(
      onTap: () => _handleSelectSeat(context, seat),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(meetingName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
            if (capacity.isNotEmpty) Text(capacity, style: TextStyle(fontSize: 9, color: isMine ? Colors.white70 : Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(isMine ? '✓ 自分が利用中' : (isOccupied ? '使用中' : '選択して使用'), style: TextStyle(fontSize: 8, color: isMine ? Colors.white70 : Colors.grey)),
          ],
        ),
      )
    );
  }
}

// lib/widgets/seat_detail_dialog.dart

class SeatDetailDialog extends StatelessWidget {
  final Seat seat;
  final UserProfile userProfile;
  final VoidCallback onToggleSeat;
  final VoidCallback onForceVacate;

  const SeatDetailDialog({
    super.key,
    required this.seat,
    required this.userProfile,
    required this.onToggleSeat,
    required this.onForceVacate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final isOutsideHours = now.hour < 9 || now.hour >= 20;

    final isMine = seat.occupiedBy?.name == userProfile.name;
    final effectiveStatus = isOutsideHours ? 'unavailable' : seat.status;
    final isOccupied = effectiveStatus == 'occupied';
    
    final isA = seat.id.contains('left') || seat.name.contains('A-');
    final isB = seat.id.contains('center') || seat.name.contains('B-');
    final isMeeting = seat.type == 'meeting';
    
    String capacity = '情報なし';
    if (isA) {
      capacity = '6人';
    } else if (isB) capacity = '2人';
    else if (isMeeting) capacity = seat.name.contains('8名') ? '8人' : '10人';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(
              seat.type == 'meeting' ? '共有スペース' : '個別ワークスペース',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700, letterSpacing: 1.5),
            ),
            const SizedBox(height: 4),
            Text(seat.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                   _buildSpecRow('利用状態', isMine ? 'あなたが利用中 🔵' : (isOccupied ? '使用中 🔴' : (isOutsideHours ? '利用時間外 ⚪' : '空席 🟢'))),
                  const Divider(),
                  _buildSpecRow('利用可能時間', '9:00 〜 20:00 ⏱️'),
                  const Divider(),
                  _buildSpecRow('座れる人数', capacity + (capacity != '情報なし' ? ' 👨‍💼' : '')),
                  const Divider(),
                  _buildSpecRow('電源 (コンセント)', seat.amenities.contains('電源') ? 'あり 🔌' : 'なし ✕'),
                  const Divider(),
                  _buildSpecRow('主なアメニティ', seat.amenities.isEmpty ? '特になし' : seat.amenities.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (isMine)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: onToggleSeat,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('この席の利用を終了する', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else if (isOutsideHours)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: null,
                icon: const Icon(Icons.access_time),
                label: const Text('利用時間外', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else if (isOccupied)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: onForceVacate,
                icon: const Icon(Icons.refresh),
                label: const Text('この席を空席に戻す (退出確認)', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onToggleSeat,
                icon: const Icon(Icons.check),
                label: const Text('この席を利用する', style: TextStyle(fontWeight: FontWeight.bold)),
              )
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

// lib/screens/settings_screen.dart

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onProfileChanged;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _deptController;
  late TextEditingController _untilController;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _startLoadingAnimation();
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
    _nameController = TextEditingController(text: widget.profile.name);
    _deptController = TextEditingController(text: widget.profile.department);
    _untilController = TextEditingController(text: widget.profile.until);
  }

  void _saveProfile() {
    widget.onProfileChanged(UserProfile(
      name: _nameController.text,
      department: _deptController.text,
      until: _untilController.text,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('プロフィールを保存しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: FloorDrawer(
        currentFloor: _currentFloor,
        onFloorSelected: _changeFloor,
      ),
      // ドロワーが開いたときに本体が右にスライド＆縮小してグレーがかる
      // 動きを再現するため drawerScrimColor を使いつつ、Builder で
      // 本体コンテンツに少し縮小エフェクトを掛ける
      drawerScrimColor: Colors.black.withOpacity(0.08),
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
      appBar: AppBar(title: const Text('プロフィール・設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'お名前', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deptController,
              decoration: const InputDecoration(labelText: '所属・部署', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _untilController,
              decoration: const InputDecoration(labelText: '利用予定時刻', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveProfile,
              child: const Text('設定を保存する', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

/// フロアマップのスケルトン（ローディング時の薄いプレースホルダー）
/// 以前は6F/9Fどちらでも同じ汎用グリッドを表示していたため、
/// 「見覚えのある違うフロアマップが一瞬見える」ように感じられる原因になっていた。
/// 実際のフロア（_floor6FItems / _floor9FItems）のシルエットを
/// 薄いグレーで表示することで、ローディング後にスムーズに実体へ繋がるようにする。
class _FloorMapSkeleton extends StatelessWidget {
  final String floor;
  const _FloorMapSkeleton({super.key, required this.floor});

  @override
  Widget build(BuildContext context) {
    final items = floor == '9F' ? _floor9FItems : _floor6FItems;
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
/// これにより、
///   - 一部分しか見えない（要素が画面外に出てしまう）
///   - フロア切替直後に拡大された状態で一瞬表示される
/// という問題を解消する。
class _FloorMapContent extends StatefulWidget {
  final String floor;
  const _FloorMapContent({super.key, required this.floor});

  @override
  State<_FloorMapContent> createState() => _FloorMapContentState();
}

class _FloorMapContentState extends State<_FloorMapContent> {
  final TransformationController _controller = TransformationController();
  bool _isFitReady = false; // フィット計算が完了するまで何も描画しないためのフラグ
  Size? _lastFittedSize; // 直前にフィット計算を行ったビューポートサイズ

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
          items: _floor9FItems,
        ),
      _ => _FloorMapCanvas(
          canvasWidth: _canvasSize.width,
          canvasHeight: _canvasSize.height,
          items: _floor6FItems,
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
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.95; // 少し余白を持たせる

    // スケール後のサイズが表示エリアの中央に来るような平行移動量を計算
    final dx = (viewportSize.width - canvas.width * scale) / 2;
    final dy = (viewportSize.height - canvas.height * scale) / 2;

    final matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);

    _controller.value = matrix;
    _lastFittedSize = viewportSize;

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
            // パン（ドラッグでの横・縦スクロール）を有効化
            panEnabled: true,
            // ピンチでのズームイン・ズームアウトを有効化
            scaleEnabled: true,
            minScale: 0.3,
            maxScale: 4.0,
            // フィット計算で設定した中央寄せの平行移動(dx, dy)が
            // InteractiveViewer内部の境界判定でクランプされて
            // 見切れてしまうことを防ぐため、キャンバス全体を
            // 十分にカバーできる大きさの余白を確保する。
            boundaryMargin: EdgeInsets.symmetric(
              horizontal: _canvasSize.width,
              vertical: _canvasSize.height,
            ),
            child: _buildMapWidget(),
          ),
        );
      },
    );
  }
}

/// フロアマップ上の1要素（座席・設備など）の配置情報
/// x, y, width, height は元画像のピクセル座標そのまま使う
class FloorMapItem {
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
  final String? label; // 「入口」のようなテキストラベルがある場合に指定

  const FloorMapItem({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.color = AppColors.gridGray,
    this.label,
  });
}

/// 6Fimage.png から実測した座標データ
/// （画像を背景差分で解析し、各矩形のx, y, width, heightを抽出したもの）
const List<FloorMapItem> _floor6FItems = [
  // --- 左側の縦に並んだ列（7個） ---
  FloorMapItem(x: 108, y: 120, width: 45, height: 25),
  FloorMapItem(x: 108, y: 167, width: 45, height: 25),
  FloorMapItem(x: 108, y: 213, width: 45, height: 26),
  FloorMapItem(x: 108, y: 260, width: 45, height: 25),
  FloorMapItem(x: 108, y: 307, width: 45, height: 25),
  FloorMapItem(x: 108, y: 354, width: 45, height: 25),
  FloorMapItem(x: 108, y: 401, width: 45, height: 25),

  // --- 中央の座席グリッド（7列 x 5行 = 35個） ---
  FloorMapItem(x: 216, y: 170, width: 25, height: 25),
  FloorMapItem(x: 260, y: 170, width: 26, height: 25),
  FloorMapItem(x: 305, y: 170, width: 25, height: 25),
  FloorMapItem(x: 349, y: 170, width: 25, height: 25),
  FloorMapItem(x: 394, y: 170, width: 25, height: 25),
  FloorMapItem(x: 438, y: 170, width: 25, height: 25),
  FloorMapItem(x: 482, y: 170, width: 26, height: 25),

  FloorMapItem(x: 216, y: 209, width: 25, height: 25),
  FloorMapItem(x: 260, y: 209, width: 26, height: 25),
  FloorMapItem(x: 305, y: 209, width: 25, height: 25),
  FloorMapItem(x: 349, y: 209, width: 25, height: 25),
  FloorMapItem(x: 394, y: 209, width: 25, height: 25),
  FloorMapItem(x: 438, y: 209, width: 25, height: 25),
  FloorMapItem(x: 482, y: 209, width: 26, height: 25),

  FloorMapItem(x: 216, y: 248, width: 25, height: 25),
  FloorMapItem(x: 260, y: 248, width: 26, height: 25),
  FloorMapItem(x: 305, y: 248, width: 25, height: 25),
  FloorMapItem(x: 349, y: 248, width: 25, height: 25),
  FloorMapItem(x: 394, y: 248, width: 25, height: 25),
  FloorMapItem(x: 438, y: 248, width: 25, height: 25),
  FloorMapItem(x: 482, y: 248, width: 26, height: 25),

  FloorMapItem(x: 216, y: 287, width: 25, height: 25),
  FloorMapItem(x: 260, y: 287, width: 26, height: 25),
  FloorMapItem(x: 305, y: 287, width: 25, height: 25),
  FloorMapItem(x: 349, y: 287, width: 25, height: 25),
  FloorMapItem(x: 394, y: 287, width: 25, height: 25),
  FloorMapItem(x: 438, y: 287, width: 25, height: 25),
  FloorMapItem(x: 482, y: 287, width: 26, height: 25),

  FloorMapItem(x: 216, y: 326, width: 25, height: 25),
  FloorMapItem(x: 260, y: 326, width: 26, height: 25),
  FloorMapItem(x: 305, y: 326, width: 25, height: 25),
  FloorMapItem(x: 349, y: 326, width: 25, height: 25),
  FloorMapItem(x: 394, y: 326, width: 25, height: 25),
  FloorMapItem(x: 438, y: 326, width: 25, height: 25),
  FloorMapItem(x: 482, y: 326, width: 26, height: 25),

  // --- 右側の縦に並んだ小さい列（4個） ---
  FloorMapItem(x: 615, y: 187, width: 26, height: 25),
  FloorMapItem(x: 615, y: 216, width: 26, height: 25),
  FloorMapItem(x: 615, y: 245, width: 26, height: 26),
  FloorMapItem(x: 615, y: 275, width: 26, height: 25),

  // --- 下部の長方形2つ ---
  FloorMapItem(x: 219, y: 413, width: 89, height: 35),
  FloorMapItem(x: 350, y: 413, width: 89, height: 35),

  // --- 入口ラベル ---
  FloorMapItem(x: 526, y: 519, width: 115, height: 53, label: '入口'),
];

/// 9Fimage.png から実測した座標データ
/// 左から3列の座席エリア（各7個）+ 右側の受付/棚/小型設備群 + 入口ラベル
const List<FloorMapItem> _floor9FItems = [
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
  FloorMapItem(x: 567, y: 635, width: 91, height: 42, label: '入口'),
];

/// 座標リスト（FloorMapItem）を実際のキャンバス上に配置して描画するウィジェット。
/// Stack + Positioned で、画像から実測したピクセル座標をそのまま使用する。
class _FloorMapCanvas extends StatelessWidget {
  final double canvasWidth;
  final double canvasHeight;
  final List<FloorMapItem> items;

  const _FloorMapCanvas({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.items,
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
              child: Container(
                color: item.color,
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
              ),
            ),
        ],
      ),
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
