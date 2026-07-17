import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// このプロジェクトのRealtime DatabaseのURL(東南アジアリージョン)。
///
/// 重要: これまで一部のファイルは `FirebaseDatabase.instance`(URL指定なし)、
/// 別のファイルは `FirebaseDatabase.instanceFor(databaseURL: ...)` と、
/// 接続方法がバラバラだった。この不一致がWeb版で
/// 「FIREBASE FATAL ERROR: Database initialized multiple times」の原因になっていたため、
/// 今後はアプリ内のどこからでも必ずこの [appDatabase] 経由でアクセスすること。
const String kFirebaseDatabaseUrl =
    'https://bench-team-app-default-rtdb.asia-southeast1.firebasedatabase.app';

FirebaseDatabase get appDatabase => FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kFirebaseDatabaseUrl,
    );
