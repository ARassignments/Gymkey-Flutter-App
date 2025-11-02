import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../theme/theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _dragPosition = 0.0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Welcome to HomeStaff 360",
      description: "Revolutionary staff management solution",
      icon: Icons.people,
      color: Colors.blue.shade700,
    ),
    OnboardingPage(
      title: "Smart Scheduling",
      description: "Create optimal work schedules",
      icon: Icons.calendar_today,
      color: Colors.teal.shade600,
    ),
    OnboardingPage(
      title: "Real-time Tracking",
      description: "Monitor staff activities",
      icon: Icons.location_on,
      color: Colors.indigo.shade600,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Color with Animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            // color: _pages[_currentPage].color,
          ),

          // Custom Swipe Gesture Detection
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              setState(() {
                _dragPosition = 0.0;
              });
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragPosition = details.delta.dx;
              });
              _pageController.jumpTo(_pageController.offset - details.delta.dx);
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 100) {
                // Swipe right to left (previous page)
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              } else if (details.primaryVelocity! < -100) {
                // Swipe left to right (next page)
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              } else {
                // Snap back if swipe wasn't strong enough
                _pageController.animateToPage(
                  _currentPage,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            },
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              physics: const NeverScrollableScrollPhysics(), // Disable default scrolling
              children: _pages.map((page) => _buildPage(page)).toList(),
            ),
          ),

          // Page Indicator
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: CustomizableEffect(
                  activeDotDecoration: DotDecoration(
                    width: 24,
                    height: 8,
                    color: AppTheme.onBoardingDotActive(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  dotDecoration: DotDecoration(
                    width: 8,
                    height: 8,
                    color: AppTheme.onBoardingDot(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  spacing: 8,
                ),
              ),
            ),
          ),

          // Navigation Buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip Button
                  if (_currentPage != _pages.length - 1)
                    Expanded(
                      flex: 1,
                      child: GhostButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _pages.length - 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        text: "Skip",
                      ),
                    ),
              
                  // Next/Get Started Button
                  Expanded(
                    flex: 1,
                    child: FlatButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      text: _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                      icon: _currentPage == _pages.length - 1
                          ? Icons.check_rounded
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon based on drag position
          Transform.translate(
            offset: Offset(_dragPosition * 0.5, 0),
            child: Icon(
              page.icon,
              size: 100,
              color: Colors.white.withOpacity(1 - (_dragPosition.abs() / 500).clamp(0, 0.3)),
            ),
          ),
          const SizedBox(height: 30),
          // Animated text based on drag position
          Transform.translate(
            offset: Offset(_dragPosition * 0.3, 0),
            child: Text(
              page.title,
              style: AppTheme.textTitle(context),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Transform.translate(
            offset: Offset(_dragPosition * 0.2, 0),
            child: Text(
              page.description,
              style: AppTheme.textLabel(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}