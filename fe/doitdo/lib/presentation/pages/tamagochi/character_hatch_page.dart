import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 알을 10회 두드려 부화시키는 전용 전체화면.
///
/// 10회 탭 완료 → `POST /api/characters/me/hatch` → 성공 시 이름짓기 페이지로
/// `pushReplacement` (뒤로가기가 부화 페이지로 돌아가지 않도록). 실패 시 카운터
/// 리셋 후 스낵바.
class CharacterHatchPage extends ConsumerStatefulWidget {
  const CharacterHatchPage({super.key});

  static const int requiredTaps = 10;

  @override
  ConsumerState<CharacterHatchPage> createState() =>
      _CharacterHatchPageState();
}

class _CharacterHatchPageState extends ConsumerState<CharacterHatchPage>
    with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  bool _hatching = false;
  late final AnimationController _bump;

  @override
  void initState() {
    super.initState();
    _bump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_hatching) return;
    HapticFeedback.lightImpact();
    _bump.forward(from: 0).then((_) => _bump.reverse());

    final next = _tapCount + 1;
    if (next < CharacterHatchPage.requiredTaps) {
      setState(() => _tapCount = next);
      return;
    }

    setState(() {
      _tapCount = next;
      _hatching = true;
    });

    final ok =
        await ref.read(characterViewModelProvider.notifier).hatchEgg();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _tapCount = 0;
        _hatching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알을 깨우는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }
    context.pushReplacement(AppRoutes.tamagochiNaming);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = CharacterHatchPage.requiredTaps - _tapCount;
    final title = _hatching ? '부화 중...' : '$remaining번 더';
    final eggImageUrl =
        ref.watch(characterViewModelProvider).valueOrNull?.thumbnailUrl ?? '';

    return DoitdoScaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontSize: 40.sp,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  AnimatedBuilder(
                    animation: _bump,
                    builder: (context, child) {
                      final scale = 1.0 + _bump.value * 0.12;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: _HatchEggImage(
                      imageUrl: eggImageUrl,
                      size: 180.sp,
                      fallbackColor: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 60.h),
                  Icon(
                    Icons.touch_app,
                    size: 40.sp,
                    color: colors.textHint,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '화면을 톡톡 두드려 알을 깨워주세요',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 뒤로가기(부화 포기) — 실수 탭으로 홀랑 들어와도 빠져나갈 수 있게.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: IconButton(
              icon: Icon(Icons.close, color: colors.textPrimary),
              onPressed: _hatching ? null : () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 부화 페이지의 큰 알 이미지. 서버 URL 사용, 실패/빈값이면 Icons.egg fallback.
class _HatchEggImage extends StatelessWidget {
  const _HatchEggImage({
    required this.imageUrl,
    required this.size,
    required this.fallbackColor,
  });

  final String imageUrl;
  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _fallback();
    return Image.network(
      imageUrl,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() =>
      Icon(Icons.egg, size: size, color: fallbackColor);
}