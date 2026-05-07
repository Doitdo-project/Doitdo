import 'dart:math' show pi, sin;

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
                  showDragDemo: i == 3,
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

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.slide, this.showDragDemo = false});

  final _Slide slide;
  final bool showDragDemo;

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
          child: showDragDemo
              ? const _DragDropDemo()
              : Image.asset(
                  slide.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  alignment: Alignment.topCenter,
                ),
        ),
      ),
    );
  }
}

// ── 드래그앤드롭 데모 (순수 Flutter, 이미지 불필요) ──────────

class _DragDropDemo extends StatefulWidget {
  const _DragDropDemo();

  @override
  State<_DragDropDemo> createState() => _DragDropDemoState();
}

class _DragDropDemoState extends State<_DragDropDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final t = _progress.value; // 0↔1 (reverse: true)
            final cardH = 54.h;
            final gap = 10.h;
            final spacing = cardH + gap;

            // 카드1: 위 → 아래, 카드2: 아래 → 위
            final startY = h * 0.27;
            final card1Top = startY + t * spacing;
            final card2Top = startY + (1.0 - t) * spacing;

            // t=0.5 일 때 리프트 최대 (sin 커브)
            final lift = sin(pi * t);
            final scale1 = 1.0 + 0.04 * lift;
            final shadowBlur = 4.0 + 20.0 * lift;
            final shadowAlpha = 0.06 + 0.18 * lift;

            // 손가락: 카드1 우측 중앙에 위치
            final fingerTop = card1Top + cardH / 2 - 14.h;
            final fingerRight = w * 0.08;

            return Stack(
              children: [
                // ── 폰 화면 배경 ─────────────────────────
                Container(color: const Color(0xFFF5F2EC)),

                // ── 상단 헤더 ─────────────────────────────
                Positioned(
                  top: h * 0.07,
                  left: 20.w,
                  right: 20.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 할 일',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF231C16),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '길게 눌러 순서를 바꿔보세요',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF9A8E80),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 카드2 (뒤쪽 — 먼저 그려야 카드1 위에 올라옴) ───
                Positioned(
                  top: card2Top,
                  left: 20.w,
                  right: 20.w,
                  child: _DemoCard(
                    label: '공부하기',
                    dotColor: const Color(0xFF5C6BC0),
                    elevated: false,
                  ),
                ),

                // ── 카드1 (드래그 중 — 위에 그려짐) ─────────────
                Positioned(
                  top: card1Top,
                  left: 20.w,
                  right: 20.w,
                  child: Transform.scale(
                    scale: scale1,
                    child: _DemoCard(
                      label: '운동하기',
                      dotColor: _accent,
                      elevated: true,
                      shadowBlur: shadowBlur,
                      shadowAlpha: shadowAlpha,
                    ),
                  ),
                ),

                // ── 정적 카드3 (하단 컨텍스트) ───────────────────
                Positioned(
                  top: startY + spacing * 2 + gap,
                  left: 20.w,
                  right: 20.w,
                  child: Opacity(
                    opacity: 0.45,
                    child: _DemoCard(
                      label: '집안일 정리',
                      dotColor: const Color(0xFF66BB6A),
                      elevated: false,
                    ),
                  ),
                ),

                // ── 손가락 커서 ───────────────────────────────
                Positioned(
                  top: fingerTop,
                  right: fingerRight,
                  child: Opacity(
                    opacity: 0.85,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Icon(
                        Icons.touch_app_rounded,
                        size: 28.sp,
                        color: const Color(0xFF231C16).withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.label,
    required this.dotColor,
    required this.elevated,
    this.shadowBlur = 4.0,
    this.shadowAlpha = 0.06,
  });

  final String label;
  final Color dotColor;
  final bool elevated;
  final double shadowBlur;
  final double shadowAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowAlpha),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowBlur / 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF231C16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
