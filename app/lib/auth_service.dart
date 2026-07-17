import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Google / Apple / メールアドレスでのログイン・新規登録をまとめて扱うサービス。
///
/// 注意: LINEログインは今回未対応です。
/// Firebase AuthにはLINE用の標準プロバイダーがないため、
/// 対応する場合はCloud FunctionsでLINEのアクセストークンを検証し、
/// Firebaseのカスタムトークンを発行する処理を別途作る必要があります。
///
/// Googleログインについて(重要):
/// google_sign_in 7.x以降、Webでは`authenticate()`が使えず、
/// Googleが提供する公式ボタン(renderButton)経由でしかログインできない仕様になった。
/// そのため、Web版はGoogleの公式ボタンがユーザー操作を受け取った後に発生する
/// `authenticationEvents`を購読し、そこでFirebaseへのサインインを完了させる方式にしている。
/// Android/iOSは従来通り、ボタン押下から`authenticate()`を直接呼ぶ方式のまま。
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  /// Web版でGoogleログインに失敗した際のエラーを受け取るためのストリーム。
  /// login_page.dart側でエラーメッセージ表示に使う。
  final _webGoogleErrorController = StreamController<Object>.broadcast();
  Stream<Object> get webGoogleSignInErrors => _webGoogleErrorController.stream;

  /// 現在ログイン中のユーザー(未ログインならnull)
  User? get currentUser => _auth.currentUser;

  /// 現在のユーザーがゲスト(匿名ログイン)かどうか。
  /// フレンド機能の表示可否を判定する際に、画面側からこれを参照する。
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  /// ログイン状態の変化を監視するStream。
  /// main.dart側のAuthGateがこれを見てLoginPage/HomePageを切り替える。
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// v7からは使用前に一度だけ initialize() を呼ぶ必要がある。
  /// Webの場合はここで認証完了イベントの購読も行う。
  Future<void> ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;

    if (kIsWeb) {
      // Web版: Googleの公式ボタン(renderButton)がログインを完了させると
      // この authenticationEvents に GoogleSignInAuthenticationEventSignIn が流れてくる。
      // ここでFirebaseへのサインインまで完了させる。
      _googleSignIn.authenticationEvents.listen((event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          try {
            final googleAuth = event.user.authentication;
            final credential = GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
            );
            await _auth.signInWithCredential(credential);
          } catch (e) {
            _webGoogleErrorController.add(e);
          }
        }
      }, onError: (Object e) => _webGoogleErrorController.add(e));
    }
  }

  /// Googleアカウントでログイン(Android / iOS向け)。
  /// Webでは使えないので、Web版はlogin_page.dart側で公式ボタンを直接表示する。
  /// ユーザーが選択ダイアログをキャンセルした場合はnullを返す。
  Future<UserCredential?> signInWithGoogle() async {
    await ensureGoogleInitialized();

    try {
      // v7からは signIn() ではなく authenticate() を使う(認証=身元確認)
      final googleUser = await _googleSignIn.authenticate();

      // v7からは authentication が同期プロパティになった
      final googleAuth = googleUser.authentication;

      // accessTokenは「認可(authorization)」側の責務に分離されたため、
      // authorizationClient経由で別途取得する。
      final authorization =
          await googleUser.authorizationClient.authorizeScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: authorization.accessToken,
      );

      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // ユーザーがキャンセルした場合は静かにnullを返す
        return null;
      }
      rethrow;
    }
  }

  /// Apple IDでログイン(iOS / macOS向け)。
  Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Appleは初回ログイン時にしか氏名を返さない仕様のため、
    // 未設定であればここでdisplayNameに反映しておく。
    final user = userCredential.user;
    if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
      final givenName = appleCredential.givenName ?? '';
      final familyName = appleCredential.familyName ?? '';
      final fullName = ('$familyName $givenName').trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
        await user.reload();
      }
    }

    return userCredential;
  }

  /// ゲストログイン(匿名認証)。
  /// 座席の空き状況の閲覧・QRチェックインは可能だが、
  /// フレンド機能(誰がどこに座っているかの把握)は利用できない。
  /// この制限はUI側で隠すだけでなく、Firebase側のセキュリティルールでも
  /// 二重に強制すること(sign_in_provider が anonymous の場合は
  /// friends / friend_requests への書き込みを拒否する)が望ましい。
  Future<UserCredential> signInAsGuest() {
    return _auth.signInAnonymously();
  }

  /// メールアドレス + パスワードでログイン
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// メールアドレス + パスワードで新規登録し、表示名(displayName)も設定する
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await credential.user?.reload();
    return credential;
  }

  /// ログアウト(Google経由でログインしていた場合も含めて解除)
  Future<void> signOut() async {
    await ensureGoogleInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
