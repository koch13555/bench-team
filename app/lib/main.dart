import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'firebase_db.dart';
import 'seat_widget.dart'; // floor_select_page.dartから変更
import 'login_page.dart';
import 'notification_service.dart';
import 'onboarding_page.dart';

/// 画面遷移(他の画面から戻ってきたタイミングなど)を検知するための仕組み。
/// キャンパス一覧のお気に入り並び替えなど、「画面に戻ってきた時だけ更新したい」
/// 処理で使う(seat_widget.dart側でRouteAwareを使って購読する)。
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// 座席データの初期化
Future<void> initializeSeats() async {
  final db = appDatabase.ref('seats');
  final snapshot = await db.get();

  // データがない場合のみ初期化
  if (!snapshot.exists) {
    for (int i = 1; i <= 35; i++) {
      final seatId = 'seat_${i.toString().padLeft(2, '0')}';
      await db.child(seatId).set({
        'occupied': false,
        'startTime': '',
      });
    }
    print('座席データを初期化しました');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 権限エラー(セキュリティルールでログイン必須にした場合など)が起きても
  // アプリ全体がクラッシュしてrunApp()が呼ばれなくなるのを防ぐ。
  // (座席データは既に存在しているはずなので、ここで失敗しても実害はない)
  try {
    await initializeSeats();
  } catch (e) {
    debugPrint('initializeSeatsをスキップしました: $e');
  }

  // ローカル通知の初期化(失敗しても致命的ではないので同様にtry-catchで保護)
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('通知サービスの初期化をスキップしました: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'すわほ',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _RootGate(),
    );
  }
}

/// アプリの一番最初の入り口。
/// 初回起動時だけチュートリアル(OnboardingPage)を表示し、
/// 2回目以降はAuthGate(ログイン判定)に直接進む。
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final seen = await OnboardingPage.hasSeenOnboarding();
    if (mounted) setState(() => _hasSeenOnboarding = seen);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasSeenOnboarding == false) {
      return OnboardingPage(
        onFinished: () => setState(() => _hasSeenOnboarding = true),
      );
    }
    return const AuthGate();
  }
}

/// ログイン状態を監視して、未ログインならLoginPage、
/// ログイン済みならHomePageを表示する入り口ウィジェット。
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 起動直後、ログイン状態を確認中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
