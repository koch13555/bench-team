import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Google / Apple / メールアドレスでのログイン・新規登録をまとめて扱うサービス。
///
/// 注意: LINEログインは今回未対応です。
/// Firebase AuthにはLINE用の標準プロバイダーがないため、
/// 対応する場合はCloud FunctionsでLINEのアクセストークンを検証し、
/// Firebaseのカスタムトークンを発行する処理を別途作る必要があります。
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // google_sign_in 7.x からはコンストラクタでのインスタンス生成が廃止され、
  // シングルトンの GoogleSignIn.instance を使う方式に変わった。
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  /// 現在ログイン中のユーザー(未ログインならnull)
  User? get currentUser => _auth.currentUser;

  /// ログイン状態の変化を監視するStream。
  /// main.dart側のAuthGateがこれを見てLoginPage/HomePageを切り替える。
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// v7からは使用前に一度だけ initialize() を呼ぶ必要がある。
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  /// Googleアカウントでログイン。
  /// ユーザーが選択ダイアログをキャンセルした場合はnullを返す。
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleInitialized();

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
    await _ensureGoogleInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}