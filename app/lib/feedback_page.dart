import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_db.dart';
import 'app_localizations.dart';

/// フィードバック(不具合報告・要望)を送信する画面。
/// 送信内容は Realtime Database の `feedback/{自動生成ID}` に保存する。
/// (専用の管理画面は無いので、開発チームはFirebaseコンソールから直接確認する想定)
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('feedback_empty_error'))),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await appDatabase.ref('feedback').push().set({
        'uid': user?.uid ?? '不明',
        'displayName': user?.displayName ?? user?.email ?? 'ゲスト',
        'text': text,
        'createdAt': ServerValue.timestamp,
      });

      if (mounted) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('feedback_sent'))),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.t('feedback_send_failed')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('feedback_title'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.t('feedback_description'),
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: AppStrings.t('feedback_hint'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF106E00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(AppStrings.t('feedback_send')),
            ),
          ],
        ),
      ),
    );
  }
}
