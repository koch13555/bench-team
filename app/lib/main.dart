import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'floor_select_page.dart';
import 'receive_service.dart';

// 座席データの初期化
Future<void> initializeSeats() async {
  final db = FirebaseDatabase.instance.ref('seats');
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
      home: const FloorSelectPage(),
    );
  }
}