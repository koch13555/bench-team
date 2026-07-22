import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'notification_settings.dart';

/// 設定画面。通知のON/OFFと、表示言語(日本語/英語)をまとめて変更できる。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = NotificationSettings.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('settings_title'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(AppStrings.t('settings_notifications_heading'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          SwitchListTile(
            title: Text(AppStrings.t('settings_notif_friend_request')),
            subtitle: Text(AppStrings.t('settings_notif_friend_request_sub')),
            value: _settings.friendRequestEnabled,
            onChanged: (value) async {
              await _settings.setFriendRequestEnabled(value);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(AppStrings.t('settings_notif_friend_seated')),
            subtitle: Text(AppStrings.t('settings_notif_friend_seated_sub')),
            value: _settings.friendSeatedEnabled,
            onChanged: (value) async {
              await _settings.setFriendSeatedEnabled(value);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(AppStrings.t('settings_notif_checkin_reminder')),
            subtitle: Text(AppStrings.t('settings_notif_checkin_reminder_sub')),
            value: _settings.checkinReminderEnabled,
            onChanged: (value) async {
              await _settings.setCheckinReminderEnabled(value);
              setState(() {});
            },
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(AppStrings.t('settings_language_heading'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.t('settings_language_note'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: AppLanguage.instance,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ja', label: Text('日本語')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {AppLanguage.instance.code},
                  onSelectionChanged: (selected) {
                    AppLanguage.instance.setLanguage(selected.first);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
