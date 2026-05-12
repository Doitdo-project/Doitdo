import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

// ── 슬라이드 데이터 ─────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  final String imagePath;
  final String title;
  final String subtitle;
}

const _slides = [
  _Slide(
    imagePath: 'assets/images/damagochiPage.png',
    title: '할 일 완료가 곧 성장이에요',
    subtitle: '투두를 체크할 때마다 캐릭터 경험치가 올라가고\n7일 스트릭 달성 시 보상도 받을 수 있어요',
  ),
  _Slide(
    imagePath: 'assets/images/calendarPage.png',
    title: '투두와 일정을 한눈에',
    subtitle: '카테고리별 색상 점으로 할 일을 바로 구분하고\n스와이프로 주/월 보기도 자유롭게 전환해요',
  ),
  _Slide(
    imagePath: 'assets/images/repeatPage.png',
    title: '반복 일정도 쉽게 설정해요',
    subtitle: '매일·매주·특정 요일 반복을 원하는 대로 설정하고\n기간 일정도 자유롭게 추가할 수 있어요',
  ),
  _Slide(
    imagePath: 'assets/images/dragdropPage.png',
    title: '순서도 내 마음대로',
    subtitle: '홈과 캘린더에서 투두를 길게 눌러 드래그하면\n원하는 위치로 순서를 바꿀 수 있어요',
  ),
  _Slide(
    imagePath: 'assets/images/settingPage.png',
    title: '알림부터 테마까지 내 마음대로',
    subtitle: '아침/저녁 리마인더를 설정하고\n팔레트로 카테고리 색상을 자유롭게 바꿔요',
  ),
];

const _accent = Color(0xFFE07A2E);

// ── 페이지 ──────────────────────────────────────────────────

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, required this.next});

  final String next;

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    context.go(widget.next);
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 상단: 건너뛰기 ──────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLast ? 0.0 : 1.0,
                  child: GestureDetector(
                    onTap: isLast ? null : _dismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 4.h, horizontal: 2.w),
                      child: Text(
                        '건너뛰기',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 13.sp,
                          color: colors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // ── 폰 목업 이미지 카드 ──────────────────────────
            Expanded(
              flex: 11,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _PhoneCard(
                  slide: _slides[i],
                  showFingerOverlay: i == 3,
                ),
              ),
            ),

            SizedBox(height: 28.h),

            // ── 하단: 제목 + 부제 + 도트 + CTA ──────────────
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 36.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      slide.title,
                      key: ValueKey('title_$_currentPage'),
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 22.sp,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      slide.subtitle,
                      key: ValueKey('sub_$_currentPage'),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13.sp,
                        color: colors.textSecondary,
                        height: 1.65,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // 도트 인디케이터 (좌) + CTA 버튼 (우)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 도트
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                            width: active ? 20.w : 6.w,
                            height: 6.h,
                            margin: EdgeInsets.only(right: 5.w),
                            decoration: BoxDecoration(
                              color: active ? _accent : colors.border,
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          );
                        }),
                      ),

                      // CTA: 마지막 슬라이드 → 시작하기 pill / 중간 → 원형 화살표
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isLast
                            ? GestureDetector(
                                key: const ValueKey('start'),
                                onTap: _dismiss,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 22.w, vertical: 13.h),
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '시작하기',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                key: const ValueKey('next'),
                                onTap: _next,
                                child: Container(
                                  width: 48.w,
                                  height: 48.w,
                                  decoration: const BoxDecoration(
                                    color: _accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 폰 목업 카드 ─────────────────────────────────────────────

class _PhoneCard extends StatefulWidget {
  const _PhoneCard({required this.slide, this.showFingerOverlay = false});

  final _Slide slide;
  final bool showFingerOverlay;

  @override
  State<_PhoneCard> createState() => _PhoneCardState();
}

class _PhoneCardState extends State<_PhoneCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.showFingerOverlay) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: widget.showFingerOverlay
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Image.asset(
                          widget.slide.imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          alignment: Alignment.topCenter,
                          filterQuality: FilterQuality.high,
                        ),
                        Positioned(
                          top: constraints.maxHeight * 0.57,
                          right: constraints.maxWidth * 0.10,
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, __) => Opacity(
                              opacity: _pulse.value,
                              child: Transform.rotate(
                                angle: -0.3,
                                child: Icon(
                                  Icons.touch_app_rounded,
                                  size: 38.sp,
                                  color: Colors.black.withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : Image.asset(
                  widget.slide.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                ),
        ),
      ),
    );
  }
}

