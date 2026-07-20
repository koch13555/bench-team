import 'package:flutter/material.dart';

/// 利用規約・プライバシーポリシー画面。
///
/// 注意: これは学生プロジェクトとしての簡易的なひな形です。
/// 実際に一般公開する場合は、正式な法的文書として
/// 指導教員や有識者に内容を確認してもらうことをおすすめします。
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用規約・プライバシーポリシー')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            '本アプリ「すわほ」は、大学の講義における企業連携プログラムの一環として、'
            '学生チームが開発したものです。以下は簡易的な利用規約・プライバシーポリシーです。',
            style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
          ),
          SizedBox(height: 24),
          _Section(
            title: '1. 収集する情報',
            body:
                '本アプリでは、以下の情報を取得・保存する場合があります。\n'
                '・ログインに用いるメールアドレス、Google/Appleアカウントの表示名\n'
                '・プロフィール写真(任意で設定した場合のみ)\n'
                '・座席のチェックイン履歴(いつ・どの座席を利用したか)\n'
                '・フレンド関係、およびフレンドに公開される現在の座席位置\n'
                '・お気に入りに登録したキャンパスの情報',
          ),
          _Section(
            title: '2. 情報の利用目的',
            body:
                '取得した情報は、座席の空き状況の可視化、フレンド間での位置共有、'
                'アプリの改善(フィードバックの確認)以外の目的には利用しません。',
          ),
          _Section(
            title: '3. 情報の共有範囲',
            body:
                '座席の利用状況や現在地は、承認済みのフレンドにのみ共有されます。'
                'フレンド以外の第三者や、本アプリの開発チーム以外の外部組織に'
                '個人を特定できる情報を提供することはありません。',
          ),
          _Section(
            title: '4. データの削除',
            body:
                'プロフィール写真は、プロフィール画面からいつでも削除できます。'
                'アカウント自体の削除や、保存されているデータ全体の削除を希望する場合は、'
                '開発チームまでフィードバック画面よりご連絡ください。',
          ),
          _Section(
            title: '5. 免責事項',
            body:
                '本アプリは学生プロジェクトの成果物であり、動作の完全性・正確性を'
                '保証するものではありません。座席状況の表示が実際の状況と'
                '異なる場合があります。',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.6, fontSize: 13)),
        ],
      ),
    );
  }
}
