import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'friend_service.dart';
import 'qr_scanner_page.dart';
import 'checkin_page.dart';

/// 自分のQRコード表示・相手のQR読み取り・フレンド申請一覧・
/// フレンドが今どの座席にいるかの表示を扱う画面
class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final _friendService = FriendService();
  Future<List<FriendStatus>>? _friendsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFriends();
  }

  void _refreshFriends() {
    setState(() {
      _friendsFuture = _friendService.loadFriendsWithLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('フレンド')),
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
                isActive: true, // 現在この画面にいるのでハイライト
                onTap: null,
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
      body: RefreshIndicator(
        onRefresh: () async => _refreshFriends(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              children: [
                const Text('自分のQRコード(相手に読み取ってもらう)'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  // QRコードの中身は自分のUIDのみ。個人情報(名前・メール等)は含めない
                  child: QrImageView(
                    data: 'benchapp://addfriend?uid=$myUid',
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QRコードを読み取ってフレンド申請'),
              onPressed: () => _openScanner(context),
            ),
            const SizedBox(height: 24),
            const Text('届いているフレンド申請', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<List<FriendRequest>>(
              stream: _friendService.incomingRequests(),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return const Text('現在届いている申請はありません');
                }
                return Column(
                  children: requests.map((r) {
                    return Card(
                      child: ListTile(
                        title: Text(r.fromName),
                        subtitle: const Text('フレンド申請が届いています'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await _friendService.approveRequest(r);
                                _refreshFriends();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _friendService.rejectRequest(r.fromUid),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('フレンドの現在地', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<FriendStatus>>(
              future: _friendsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final friends = snapshot.data ?? [];
                if (friends.isEmpty) {
                  return const Text('まだフレンドがいません');
                }
                return Column(
                  children: friends.map((f) {
                    final isSeated = f.seatId != null;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isSeated ? Icons.event_seat : Icons.person_outline,
                          color: isSeated ? const Color(0xFF106E00) : Colors.grey,
                        ),
                        title: Text(f.name),
                        subtitle: Text(
                          isSeated ? '${f.seatId} に着席中' : '現在チェックインしていません',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final rawValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerPage(title: 'フレンドのQRコードを読み取ってください'),
      ),
    );
    if (rawValue == null) return;

    final uri = Uri.tryParse(rawValue);
    final scannedUid = uri?.queryParameters['uid'];
    if (uri == null || uri.host != 'addfriend' || scannedUid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンド追加用のQRコードではないようです')),
        );
      }
      return;
    }

    try {
      await _friendService.sendFriendRequest(scannedUid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンド申請を送りました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('申請に失敗しました: $e')),
        );
      }
    }
  }
}

/// 画面下部の共通ナビ項目(ホーム/フレンド/QRコード)。
/// checkin_page.dart / seat_widget.dart の同名ウィジェットと見た目を揃えている。
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
