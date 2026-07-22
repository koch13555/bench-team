import 'package:shared_preferences/shared_preferences.dart';

/// 通知のON/OFF設定を端末に保存して管理するクラス。
/// 設定画面(settings_page.dart)のスイッチと、
/// 実際に通知を送る箇所(seat_widget.dart / seat_checkin_service.dart)の
/// 両方から参照する。
class NotificationSettings {
  NotificationSettings._();
  static final NotificationSettings instance = NotificationSettings._();

  static const _keyFriendRequest = 'notif_friend_request';
  static const _keyFriendSeated = 'notif_friend_seated';
  static const _keyCheckinReminder = 'notif_checkin_reminder';

  bool friendRequestEnabled = true;
  bool friendSeatedEnabled = true;
  bool checkinReminderEnabled = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    friendRequestEnabled = prefs.getBool(_keyFriendRequest) ?? true;
    friendSeatedEnabled = prefs.getBool(_keyFriendSeated) ?? true;
    checkinReminderEnabled = prefs.getBool(_keyCheckinReminder) ?? true;
  }

  Future<void> setFriendRequestEnabled(bool value) async {
    friendRequestEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFriendRequest, value);
  }

  Future<void> setFriendSeatedEnabled(bool value) async {
    friendSeatedEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFriendSeated, value);
  }

  Future<void> setCheckinReminderEnabled(bool value) async {
    checkinReminderEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCheckinReminder, value);
  }
}
