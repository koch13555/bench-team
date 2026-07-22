import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seat_checkin_service.dart';
import 'qr_scanner_page.dart';
import 'seat_widget.dart'; // goToFriendScreen()を使うため
import 'app_localizations.dart';

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
        builder: (_) => QrScannerPage(title: AppStrings.t('checkin_scan_hint')),
      ),
    );
    if (rawValue == null) return;

    final seatId = SeatCheckinService.parseCheckinQr(rawValue);
    if (seatId == null) {
      _showMessage(AppStrings.t('not_qr_seat'));
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
    // 今この席に何人いるか確認する(グループ席は複数人が同時にチェックインできる)
    final occupants = await _service.getCurrentOccupants(seatId);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final others = occupants.where((o) => o.uid != myUid).toList();

    if (others.isNotEmpty) {
      final proceed = await _confirmJoinSeat(others.map((o) => o.displayName).toList());
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.checkIn(seatId: seatId);
      _showMessage('$seatId ${AppStrings.t('checkin_success')}');
    } catch (e) {
      _showMessage('${AppStrings.t('checkin_fail')}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 「現在〇〇さんたちが利用中です。一緒にチェックインしますか?」の確認ダイアログ
  /// (満席の場合は、この後 checkIn() 側でエラーメッセージが表示される)
  Future<bool?> _confirmJoinSeat(List<String> occupantNames) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('checkin_join_title')),
        content: Text('${AppStrings.t('checkin_join_body_prefix')}${occupantNames.join('、')}${AppStrings.t('checkin_join_body_suffix')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.t('checkin_button')),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppStrings.t('checkin_title')),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // ← 戻る矢印を非表示にし、下部ナビに統一
      ),
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
                label: AppStrings.t('nav_home'),
                isActive: false,
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: AppStrings.t('nav_friend'),
                isActive: false,
                onTap: () => goToFriendScreen(context),
              ),
              _NavItem(
                icon: Icons.qr_code_scanner,
                label: AppStrings.t('nav_qr'),
                isActive: true, // 現在この画面にいるのでハイライト
                onTap: null,
              ),
            ],
          ),
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
                        label: Text(AppStrings.t('checkin_scan_qr')),
                        onPressed: _scanAndCheckIn,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _manualCheckIn,
                      child: Text(AppStrings.t('checkin_manual_entry')),
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
      title: Text(AppStrings.t('checkin_manual_dialog_title')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppStrings.t('checkin_manual_hint'),
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(AppStrings.t('checkin_button')),
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
