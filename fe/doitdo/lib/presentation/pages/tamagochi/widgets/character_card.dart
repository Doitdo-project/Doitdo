import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';

/// 다마고치 메인 상단의 초록 배경 카드.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.state,
    this.onTapShop,
    this.onTapCollection,
  });

  final TamagochiState state;
  final VoidCallback? onTapShop;
  final VoidCallback? onTapCollection;

  // 카드 배경이 테마와 무관하게 고정이라 DoitdoColors 가 아닌 로컬 상수.
  static const Color _expBarBg = Color(0xFF3F4A3A);
  static const Color _expBarFill = Color(0xFFF5D33C);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_grass.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),

          // 중앙: 말풍선 + 캐릭터
          // bottom 을 EXP 영역 높이만큼 비워 경험치 바와 겹치지 않게 한다.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 24.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.speechBubble != null) ...[
                  _SpeechBubble(text: state.speechBubble!),
                  SizedBox(height: 6.h),
                ],
                const _CharacterImage(),
              ],
            ),
          ),

          // 우측 상단 아이콘 (상점 / 도감)
          Positioned(
            top: 8.h,
            right: 16.w,
            child: Column(
              children: [
                _RoundIconButton(
                  icon: Icons.shopping_basket_outlined,
                  onTap: onTapShop,
                ),
                SizedBox(height: 8.h),
                _RoundIconButton(
                  icon: Icons.menu_book_outlined,
                  onTap: onTapCollection,
                ),
              ],
            ),
          ),

          // 하단: 레벨/EXP 텍스트 + 경험치 바
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: 14.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LV${state.level}. ${state.characterName}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '레벨업까지 ${state.expToNextLevel - state.currentExp} EXP',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: state.expProgress,
                    minHeight: 10.h,
                    backgroundColor: _expBarBg,
                    valueColor: const AlwaysStoppedAnimation(_expBarFill),
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Icon(icon, size: 20.sp, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}

/// 다마고치 캐릭터 이미지. 추후 Lottie 로 교체 가능.
class _CharacterImage extends StatelessWidget {
  const _CharacterImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/tama_hanrabong.png',
      height: 100.h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}