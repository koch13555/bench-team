import 'package:flutter/material.dart';

/// Android / iOS向け: 見た目だけのボタン。押すと[onPressed]
/// (= AuthService.signInWithGoogle経由の従来ログイン処理)を呼ぶ。
Widget buildGoogleSignInButton({required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.g_mobiledata, color: Colors.black87),
      label: const Text('Googleでログイン', style: TextStyle(color: Colors.black87)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}
