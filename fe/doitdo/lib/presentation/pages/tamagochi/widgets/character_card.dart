import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';

/// 다마고치 메인 상단의 초록 배경 카드.
///
/// [character] 상태에 따라 중앙 슬롯을 분기:
/// - null : 미수령 — 로딩 스피너 (정상 플로우에선 거의 보이지 않음)
/// - isEgg: 알 아이콘 + TAP 배지. 탭하면 [onEggTap] 이 호출되어 부화 페이지로 이동
/// - else : thumbnailUrl 로 캐릭터 이미지
///
/// 이름/성장률/경험치/상점/도감 UI("chrome")는 **부화 이후**(egg 가 아닌 상태)
/// 에만 노출된다.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.state,
    this.character,
    this.isCharacterLoading = false,
    this.onTapShop,
    this.onTapCollection,
    this.onEggTap,
    this.topSafePadding = 0,
  });

  final TamagochiState state;
  final Character? character;

  /// 최초 캐릭터 조회 중일 때 true. 캐릭터 영역만 살짝 가리는 용도.
  final bool isCharacterLoading;

  final VoidCallback? onTapShop;
  final VoidCallback? onTapCollection;

  /// 알을 탭했을 때 호출. 부화 페이지로 이동 + 복귀 시 재조회는 부모가 담당.
  final VoidCallback? onEggTap;

  /// 카드가 상태바 영역까지 확장될 때 content 가 상태바 아이콘과 겹치지 않도록
  /// 밀어낼 상단 여백. 배경(grass) 은 이 영역까지 그대로 이어지고, 내부 content
  /// 좌표만 이 값만큼 내려간다.
  final double topSafePadding;

  // 카드 배경이 테마와 무관하게 고정이라 DoitdoColors 가 아닌 로컬 상수.
  static const Color _expBarBg = Color(0xFF3F4A3A);
  static const Color _expBarFill = Color(0xFFF5D33C);

  @override
  Widget build(BuildContext context) {
    // 미수령 중이거나 알 상태면 이름/성장률/상점/도감 UI 는 숨긴다.
    final hideChrome = character == null || character!.isEgg;

    return SizedBox(
      height: 200.h + topSafePadding,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_grass.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),

          // 진화/부화/독립 같은 주요 액션 중의 로딩 표시. copyWithPrevious 덕에
          // 이전 캐릭터 데이터는 그대로 남아 있고, 이 작은 스피너만 카드 왼쪽
          // 상단에 얹혀 "서버 갱신 중" 만 표현한다. 홈 전체를 덮지 않으므로 아래
          // 투두 영역은 그대로 상호작용 가능.
          if (isCharacterLoading && character != null)
            Positioned(
              top: topSafePadding + 10.h,
              left: 12.w,
              child: SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // 중앙: 말풍선 + 캐릭터 (캐릭터 상태에 따라 분기)
          // 하단 크롬이 없을 땐 아래 패딩을 줄여 캐릭터를 중앙에 가깝게 배치.
          // 상태바 영역(topSafePadding) 은 비워 중앙 정렬 기준이 그 아래 영역.
          Positioned(
            left: 0,
            right: 0,
            top: topSafePadding,
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
              top: topSafePadding + 8.h,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_stageLabel != null) ...[
                            _StageBadge(label: _stageLabel!),
                            SizedBox(width: 6.w),
                          ],
                          Text(
                            _displayName,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          if (_stageHint != null) ...[
                            SizedBox(width: 4.w),
                            _StageHintIcon(message: _stageHint!),
                          ],
                        ],
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
      return null;
    }
    return state.speechBubble;
  }

  // 아래 getter 들은 하단 크롬이 노출되는 경우(character != null && !isEgg)
  // 에만 호출된다.
  String get _displayName => character!.name;

  String get _displayProgressLabel => '성장률 ${character!.growthPercent}%';

  double get _displayProgress =>
      character!.growthPercent.clamp(0, 100) / 100;

  /// 단계별 가이드. 알/미확정 단계는 null (호출부에서 툴팁 자체를 숨김).
  String? get _stageHint {
    final c = character;
    if (c == null) return null;
    switch (c.stage) {
      case CharacterStage.egg:
      case CharacterStage.other:
        return null;
      case CharacterStage.infant:
        return '할 일을 완료해 경험치를 모아보세요.\n100% 달성 시 성장기로 진화해요.';
      case CharacterStage.juvenile:
        return '꾸준히 할 일을 완료하면 성숙기로 자라나요.';
      case CharacterStage.adult:
        if (c.canFarewell) {
          return '독립할 준비가 됐어요. 배웅하면 다음 알이 도착해요.';
        }
        return '조금만 더 함께하면 독립할 수 있어요.';
    }
  }

  /// 단계 배지 문구. 미정 단계(other)면 null → 배지 생략.
  String? get _stageLabel => character?.stage.badgeLabel;

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
      return _EggSlot(imageUrl: c.thumbnailUrl, onTap: onEggTap);
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
          // 카드 자체가 라이트/다크 무관 고정 잔디 배경 + 흰 버튼이라
          // 아이콘도 토큰이 아닌 고정 어두운 색으로 둔다 (다크에서 흰 위 흰 회피).
          child: Icon(icon, size: 20.sp, color: Colors.black87),
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
      // 흰 말풍선 배경은 라이트/다크 무관 고정. 텍스트도 토큰이 아닌 고정 어두운 색.
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// 서버 thumbnailUrl 이 비어있거나 로드 실패했을 때 자리를 지키는 중립 플레이스홀더.
/// 특정 캐릭터 에셋(한라봉 등) 을 깔면 엉뚱한 캐릭터가 보이는 오해를 낳으므로 비움.
class _CharacterPlaceholder extends StatelessWidget {
  const _CharacterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.h,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 56.sp,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
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

/// 알 상태. 탭하면 [onTap] 으로 전달만 하고, 실제 부화 카운팅/애니메이션은
/// 전용 페이지([CharacterHatchPage])에서 처리된다.
/// 서버가 알 단계에서도 [imageUrl] 을 내려주므로 그 이미지를 사용.
class _EggSlot extends StatelessWidget {
  const _EggSlot({required this.imageUrl, this.onTap});

  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EggImage(imageUrl: imageUrl, size: 100.h),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '알을 톡톡 두드려보세요',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 알 이미지. 서버 url 사용 → 실패/빈값이면 Icons.egg fallback.
class _EggImage extends StatelessWidget {
  const _EggImage({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

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

  Widget _fallback() => Icon(Icons.egg, size: size * 0.88, color: Colors.white);
}

/// 이름 옆 info 아이콘. 탭하면 현재 단계 기준 안내 문구가 잠깐 떠오른다.
///
/// 모바일에선 Tooltip 기본 트리거가 long-press 라 발견성이 떨어져서
/// [TooltipTriggerMode.tap] 으로 교체하고 유지 시간도 살짝 늘렸다.
class _StageHintIcon extends StatelessWidget {
  const _StageHintIcon({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      waitDuration: Duration.zero,
      preferBelow: true,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8.r),
      ),
      textStyle: AppTextStyles.labelSmall.copyWith(
        color: Colors.white,
        height: 1.4,
      ),
      child: Icon(
        Icons.info_outline_rounded,
        size: 14.sp,
        color: Colors.black.withValues(alpha: 0.45),
      ),
    );
  }
}

/// 이름 앞에 붙는 진화 단계 배지 (네모). 유년기/성장기/성숙기.
class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.black.withValues(alpha: 0.75),
          fontSize: 11.sp,
          height: 1.0,
        ),
      ),
    );
  }
}

/// 이미 부화한 (egg 이외의) 캐릭터. **항상** 서버 thumbnailUrl 을 사용.
/// url 이 비었거나 로드 실패 시에만 중립 플레이스홀더로 대체.
class _GrownCharacter extends StatelessWidget {
  const _GrownCharacter({required this.thumbnailUrl});

  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl.isEmpty) {
      return const _CharacterPlaceholder();
    }
    return Image.network(
      thumbnailUrl,
      height: 80.h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const _CharacterPlaceholder(),
    );
  }
}