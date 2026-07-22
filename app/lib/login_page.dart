import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'google_signin_button.dart';
import 'app_localizations.dart';

/// アプリ初回起動時に表示するログイン画面。
/// Google / Apple / メールアドレスでのログイン・新規登録に対応。
/// (LINEログインは今回未対応。将来Cloud Functions側を実装したら追加予定)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  StreamSubscription<Object>? _webGoogleErrorSub;

  bool get _showAppleButton => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    // Web版のGoogle公式ボタン(renderButton)は、事前にinitialize()が
    // 呼ばれていないと使えないため、画面表示前にここで済ませておく。
    _authService.ensureGoogleInitialized();
    // Web版はボタン自体がログインを完結させるため、
    // 失敗した場合のエラーだけこちらで受け取ってスナックバー表示する。
    _webGoogleErrorSub = _authService.webGoogleSignInErrors.listen((error) {
      _showError('Googleログインに失敗しました: $error');
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _webGoogleErrorSub?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      // 成功するとFirebaseのauthStateChangesが発火し、
      // main.dartのAuthGateが自動でHomePageに切り替えてくれる。
    } catch (e) {
      _showError('ログインに失敗しました: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() => _run(_authService.signInWithGoogle);

  Future<void> _handleApple() => _run(_authService.signInWithApple);

  Future<void> _handleGuest() => _run(_authService.signInAsGuest);

  /// メールアドレスを入力してもらい、パスワード再設定メールを送る
  Future<void> _handleForgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(initialEmail: _emailController.text),
    );
    if (email == null || email.isEmpty) return;

    try {
      await _authService.sendPasswordResetEmail(email);
      _showMessage('$email 宛にパスワード再設定メールを送信しました');
    } catch (e) {
      _showError('メールの送信に失敗しました: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF106E00)),
    );
  }

  Future<void> _handleEmailSubmit() {
    final email = _emailController.text;
    final password = _passwordController.text;
    final name = _nameController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('メールアドレスとパスワードを入力してください');
      return Future.value();
    }
    if (_isRegisterMode && name.trim().isEmpty) {
      _showError('お名前を入力してください');
      return Future.value();
    }

    return _run(() async {
      if (_isRegisterMode) {
        await _authService.registerWithEmail(
          email: email,
          password: password,
          displayName: name,
        );
      } else {
        await _authService.signInWithEmail(email, password);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8DF172),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_seat, size: 56, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  AppStrings.t('app_title'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  // Android/iOSは従来ボタン、Webは自動的にGoogle公式ボタンに切り替わる
                  buildGoogleSignInButton(onPressed: _handleGoogle),
                  if (_showAppleButton) ...[
                    const SizedBox(height: 12),
                    _SocialButton(
                      label: AppStrings.t('login_apple'),
                      icon: Icons.apple,
                      onTap: _handleApple,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white54)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(AppStrings.t('or_divider'), style: const TextStyle(color: Colors.white)),
                      ),
                      const Expanded(child: Divider(color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        if (_isRegisterMode) ...[
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: AppStrings.t('label_name'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: AppStrings.t('label_email'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: AppStrings.t('label_password'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleEmailSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF106E00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(_isRegisterMode ? AppStrings.t('button_register') : AppStrings.t('button_login')),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => _isRegisterMode = !_isRegisterMode);
                          },
                          child: Text(
                            _isRegisterMode
                                ? AppStrings.t('switch_to_login')
                                : AppStrings.t('switch_to_register'),
                          ),
                        ),
                        if (!_isRegisterMode)
                          TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(AppStrings.t('forgot_password')),
                          ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _handleGuest,
                          child: Text(
                            AppStrings.t('guest_login'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.black87),
        label: Text(label, style: const TextStyle(color: Colors.black87)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// パスワード再設定用のメールアドレス入力ダイアログ
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _controller = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('パスワードを再設定'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '登録済みのメールアドレスを入力してください。\n再設定用のリンクを記載したメールをお送りします。',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppStrings.t('label_email'),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('送信'),
        ),
      ],
    );
  }
}
