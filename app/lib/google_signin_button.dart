import 'package:flutter/material.dart';

// デフォルト(Android/iOSなど)は google_signin_button_mobile.dart を使う。
// Webでビルドされる場合だけ google_signin_button_web.dart に差し替わる。
//
// google_sign_in_web パッケージはWeb専用ビルドの中でしか存在しないため、
// この条件付きインポートを使わずに直接importすると、
// Android/iOSのビルドが「パッケージが見つからない」で失敗してしまう。
export 'google_signin_button_mobile.dart'
    if (dart.library.js_interop) 'google_signin_button_web.dart';

/// 両実装が共通して満たすべきシグネチャ(ドキュメント用)。
/// 実際の関数はそれぞれのファイルで定義している。
typedef GoogleSignInButtonBuilder = Widget Function({
  required VoidCallback onPressed,
});
