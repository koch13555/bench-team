import 'package:flutter/material.dart';

/// 「使い方」画面。アプリの主な機能を簡単に説明する。
class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使い方')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _HowToSection(
            icon: Icons.event_seat,
            title: '座席の空き状況を確認する',
            steps: [
              'ホーム画面でキャンパスを選び、フロア(6F/9F)を選択します。',
              '座席をタップすると、詳細(空席/使用中、電源の有無など)が確認できます。',
              '青(空席)・赤(使用中)の色で一目で分かります。',
            ],
          ),
          SizedBox(height: 24),
          _HowToSection(
            icon: Icons.qr_code_scanner,
            title: 'QRコードでチェックインする',
            steps: [
              '下部ナビの「QRコード」をタップします。',
              'テーブルに設置されたQRコードを読み取ると、その場でチェックインできます。',
              'QRが読み取れない場合は「座席番号を直接入力する」からでもチェックインできます。',
            ],
          ),
          SizedBox(height: 24),
          _HowToSection(
            icon: Icons.people_outline,
            title: 'フレンドを追加する',
            steps: [
              '下部ナビの「フレンド」から、自分のQRコードを表示できます。',
              '友達に読み取ってもらう(または友達のQRを読み取る)とフレンド申請が届きます。',
              '申請を承認すると、フレンドが今どの座席にいるかが分かるようになります。',
            ],
          ),
          SizedBox(height: 24),
          _HowToSection(
            icon: Icons.star_border,
            title: 'キャンパスをお気に入り登録する',
            steps: [
              'ホーム画面のキャンパスカード左上の☆をタップすると★になります。',
              'お気に入りにしたキャンパスは、次にアプリを開いた時に一覧の上位に表示されます。',
            ],
          ),
          SizedBox(height: 24),
          _HowToSection(
            icon: Icons.warning_amber,
            title: '災害用モード',
            steps: [
              'フロアマップ画面右上の⚠️アイコンで切り替えられます。',
              'ONにすると、災害時に「かまどベンチ」として使える座席がオレンジ色で表示されます。',
              'タップすると使い方(組み立て方・注意事項)を確認できます。',
            ],
          ),
        ],
      ),
    );
  }
}

class _HowToSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> steps;

  const _HowToSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF106E00)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(steps[i], style: const TextStyle(height: 1.4))),
              ],
            ),
          ),
      ],
    );
  }
}
