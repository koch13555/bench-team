import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_db.dart';

/// プロフィール写真を丸いアイコンとして表示するウィジェット。
///
/// 写真はFirebase Storageを使わず、圧縮したJPEGをbase64文字列にして
/// Realtime Databaseの `users/{uid}/photoBase64` に直接保存する方式にしている
/// (Firebase StorageはBlazeプラン=クレジットカード登録が必要なプランへの
///  切り替えが必須なため、無料のSparkプランのままにするための対応)。
///
/// 写真が未設定、または読み込みに失敗した場合はデフォルトの人物アイコンを表示する。
class ProfileAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({super.key, this.size = 56, this.onTap});

  Widget _defaultIcon() {
    return Icon(
      Icons.person,
      size: size * 0.57,
      color: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    Widget inner;
    if (uid == null) {
      inner = _defaultIcon();
    } else {
      inner = StreamBuilder<DatabaseEvent>(
        // Realtime Databaseを直接見ているので、他の画面で写真を更新すると
        // ここも自動的に最新の写真に切り替わる。
        stream: appDatabase.ref('users/$uid/photoBase64').onValue,
        builder: (context, snapshot) {
          final base64Str = snapshot.data?.snapshot.value as String?;
          if (base64Str == null || base64Str.isEmpty) {
            return _defaultIcon();
          }
          try {
            final bytes = base64Decode(base64Str);
            return Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          } catch (_) {
            return _defaultIcon();
          }
        },
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
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
        child: inner,
      ),
    );
  }
}
