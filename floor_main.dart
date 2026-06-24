import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'フロア選択UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansJP',
        useMaterial3: true,
      ),
      home: const FloorSelectPage(),
    );
  }
}

/// ===== カラーパレット =====
/// 元デザイン (すわほui-1.png) からピクセル抽出した値
class AppColors {
  static const Color mainGreen = Color(0xFF8DF172); // メインの緑
  static const Color lightGreen = Color(0xFFB3FF9E); // 薄い緑（ボタン・選択メニュー項目）
  static const Color bgGray = Color(0xFFF5F5F5); // ページ背景グレー
  static const Color gridGray = Color(0xFFD9D9D9); // フロアマップのグリッド
  static const Color overlayGray = Color(0xFFEBEBEB); // ドロワー表示時のコンテンツオーバーレイ
  static const Color skeletonGray = Color(0xFFE0E0E0); // ローディング用バー
}

/// =========================================================
/// 1. 最初のフロア選択画面
/// 「フロアを選択してください」 + 6F / 9F ボタン
/// タップすると即座に該当フロアの画面に遷移する
/// =========================================================
class FloorSelectPage extends StatelessWidget {
  const FloorSelectPage({super.key});

  void _goToFloor(BuildContext context, String floor) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero, // 動画では遷移はカットのように見えるため瞬時に切り替え
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => FloorMapPage(floor: floor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'フロアを選択してください',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              _FloorButton(
                label: '6F',
                onTap: () => _goToFloor(context, '6F'),
              ),
              const SizedBox(height: 16),
              _FloorButton(
                label: '9F',
                onTap: () => _goToFloor(context, '9F'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloorButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FloorButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightGreen,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          width: 140,
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// =========================================================
/// 2. フロアマップ画面（6F / 9F 共通）
/// 上部: ハンバーガーメニュー
/// 中央: フロアマップ（グリッド状のアイコン）— ローディングの
///       フェードアニメーションあり
/// 下部: 緑色のフロア表示バー
/// 左からDrawer（ハンバーガーメニュー）がスライドインする
/// =========================================================
class FloorMapPage extends StatefulWidget {
  final String floor;
  const FloorMapPage({super.key, required this.floor});

  @override
  State<FloorMapPage> createState() => _FloorMapPageState();
}

class _FloorMapPageState extends State<FloorMapPage> {
  late String _currentFloor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _startLoadingAnimation();
  }

  /// フロアマップのスケルトン→実体のフェード切り替えを
  /// ループ再生する（動画内で繰り返し見られたローディング表現）
  void _startLoadingAnimation() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  void _changeFloor(String floor) {
    setState(() {
      _currentFloor = floor;
    });
    _startLoadingAnimation();
    Navigator.of(context).pop(); // ドロワーを閉じる
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: FloorDrawer(
        currentFloor: _currentFloor,
        onFloorSelected: _changeFloor,
      ),
      // ドロワーが開いたときに本体が右にスライド＆縮小してグレーがかる
      // 動きを再現するため drawerScrimColor を使いつつ、Builder で
      // 本体コンテンツに少し縮小エフェクトを掛ける
      drawerScrimColor: Colors.black.withOpacity(0.08),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（ハンバーガーメニュー）
            Container(
              width: double.infinity,
              height: 48,
              color: AppColors.mainGreen,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            // フロアマップ本体
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isLoading
                    ? _FloorMapSkeleton(key: const ValueKey('skeleton'))
                    : _FloorMapContent(key: const ValueKey('content')),
              ),
            ),
            // フッター（現在のフロア表示）
            Container(
              width: double.infinity,
              height: 56,
              color: AppColors.mainGreen,
              alignment: Alignment.center,
              child: Text(
                _currentFloor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// フロアマップのスケルトン（ローディング時の薄いプレースホルダー）
class _FloorMapSkeleton extends StatelessWidget {
  const _FloorMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: 35,
              itemBuilder: (_, i) => Container(
                color: AppColors.gridGray.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(width: 80, height: 16, color: AppColors.skeletonGray),
              const SizedBox(width: 12),
              Container(width: 80, height: 16, color: AppColors.skeletonGray),
            ],
          ),
        ],
      ),
    );
  }
}

/// フロアマップの実体（グリッド状のアイコン配置）
class _FloorMapContent extends StatelessWidget {
  const _FloorMapContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: 35,
              itemBuilder: (_, i) => Container(
                color: AppColors.gridGray,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(width: 80, height: 16, color: AppColors.gridGray),
              const SizedBox(width: 12),
              Container(width: 80, height: 16, color: AppColors.gridGray),
            ],
          ),
        ],
      ),
    );
  }
}

/// =========================================================
/// 3. ドロワー（ハンバーガーメニュー）
/// 1階層目: 「フロア選択」「使い方」 ヘッダーは × ボタン
/// 2階層目（フロア選択タップ後）: 「6F」「9F」一覧 ヘッダーは ← ボタン
/// AnimatedSwitcher で階層間をスライド切り替え
/// =========================================================
class FloorDrawer extends StatefulWidget {
  final String currentFloor;
  final ValueChanged<String> onFloorSelected;

  const FloorDrawer({
    super.key,
    required this.currentFloor,
    required this.onFloorSelected,
  });

  @override
  State<FloorDrawer> createState() => _FloorDrawerState();
}

enum _DrawerView { menu, floorList }

class _FloorDrawerState extends State<FloorDrawer> {
  _DrawerView _view = _DrawerView.menu;

  void _openFloorList() {
    setState(() => _view = _DrawerView.floorList);
  }

  void _backToMenu() {
    setState(() => _view = _DrawerView.menu);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.mainGreen,
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            // ヘッダー：× または ← で切り替え
            Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _view == _DrawerView.menu
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _backToMenu,
                    ),
            ),
            // 本体：AnimatedSwitcher でスライドしながら切り替え
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  final inSlide = Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: inSlide,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _view == _DrawerView.menu
                    ? _DrawerMenuList(
                        key: const ValueKey('menu'),
                        onFloorSelectTap: _openFloorList,
                      )
                    : _DrawerFloorList(
                        key: const ValueKey('floorList'),
                        currentFloor: widget.currentFloor,
                        onFloorTap: widget.onFloorSelected,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ドロワー：1階層目「フロア選択」「使い方」
class _DrawerMenuList extends StatelessWidget {
  final VoidCallback onFloorSelectTap;

  const _DrawerMenuList({super.key, required this.onFloorSelectTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DrawerItem(label: 'フロア選択', onTap: onFloorSelectTap),
        const Divider(height: 1, color: AppColors.mainGreen),
        _DrawerItem(label: '使い方', onTap: () {}),
      ],
    );
  }
}

/// ドロワー：2階層目「6F」「9F」一覧
class _DrawerFloorList extends StatelessWidget {
  final String currentFloor;
  final ValueChanged<String> onFloorTap;

  const _DrawerFloorList({
    super.key,
    required this.currentFloor,
    required this.onFloorTap,
  });

  @override
  Widget build(BuildContext context) {
    const floors = ['6F', '9F'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final floor in floors) ...[
          _DrawerItem(
            label: floor,
            selected: floor == currentFloor,
            onTap: () => onFloorTap(floor),
          ),
        ],
      ],
    );
  }
}

/// ドロワー共通の項目（タップでハイライトする薄緑の背景）
class _DrawerItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lightGreen : AppColors.mainGreen,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.lightGreen,
        highlightColor: AppColors.lightGreen,
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}