import 'package:flutter/material.dart';

/// 「アプリについて」画面。バージョン情報とチームメンバーのクレジットを表示する。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // リリース時にバージョンを上げる場合はここを更新する。
  static const String appVersion = '1.0.0';

  static const List<String> teamMembers = [
    '十代田航大',
    '大西優輝',
    '長本瑞輝',
    '日高怜良',
    '堀田晋平',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アプリについて')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.event_seat, size: 64, color: Color(0xFF106E00)),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'すわほ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'バージョン $appVersion',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '座席の空き状況をリアルタイムに確認できる、大学構内向けの座席管理アプリです。',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text('開発チーム', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (final name in teamMembers)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(name),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
