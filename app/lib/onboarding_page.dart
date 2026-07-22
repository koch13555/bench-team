import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

/// アプリを初めて開いた時だけ表示するチュートリアル画面。
/// 一度見たら、次回以降は表示しない(端末内にフラグを保存する)。
class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingPage({super.key, required this.onFinished});

  /// このフラグがtrueなら、既にチュートリアルを見たことがある。
  static const _prefsKey = 'has_seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

List<_OnboardingSlide> _buildSlides() => [
  _OnboardingSlide(
    icon: Icons.event_seat,
    title: AppStrings.t('onboarding_title_1'),
    description: AppStrings.t('onboarding_desc_1'),
  ),
  _OnboardingSlide(
    icon: Icons.qr_code_scanner,
    title: AppStrings.t('onboarding_title_2'),
    description: AppStrings.t('onboarding_desc_2'),
  ),
  _OnboardingSlide(
    icon: Icons.people_outline,
    title: AppStrings.t('onboarding_title_3'),
    description: AppStrings.t('onboarding_desc_3'),
  ),
  _OnboardingSlide(
    icon: Icons.warning_amber,
    title: AppStrings.t('onboarding_title_4'),
    description: AppStrings.t('onboarding_desc_4'),
  ),
];

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPage.markAsSeen();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides();
    final isLast = _currentPage == slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF8DF172),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(AppStrings.t('onboarding_skip'), style: const TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 64, color: const Color(0xFF106E00)),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.6),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ページインジケーター(ドット)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage ? Colors.white : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLast
                      ? _finish
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF106E00),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isLast ? AppStrings.t('onboarding_start') : AppStrings.t('onboarding_next')),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
