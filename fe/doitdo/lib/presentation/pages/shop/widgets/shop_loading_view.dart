import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 상점 진입 시 표시되는 로딩 뷰.
///
/// shop_loading.gif (픽셀 캐릭터 + 줄자) + 사이클 메시지 + 점 애니메이션.
/// 픽셀 결을 살리되 흐릿함을 피하려 [FilterQuality.medium] 사용 —
/// character_card 의 idle gif 와 동일한 정책.
class ShopLoadingView extends StatefulWidget {
  const ShopLoadingView({super.key});

  @override
  State<ShopLoadingView> createState() => _ShopLoadingViewState();
}

class _ShopLoadingViewState extends State<ShopLoadingView>
    with TickerProviderStateMixin {
  static const _messages = <String>[
    '상점을 여는 중',
    '가구를 진열하는 중',
    '코인을 세는 중',
    '진열대를 닦는 중',
  ];

  late final Timer _messageTimer;
  late final AnimationController _dotsController;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _messageTimer.cancel();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyle =
        AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/animations/shop_loading.gif',
            width: 130.w,
            height: 130.w,
            filterQuality: FilterQuality.medium,
            opacity: const AlwaysStoppedAnimation(.85),
          ),
          SizedBox(height: 8.h),
          // 220.w 고정 폭 안에서 메시지+점을 가운데 정렬 → 메시지 길이가 바뀌어도
          // 외곽 Center 가 매번 재정렬하면서 들썩이지 않는다.
          SizedBox(
            width: 220.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    _messages[_messageIndex],
                    key: ValueKey(_messageIndex),
                    style: textStyle,
                  ),
                ),
                // 점 3개 자리 고정 폭 — 점 개수가 바뀌어도 가로가 안 흔들린다.
                SizedBox(
                  width: 14.w,
                  child: AnimatedBuilder(
                    animation: _dotsController,
                    builder: (context, _) {
                      final n = (_dotsController.value * 3).floor() + 1;
                      return Text('.' * n, style: textStyle);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
