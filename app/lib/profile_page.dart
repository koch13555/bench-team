import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'firebase_db.dart';
import 'photo_crop_page.dart';
import 'profile_avatar.dart';
import 'app_localizations.dart';
import 'settings_page.dart';

/// プロフィール画面。
/// 写真は選択後にその場でリサイズ・圧縮してbase64文字列にし、
/// Realtime Databaseの `users/{uid}/photoBase64` に保存する
/// (Firebase Storage不使用。詳細はprofile_avatar.dartのコメント参照)。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploading = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90, // ここでの圧縮はプレビュー読み込み負荷軽減用。本圧縮は下で行う。
    );
    if (picked == null) return;

    final rawBytes = await picked.readAsBytes();

    // ピンチズーム・ドラッグで位置を調整できる切り抜き画面を開く
    if (!mounted) return;
    final croppedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => PhotoCropPage(imageBytes: rawBytes)),
    );
    if (croppedBytes == null) return; // キャンセルされた場合

    setState(() => _isUploading = true);
    try {
      final decoded = img.decodeImage(croppedBytes);
      if (decoded == null) {
        throw Exception('画像を読み込めませんでした');
      }

      // 切り抜き画面で既に正方形になっているので、ここではリサイズと圧縮のみ行う。
      final resized = img.copyResize(decoded, width: 200, height: 200);
      final jpgBytes = img.encodeJpg(resized, quality: 70);
      final base64Str = base64Encode(jpgBytes);

      // 念のため、極端に大きくなっていないか確認(通常は数十KB程度に収まる)
      if (base64Str.length > 300000) {
        throw Exception('画像サイズが大きすぎます。別の写真を選んでください');
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw StateError('ログインしていません');
      }
      await appDatabase.ref('users/$uid/photoBase64').set(base64Str);

      _showMessage(AppStrings.t('profile_updated'));
    } catch (e) {
      _showMessage('${AppStrings.t('profile_update_failed')}: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploading = true);
    try {
      await appDatabase.ref('users/$uid/photoBase64').remove();
      _showMessage(AppStrings.t('profile_removed'));
    } catch (e) {
      _showMessage('${AppStrings.t('profile_remove_failed')}: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? 'ゲスト');

    return Scaffold(
      backgroundColor: const Color(0xFF8DF172),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8DF172),
        foregroundColor: Colors.white,
        title: Text(AppStrings.t('profile_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppStrings.t('drawer_settings'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const ProfileAvatar(size: 120),
              const SizedBox(height: 16),
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUpload,
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppStrings.t('profile_pick_photo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isUploading ? null : _removePhoto,
                child: Text(
                  AppStrings.t('profile_remove_photo'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('profile_name_label'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
