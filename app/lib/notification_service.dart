import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// ローカル通知(この端末の中だけで完結する通知)をまとめて扱うサービス。
///
/// 重要: これはFirebase Cloud Messaging(FCM)を使った本格的な
/// プッシュ通知ではない。アプリのプロセスが完全に終了している状態からは
/// 届かない場合がある。「アプリが起動中/バックグラウンドで動いている間に、
/// この端末自身がスケジュールした通知を鳴らす」仕組みに限定される。
///
/// 本格的なプッシュ通知(他のユーザーの操作をきっかけに、アプリが
/// 完全終了していても届く通知)には、Firebase Cloud Functions経由での
/// 送信が必要で、そのためにはFirebaseをBlazeプラン(従量課金プラン、
/// クレジットカード登録必須)にアップグレードする必要がある。
///
/// 注記: flutter_local_notifications 22.x系では、initialize/show/cancel/
/// zonedScheduleなどのメソッドが全て「名前付き引数のみ」を受け付ける
/// 仕様になっている(位置引数は一切使えない)ため、それに合わせて実装している。
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // このアプリは大阪工業大学(日本国内)向けのため、タイムゾーンを固定している。
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings: settings);

    // Android 13以降は通知の表示に明示的な許可が必要
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static const _channelId = 'suwaho_reminders';
  static const _channelName = 'すわほ通知';

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// QRチェックインから指定時間後に「まだ使いますか?」の通知を予約する。
  /// idはチェックアウト時に同じ値を渡すことでキャンセルできるようにするため、
  /// seatIdから決定的に生成する(seat_checkin_service.dart側で算出)。
  Future<void> scheduleCheckinReminder({
    required int id,
    required String seatId,
    required Duration delay,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: '座席を利用中です',
      body: '$seatId にチェックインしたままです。まだ利用していますか?',
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> showFriendRequestNotification(String fromName) async {
    await init();
    await _plugin.show(
      // フレンド申請の通知は複数来ても良いので、時刻をベースにしたidにする
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title: 'フレンド申請が届きました',
      body: '$fromName さんからフレンド申請が届いています',
      notificationDetails: _details,
    );
  }

  /// フレンドが座席にチェックインした(着席した)時の通知。
  /// この通知もアプリが起動中/バックグラウンドの間だけ有効。
  Future<void> showFriendSeatedNotification(String friendName, String seatId) async {
    await init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title: 'フレンドが着席しました',
      body: '$friendName さんが $seatId に着席しました',
      notificationDetails: _details,
    );
  }
}
