import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// 「使い方」画面。アプリの主な機能を簡単に説明する。
class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('howto_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HowToSection(
            icon: Icons.event_seat,
            title: AppStrings.t('howto_1_title'),
            steps: [
              AppStrings.t('howto_1_step1'),
              AppStrings.t('howto_1_step2'),
              AppStrings.t('howto_1_step3'),
            ],
          ),
          const SizedBox(height: 24),
          _HowToSection(
            icon: Icons.qr_code_scanner,
            title: AppStrings.t('howto_2_title'),
            steps: [
              AppStrings.t('howto_2_step1'),
              AppStrings.t('howto_2_step2'),
              AppStrings.t('howto_2_step3'),
            ],
          ),
          const SizedBox(height: 24),
          _HowToSection(
            icon: Icons.people_outline,
            title: AppStrings.t('howto_3_title'),
            steps: [
              AppStrings.t('howto_3_step1'),
              AppStrings.t('howto_3_step2'),
              AppStrings.t('howto_3_step3'),
            ],
          ),
          const SizedBox(height: 24),
          _HowToSection(
            icon: Icons.star_border,
            title: AppStrings.t('howto_4_title'),
            steps: [
              AppStrings.t('howto_4_step1'),
              AppStrings.t('howto_4_step2'),
            ],
          ),
          const SizedBox(height: 24),
          _HowToSection(
            icon: Icons.warning_amber,
            title: AppStrings.t('howto_5_title'),
            steps: [
              AppStrings.t('howto_5_step1'),
              AppStrings.t('howto_5_step2'),
              AppStrings.t('howto_5_step3'),
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
