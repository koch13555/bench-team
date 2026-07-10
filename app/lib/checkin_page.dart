import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seat_checkin_service.dart';
import 'qr_scanner_page.dart';
import 'friend_screen.dart';

/// 座席チェックインの入り口画面。
/// - QRコードをスキャンしてチェックイン
/// - 手動で座席番号(例: seat_01)を入力してチェックイン
///   (カメラが使えない・QRが読み取りにくい場合の保険)
class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  final _service = SeatCheckinService();
  bool _isLoading = false;

  Future<void> _scanAndCheckIn() async {
    final rawValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerPage(title: '座席のQRコードを枠内に合わせてください'),
      ),
    );
    if (rawValue == null) return;

    final seatId = SeatCheckinService.parseCheckinQr(rawValue);
    if (seatId == null) {
      _showMessage('座席用のQRコードではないようです');
      return;
    }
    await _checkIn(seatId);
  }

  Future<void> _manualCheckIn() async {
    final seatId = await showDialog<String>(
      context: context,
      builder: (context) => const _ManualSeatIdDialog(),
    );
    if (seatId == null || seatId.isEmpty) return;
    await _checkIn(seatId);
  }

  Future<void> _checkIn(String seatId) async {
    // チェックインする前に、今この席に誰か座っていないか確認する
    final occupant = await _service.getCurrentOccupant(seatId);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (occupant != null && occupant.uid != myUid) {
      final proceed = await _confirmOccupiedSeat(occupant.displayName);
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.checkIn(seatId: seatId);
      _showMessage('$seatId にチェックインしました');
    } catch (e) {
      _showMessage('チェックインに失敗しました: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 「現在〇〇さんが座っています。それでもチェックインしますか?」の確認ダイアログ
  Future<bool?> _confirmOccupiedSeat(String occupantName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('この席は使用中です'),
        content: Text('現在「$occupantName」さんが座っています。\nそれでもチェックインしますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('チェックインする'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8DF172), // ホーム画面と同じ背景色
      appBar: AppBar(
        title: const Text('座席にチェックイン'),
        backgroundColor: const Color(0xFF8DF172),
        automaticallyImplyLeading: false, // ← 戻る矢印を非表示にし、下部ナビに統一
      ),
      bottomNavigationBar: Container(
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendScreen()),
                );
              },
            ),
            _NavItem(
              icon: Icons.qr_code_scanner,
              label: 'QRコード',
              isActive: true, // 現在この画面にいるのでハイライト
              onTap: null,
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 72, color: Colors.grey),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('QRコードをスキャン'),
                        onPressed: _scanAndCheckIn,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _manualCheckIn,
                      child: const Text('座席番号を直接入力する'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 座席番号(seat_01など)を手入力するための簡易ダイアログ
class _ManualSeatIdDialog extends StatefulWidget {
  const _ManualSeatIdDialog();

  @override
  State<_ManualSeatIdDialog> createState() => _ManualSeatIdDialogState();
}

class _ManualSeatIdDialogState extends State<_ManualSeatIdDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('座席番号を入力'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '例: seat_01',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('チェックイン'),
        ),
      ],
    );
  }
}

/// 画面下部の共通ナビ項目(ホーム/フレンド/QRコード)。
/// seat_widget.dart の同名ウィジェットと見た目を揃えている。
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
