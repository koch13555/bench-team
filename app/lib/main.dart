import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'firebase_db.dart';
import 'seat_widget.dart'; // floor_select_page.dartから変更
import 'login_page.dart';

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
  await initializeSeats(); // ← 追加
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '座席管理システム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
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
