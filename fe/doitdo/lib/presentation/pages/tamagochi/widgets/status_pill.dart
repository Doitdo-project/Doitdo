import 'dart:ui';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 캐릭터 카드 하단에 떠있는 가로형 상태 알약(카드).
///
/// `[단계 배지][이름][경험치 바][🔥 스트릭]` 한 줄 구성.
/// 단계 배지와 `🔥` 는 둘 다 탭 가능하며, 각각 단계 안내 / 스트릭 안내 팝오버
/// 를 [Overlay] 에 띄운다 — 부모 Stack 의 clip 경계와 무관하게 화면 어디든
/// 표시 가능.
///
/// 알 단계 / 미수령 상태에서는 호출측이 위젯 자체를 숨겨야 한다 (이 위젯은
/// 부화 이후 정상 캐릭터에만 의미가 있다).
class StatusPill extends StatefulWidget {
  const StatusPill({
    super.key,
    required this.character,
    required this.streakDays,
    required this.streakSlots,
    required this.isRewardClaimable,
    required this.isClaimingReward,
    this.onClaimReward,
  }) : assert(streakSlots.length == 7, 'streakSlots 는 7칸이어야 합니다.');

  final Character character;
  final int streakDays;
  final List<bool> streakSlots;
  final bool isRewardClaimable;
  final bool isClaimingReward;
  final VoidCallback? onClaimReward;

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill> {
  final GlobalKey _stageKey = GlobalKey();
  final GlobalKey _streakKey = GlobalKey();

  OverlayEntry? _entry;

  @override
  void dispose() {
    _hidePopover();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StatusPill old) {
    super.didUpdateWidget(old);
    // 보상 수령 등으로 자식 데이터가 바뀐 동안 팝오버가 떠있으면 그대로 두지
    // 않고 마크업을 다시 빌드해 최신 슬롯/스트릭 수치가 반영되게 한다.
    if (_entry != null) _entry!.markNeedsBuild();
  }

  void _hidePopover() {
    _entry?.remove();
    _entry = null;
  }

  void _showPopover({
    required GlobalKey anchorKey,
    required Widget Function(BuildContext) builder,
    double? maxWidth,
  }) {
    // 탭 콜백이 발화하는 시점에 부모가 rebuild 되면서 이 State 가 deactivate
    // 직전인 경우가 있다 (예: 슬라이더 드래그 중 setState 폭격). 그 상태에서
    // `Overlay.of(context)` 를 호출하면 "deactivated widget's ancestor is unsafe"
    // 가 던져지므로 mounted 로 한 번 더 가드.
    if (!mounted) return;
    _hidePopover();

    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlayState = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchorSize = box.size;
    final screen = overlayBox.size;
    final horizontalPadding = 16.w;
    final anchorCenterX = pos.dx + anchorSize.width / 2;

    // [maxWidth] 가 주어지면 카드를 그 너비로 잡고 anchor 중앙을 따라가도록
    // 좌우 패딩 안에서 클램프. 없으면 기존처럼 화면 좌우 패딩까지 꽉 채운다.
    final double? cardLeft;
    final double? cardRight;
    final double? cardWidth;
    final double tailRelX;
    if (maxWidth != null) {
      final w = maxWidth;
      final left = (anchorCenterX - w / 2)
          .clamp(horizontalPadding, screen.width - horizontalPadding - w);
      cardLeft = left;
      cardRight = null;
      cardWidth = w;
      tailRelX = (anchorCenterX - left).clamp(20.w, w - 20.w);
    } else {
      cardLeft = horizontalPadding;
      cardRight = horizontalPadding;
      cardWidth = null;
      tailRelX = (anchorCenterX - horizontalPadding).clamp(
        20.w,
        screen.width - horizontalPadding * 2 - 20.w,
      );
    }

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // 바깥 탭 → 닫기 (배경 흐림 없이 투명).
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hidePopover,
              ),
            ),
            Positioned(
              left: cardLeft,
              right: cardRight,
              width: cardWidth,
              // 팝오버 하단이 anchor 윗변 바로 위(8.h gap)에 닿도록.
              bottom: screen.height - pos.dy + 8.h,
              child: _PopoverCard(tailLeft: tailRelX, child: builder(ctx)),
            ),
          ],
        );
      },
    );
    overlayState.insert(_entry!);
  }

  void _onStageTap() {
    // 단계 안내는 헤더 + breadcrumb 3 뱃지 + 한 줄 footer 뿐이라 좁게.
    _showPopover(
      anchorKey: _stageKey,
      maxWidth: 260.w,
      builder: (_) => _StageInfoContent(character: widget.character),
    );
  }

  void _onStreakTap() {
    _showPopover(
      anchorKey: _streakKey,
      maxWidth: 300.w,
      builder: (_) => _StreakInfoContent(
        streakDays: widget.streakDays,
        slots: widget.streakSlots,
        isRewardClaimable: widget.isRewardClaimable,
        isClaimingReward: widget.isClaimingReward,
        onClaimReward: widget.onClaimReward == null
            ? null
            : () {
                _hidePopover();
                widget.onClaimReward!();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = widget.character;
    final stageLabel = c.stage.badgeLabel ?? '성장중';
    final progress = (c.growthPercent.clamp(0, 100)) / 100;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        // 두 단 그림자 — 가까운 sharper + 멀리 더 넓고 흐릿한 톤. 카드와 카드
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(28.w, 4.h, 14.w, 4.h),
            decoration: BoxDecoration(
              color: colors.streakCardBg.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  key: _stageKey,
                  onTap: _onStageTap,
                  behavior: HitTestBehavior.opaque,
                  child: _StageBadge(
                    stage: c.stage,
                    label: stageLabel,
                    compact: true,
                  ),
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    c.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(flex: 3, child: _ExpBar(progress: progress)),
                SizedBox(width: 24.w),
                GestureDetector(
                  key: _streakKey,
                  onTap: _onStreakTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    // 좌측 stage compact 뱃지와 동일한 고정 높이(20.h)로 강제.
                    // streak 쪽은 border 1px + 화염 아이콘 12.sp 때문에 자연 높이가
                    // 더 컸어서, 양쪽 모두 height 로 잠그고 alignment.center 로 컨텐츠
                    // 수직 중앙 정렬. shape(border/색)은 각자 그대로 유지.
                    height: 20.h,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFFFD9A8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/fire.png',
                          width: 12.sp,
                          height: 12.sp,
                          filterQuality: FilterQuality.medium,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          widget.streakDays.toString(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFFD86A1F),
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EXP 진행 바.
///
/// - 트랙: 살짝 옴폭한 라이트 그레이 (안쪽 그림자 효과로 깊이감).
/// - 채움: 위→아래로 연한→진한 초록 세로 그라데이션 + 미세 하이라이트.
/// - 둥근 endcap (radius = 높이의 절반) — 가는 캡슐 형태.
/// - 진척 변화 시 600ms easeOutCubic 으로 자연스럽게 늘어난다.
class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Container(
      height: 9.h,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E4D6),
        borderRadius: radius,
        // 트랙 안쪽 살짝 어두운 inner-shadow 효과 (위쪽이 진한 톤).
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD9D2C0), Color(0xFFEFEBDF)],
        ),
      ),
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            width: constraints.maxWidth * progress,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFA9D793), Color(0xFF7BB964)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6FA958).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// `[유년기]` 같은 단계 라벨을 둥근 알약으로. 라이트/다크 무관 고정 색.
///
/// [compact] true 면 padding / 폰트가 한 단계 작아진다 — StatusPill 본체 행
/// 안에서는 좁은 공간이라 compact 로 쓰고, 단계 안내 popover 의 breadcrumb
/// 에서는 기본(=non-compact) 으로 써서 시각적 무게감을 살린다.
class _StageBadge extends StatelessWidget {
  const _StageBadge({
    required this.stage,
    required this.label,
    this.compact = false,
  });

