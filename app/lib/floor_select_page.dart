import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// 座席ウィジェット（Firebase連携版）
/// 空席 = 青、満席 = 赤
class SeatWidget extends StatefulWidget {
  final String seatId;
  final String label;

  const SeatWidget({
    super.key,
    required this.seatId,
    required this.label,
  });

  @override
  State<SeatWidget> createState() => _SeatWidgetState();
}

class _SeatWidgetState extends State<SeatWidget> {
  bool _isOccupied = false;

  @override
  void initState() {
    super.initState();
    // Firebaseからリアルタイムでデータを受け取る
    FirebaseDatabase.instance
        .ref('seats/${widget.seatId}')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          _isOccupied = data['occupied'] ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSeatDetail(context),
      child: Container(
        decoration: BoxDecoration(
          // 空席=青、満席=赤
          color: _isOccupied ? Colors.red : Colors.blue,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 座席の詳細を表示する
  void _showSeatDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _isOccupied ? Colors.red : Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isOccupied ? '使用中' : '空席',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_isOccupied)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    FirebaseDatabase.instance
                        .ref('seats/${widget.seatId}')
                        .set({
                      'occupied': true,
                      'startTime': DateTime.now().toIso8601String(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'この席を使用する',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    FirebaseDatabase.instance
                        .ref('seats/${widget.seatId}')
                        .set({
                      'occupied': false,
                      'startTime': '',
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'この席を空席にする',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}