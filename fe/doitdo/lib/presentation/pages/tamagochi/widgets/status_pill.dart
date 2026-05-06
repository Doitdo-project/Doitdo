import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';

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
  }) {
    _hidePopover();

    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlayState = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchorSize = box.size;
    final screen = overlayBox.size;
    final horizontalPadding = 16.w;
    final tailCenterX = pos.dx + anchorSize.width / 2;
    final tailRelX = (tailCenterX - horizontalPadding)
        .clamp(20.w, screen.width - horizontalPadding * 2 - 20.w);

    _entry = OverlayEntry(builder: (ctx) {
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
            left: horizontalPadding,
            right: horizontalPadding,
            // 팝오버 하단이 anchor 윗변 바로 위(8.h gap)에 닿도록.
            bottom: screen.height - pos.dy + 8.h,
            child: _PopoverCard(
              tailLeft: tailRelX,
              child: builder(ctx),
            ),
          ),
        ],
      );
    });
    overlayState.insert(_entry!);
  }

  void _onStageTap() {
    _showPopover(
      anchorKey: _stageKey,
      builder: (_) => _StageInfoContent(character: widget.character),
    );
  }

  void _onStreakTap() {
    _showPopover(
      anchorKey: _streakKey,
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
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: colors.streakCardBg.withValues(alpha: 0.75),
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
                  child: _StageBadge(stage: c.stage, label: stageLabel),
                ),
                SizedBox(width: 10.w),
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
                SizedBox(width: 14.w),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E1D6).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8FC57A),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                GestureDetector(
                  key: _streakKey,
                  onTap: _onStreakTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 12.sp, height: 1.1)),
                        SizedBox(width: 4.w),
                        Text(
                          widget.streakDays.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFFE2782B),
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

/// `[유년기]` 같은 단계 라벨을 둥근 알약으로. 라이트/다크 무관 고정 색.
class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage, required this.label});

  final CharacterStage stage;
  final String label;

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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final name = character.name;
    final current = character.stage;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$name는 자라고 있어요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          _StageRow(
            label: '유년기',
            description: '알에서 막 깨어난 단계예요.',
            isCurrent: current == CharacterStage.infant,
          ),
          SizedBox(height: 8.h),
          _StageRow(
            label: '성장기',
            description: '활발하게 자라는 단계예요.',
            isCurrent: current == CharacterStage.juvenile,
          ),
          SizedBox(height: 8.h),
          _StageRow(
            label: '성숙기',
            description: '독립을 앞둔 마지막 단계예요.',
            isCurrent: current == CharacterStage.adult,
          ),
          SizedBox(height: 12.h),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          SizedBox(height: 10.h),
          Text(
            '할 일을 완료할 때마다 경험치가 쌓이고,\n성숙기를 모두 채우면 $name는 독립해요.',
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

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.description,
    required this.isCurrent,
  });

  final String label;
  final String description;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final labelColor = isCurrent ? const Color(0xFFB8702A) : Colors.black87;
    final descColor = isCurrent ? const Color(0xFF8C5A22) : Colors.black54;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFFCE3C2) : const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(10.r), // 메인 카드에 맞춰 둥글기 소폭 조정
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '|',
              style: AppTextStyles.labelMedium.copyWith(
                color: descColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: AppTextStyles.labelSmall.copyWith(color: descColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
          Text(
            '🔥 $streakDays일째 함께하고 있어요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _StreakDot(achieved: slots[i]),
            ],
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color:
        achieved ? colors.streakDotActive : colors.streakDotInactive.withValues(alpha: 0.5),
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