  final CharacterStage stage;
  final String label;
  final bool compact;

  Color get _bg {
    switch (stage) {
      case CharacterStage.infant:
        return const Color(0xFFFCE3C2);
      case CharacterStage.juvenile:
        return const Color(0xFFD4ECCB);
      case CharacterStage.adult:
        return const Color(0xFFD4E2F8);
      case CharacterStage.egg:
      case CharacterStage.other:
        return const Color(0xFFE7E2D6);
    }
  }

  Color get _fg {
    switch (stage) {
      case CharacterStage.infant:
        return const Color(0xFFB8702A);
      case CharacterStage.juvenile:
        return const Color(0xFF4D8B41);
      case CharacterStage.adult:
        return const Color(0xFF3A6BB4);
      case CharacterStage.egg:
      case CharacterStage.other:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    // compact 는 StatusPill 본체에서 우측 streak pill 과 높이를 맞춰야 한다.
    // streak 쪽이 border 1px + 화염 아이콘 12.sp 때문에 자연 높이가 ~20.h 라
    // compact 도 동일하게 고정 height + 수직 center 정렬. shape(pill/각진 라운드)은
    // 그대로. non-compact 는 popover breadcrumb 용이라 자연 높이 유지.
    final hPad = compact ? 8.w : 10.w;
    final vPad = compact ? 3.h : 6.h;
    final radius = compact ? 999.0 : 8.r;
    final textStyle = compact
        ? AppTextStyles.labelSmall
        : AppTextStyles.labelMedium;
    return Container(
      height: compact ? 20.h : null,
      alignment: compact ? Alignment.center : null,
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: compact ? 0 : vPad,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: textStyle.copyWith(
          color: _fg,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

// ─── 팝오버 카드 + 꼬리 ──────────────────────────────────────────

/// 흰색 라운드 카드 + 하단 가운데 부근에 아래로 향하는 작은 삼각형 꼬리.
/// [tailLeft] 는 카드 좌측 가장자리 기준 꼬리 중앙 X (px).
class _PopoverCard extends StatelessWidget {
  const _PopoverCard({required this.tailLeft, required this.child});

  final double tailLeft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r), // 메인 카드와 통일감 있게 수정
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
          Positioned(
            left: tailLeft - 8.w,
            bottom: -7.h,
            child: CustomPaint(
              size: Size(16.w, 8.h),
              painter: _DownTailPainter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownTailPainter extends CustomPainter {
  const _DownTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DownTailPainter old) => old.color != color;
}

// ─── 단계 안내 팝오버 컨텐츠 ──────────────────────────────────────

class _StageInfoContent extends StatelessWidget {
  const _StageInfoContent({required this.character});

  final Character character;

  /// 표시 순서. 현재 단계는 [_StageBreadcrumb] 가 강조.
  static const List<(CharacterStage, String)> _stages = [
    (CharacterStage.infant, '유년기'),
    (CharacterStage.juvenile, '성장기'),
    (CharacterStage.adult, '성숙기'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${character.name}는 자라고 있어요',
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10.h),
          _StageBreadcrumb(current: character.stage, stages: _stages),
          SizedBox(height: 12.h),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          SizedBox(height: 10.h),
          Text(
            '할 일을 완료할 때마다 경험치가 쌓이고,\n성숙기를 모두 채우면 ${character.name}는 독립해요.',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// `[유년기] → [성장기] → [성숙기]` 한 줄. 카드 본체에서 쓰는 [_StageBadge] 와
/// 같은 색감을 그대로 사용해 캐릭터 옆에 떠있던 뱃지와 시각적으로 이어지게 한다.
/// 현재 단계는 풀 컬러, 나머지는 페이드 + 작은 화살표 구분자.
class _StageBreadcrumb extends StatelessWidget {
  const _StageBreadcrumb({required this.current, required this.stages});

  final CharacterStage current;
  final List<(CharacterStage, String)> stages;

  @override
  Widget build(BuildContext context) {
    final separator = Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 14.sp,
        color: Colors.black26,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          if (i > 0) separator,
          Opacity(
            opacity: stages[i].$1 == current ? 1.0 : 0.45,
            child: _StageBadge(stage: stages[i].$1, label: stages[i].$2),
          ),
        ],
      ],
    );
  }
}

// ─── 스트릭 안내 팝오버 컨텐츠 ─────────────────────────────────────

class _StreakInfoContent extends StatelessWidget {
  const _StreakInfoContent({
    required this.streakDays,
    required this.slots,
    required this.isRewardClaimable,
    required this.isClaimingReward,
    required this.onClaimReward,
  });

  final int streakDays;
  final List<bool> slots;
  final bool isRewardClaimable;
  final bool isClaimingReward;
  final VoidCallback? onClaimReward;

  @override
  Widget build(BuildContext context) {
    final showReward = isRewardClaimable && onClaimReward != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/fire.png',
                width: 16.sp,
                height: 16.sp,
                filterQuality: FilterQuality.medium,
              ),
              SizedBox(width: 6.w),
              Text(
                '$streakDays일째 함께하고 있어요',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            // 이 수치를 키울수록 더 좁아집니다
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++) _StreakDot(achieved: slots[i]),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          if (showReward) ...[
            Center(
              child: _RewardButton(
                isLoading: isClaimingReward,
                onTap: onClaimReward!,
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          SizedBox(height: 10.h),
          Text(
            '하루에 할 일을 하나라도 완료하면 스트릭이 1일 적립돼요.\n7일 연속을 모으면 보상이 도착해요.',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakDot extends StatelessWidget {
  const _StreakDot({required this.achieved});

  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: achieved
            ? colors.streakDotActive
            : colors.streakDotInactive.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RewardButton extends StatelessWidget {
  const _RewardButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.streakDotActive,
      borderRadius: BorderRadius.circular(12.r), // 버튼도 각지게 조정
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '🎁 보상 받기',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
