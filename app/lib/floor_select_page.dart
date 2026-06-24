import 'package:flutter/material.dart';

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
  Map<String, List<Seat>> _seats = loadInitialSeats();
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
    if (isA) capacity = '6人';
    else if (isB) capacity = '2人';
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

