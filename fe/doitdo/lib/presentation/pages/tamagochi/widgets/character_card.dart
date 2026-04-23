import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';

/// 다마고치 메인 상단의 초록 배경 카드.
///
/// [character] 는 `/api/characters/me` 결과. null 이면 아직 알을 수령 전이라
/// "알 받기" CTA 를 노출한다. isEgg 인 경우 알 이미지 + 탭 가이드를 덮는다.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.state,
    this.character,
    this.isCharacterLoading = false,
    this.onTapShop,
    this.onTapCollection,
    this.onHatch,
  });

  final TamagochiState state;
  final Character? character;

  /// 최초 캐릭터 조회 중일 때 true. 캐릭터 영역만 살짝 가리는 용도.
  final bool isCharacterLoading;

  final VoidCallback? onTapShop;
  final VoidCallback? onTapCollection;

  /// 알 10회 탭이 완료됐을 때. 여기에서 부화 API 호출 + 이름짓기 페이지 이동을
  /// 파이프라인으로 수행한다. 반환 Future 가 끝나면 _EggSlot 은 카운터를 리셋한다.
  final Future<void> Function()? onHatch;

  // 카드 배경이 테마와 무관하게 고정이라 DoitdoColors 가 아닌 로컬 상수.
  static const Color _expBarBg = Color(0xFF3F4A3A);
  static const Color _expBarFill = Color(0xFFF5D33C);

  @override
  Widget build(BuildContext context) {
    // 캐릭터가 아직 없으면(로딩 중 포함) 의미 없는 UI(이름/성장률/상점/도감) 는 숨긴다.
    final hideChrome = character == null;

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

          // 중앙: 말풍선 + 캐릭터 (캐릭터 상태에 따라 분기)
          // 하단 크롬이 없을 땐 아래 패딩을 줄여 캐릭터를 중앙에 가깝게 배치.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: hideChrome ? 0 : 24.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_speechText != null) ...[
                  _SpeechBubble(text: _speechText!),
                  SizedBox(height: 6.h),
                ],
                _buildCharacterSlot(),
              ],
            ),
          ),

          // 우측 상단 아이콘 (상점 / 도감) — 캐릭터 수령 이후에만 노출
          if (!hideChrome)
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

          // 하단: 레벨/EXP 텍스트 + 경험치 바 — 캐릭터 수령 이후에만 노출
          if (!hideChrome)
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
                        _displayName,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _displayProgressLabel,
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
                      value: _displayProgress,
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

  // ─── 렌더 분기 ────────────────────────────────────────────────
  // 캐릭터 상태(character == null / egg / 그 외) 에 따라 중앙 슬롯과
  // 하단 텍스트/바 값을 결정한다. 아직 API 가 없는 필드(level/exp) 는
  // 미수령 단계에서는 플레이스홀더로, 수령 후에는 growthPercent 로 채운다.

  String? get _speechText {
    if (character == null && !isCharacterLoading) {
      return '알이 도착했어요! 받아볼까요?';
    }
    if (character?.isEgg ?? false) {
      return '알을 톡톡 두드려보세요';
    }
    return state.speechBubble;
  }

  // 아래 getter 들은 하단 크롬이 노출되는 경우(character != null) 에만 호출된다.
  String get _displayName => character!.isEgg ? '알' : character!.name;

  String get _displayProgressLabel => '성장률 ${character!.growthPercent}%';

  double get _displayProgress =>
      character!.growthPercent.clamp(0, 100) / 100;

  Widget _buildCharacterSlot() {
    if (isCharacterLoading && character == null) {
      return SizedBox(
        height: 100.h,
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final c = character;
    if (c == null) {
      return const _UnreceivedSlot();
    }
    if (c.isEgg) {
      return _EggSlot(onHatch: onHatch);
    }
    return _GrownCharacter(thumbnailUrl: c.thumbnailUrl);
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

/// 아직 알을 수령하지 않은 상태. 캐릭터 자리에 떠있는 알 + "알 받기" CTA.
///
/// 아직 캐릭터 조회가 끝나지 않았거나(아주 짧은 순간) 서버가 캐릭터를
/// 내려주지 않은 상태. 정상 플로우에서는 로그인 직후 `ensureCharacter()` 가
/// 자동으로 알을 수령하므로 이 슬롯은 거의 보이지 않는다. 방어적으로 스피너만.
class _UnreceivedSlot extends StatelessWidget {
  const _UnreceivedSlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.h,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 알 상태. 10회 탭하면 [onHatch] 가 호출되며, Future 가 끝난 뒤 카운터는 0 으로
/// 리셋된다. 각 탭마다 가벼운 scale 애니메이션 + 햅틱.
class _EggSlot extends StatefulWidget {
  const _EggSlot({this.onHatch});

  final Future<void> Function()? onHatch;

  static const int requiredTaps = 10;

  @override
  State<_EggSlot> createState() => _EggSlotState();
}

class _EggSlotState extends State<_EggSlot>
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
      lowerBound: 0.0,
      upperBound: 1.0,
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
    if (next < _EggSlot.requiredTaps) {
      setState(() => _tapCount = next);
      return;
    }

    // 10회 째. hatch 호출. 완료/실패 모두 카운터는 리셋.
    setState(() {
      _tapCount = next;
      _hatching = true;
    });
    try {
      await widget.onHatch?.call();
    } finally {
      if (mounted) {
        setState(() {
          _tapCount = 0;
          _hatching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _EggSlot.requiredTaps - _tapCount;
    final badgeText = _hatching
        ? '부화 중...'
        : (_tapCount == 0 ? 'TAP' : '$remaining번 더');

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _bump,
            builder: (context, child) {
              // 탭 때마다 1.0 → 1.12 → 1.0 살짝 튐.
              final scale = 1.0 + _bump.value * 0.12;
              return Transform.scale(scale: scale, child: child);
            },
            child: Icon(Icons.egg, size: 88.sp, color: Colors.white),
          ),
          SizedBox(height: 4.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Container(
              key: ValueKey(badgeText),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 이미 부화한 (egg 이외의) 캐릭터. 서버 thumbnailUrl 사용.
class _GrownCharacter extends StatelessWidget {
  const _GrownCharacter({required this.thumbnailUrl});

  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl.isEmpty) {
      return const _CharacterImage();
    }
    return Image.network(
      thumbnailUrl,
      height: 100.h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const _CharacterImage(),
    );
  }
}