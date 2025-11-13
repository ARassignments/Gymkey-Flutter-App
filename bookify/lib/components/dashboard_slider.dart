import '/utils/themes/themes.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DashboardSlider extends StatefulWidget {
  final List<Widget> slidesData;
  const DashboardSlider({super.key, required this.slidesData});

  @override
  State<DashboardSlider> createState() => _DashboardSliderState();
}

class _DashboardSliderState extends State<DashboardSlider> {
  bool _isLoading = false;
  final CarouselSliderController _carouselController = CarouselSliderController();

  final List<String> sliderImages = [
    'https://plus.unsplash.com/premium_photo-1663931932651-ea743c9a0144?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1470',
    'https://images.unsplash.com/photo-1643101681441-0c38d714fa14?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1332',
    'https://plus.unsplash.com/premium_photo-1663931932688-306b0197d388?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1pbi1zYW1lLXNlcmllc3wxfHx8ZW58MHx8fHx8&auto=format&fit=crop&q=60&w=500',
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _isLoading ? _buildShimmerPlaceholder() : _buildImageCarousel(context),
        const SizedBox(height: 12),
        if (!_isLoading) _buildSmoothIndicator(context),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 🟣 Shimmer Placeholder
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppTheme.customListBg(context),
      highlightColor: AppTheme.sliderHighlightBg(context),
      child: CarouselSlider.builder(
        itemCount: 1,
        itemBuilder: (context, index, realIndex) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.customListBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
        options: CarouselOptions(
          height: 200,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
        ),
      ),
    );
  }

  /// 🟢 Actual Carousel
  Widget _buildImageCarousel(BuildContext context) {
    return CarouselSlider.builder(
      carouselController: _carouselController,
      itemCount: widget.slidesData.length,
      itemBuilder: (context, index, realIndex) {
        return widget.slidesData[index];
      },
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        clipBehavior: Clip.antiAlias,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        viewportFraction: 0.9,
        autoPlayInterval: const Duration(seconds: 3),
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// 🔵 SmoothPageIndicator
  Widget _buildSmoothIndicator(BuildContext context) {
    return AnimatedSmoothIndicator(
      activeIndex: _currentIndex,
      count: widget.slidesData.length,
      effect: CustomizableEffect(
        spacing: 8,
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
      ),
      onDotClicked: (index) {
        _carouselController.animateToPage(index);
      },
    );
  }
}
