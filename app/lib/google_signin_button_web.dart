import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Web向け: google_sign_in 7.x以降、Webでは独自ボタン+authenticate()が使えず、
/// Google公式が描画するボタン(renderButton)を表示するしかない仕様になっている。
/// このボタン自体がクリックからログイン完了までを内部で処理し、
/// 完了すると AuthService 側で購読している authenticationEvents に通知が来る。
///
/// そのため[onPressed]はWeb版では使わない(公式ボタンが自動でログインを開始するため)。
Widget buildGoogleSignInButton({required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 44,
    child: Center(child: web.renderButton()),
  );
}
