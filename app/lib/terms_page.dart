import 'package:flutter/material.dart';
import 'app_localizations.dart';

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
      appBar: AppBar(title: Text(AppStrings.t('terms_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.t('terms_intro'),
            style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _Section(title: AppStrings.t('terms_1_title'), body: AppStrings.t('terms_1_body')),
          _Section(title: AppStrings.t('terms_2_title'), body: AppStrings.t('terms_2_body')),
          _Section(title: AppStrings.t('terms_3_title'), body: AppStrings.t('terms_3_body')),
          _Section(title: AppStrings.t('terms_4_title'), body: AppStrings.t('terms_4_body')),
          _Section(title: AppStrings.t('terms_5_title'), body: AppStrings.t('terms_5_body')),
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
