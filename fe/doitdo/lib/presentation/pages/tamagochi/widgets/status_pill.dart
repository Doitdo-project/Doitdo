import 'dart:async';
import 'dart:ui';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 캐릭터 카드 하단의 가로형 상태 알약: `[단계][이름][EXP][🔥]`.
/// 단계 / 🔥 는 탭 시 [Overlay] 팝오버로 안내를 띄운다.
/// 알 단계에서는 호출측에서 위젯 자체를 숨긴다.
class StatusPill extends StatefulWidget {
  const StatusPill({
    super.key,
    required this.character,
    required this.streakDays,
    required this.streakSlots,
    required this.isRewardClaimable,
    required this.isClaimingReward,
    this.isRewardClaimed = false,
    this.claimSuccessFlash = false,
    this.onClaimReward,
    this.onTapEvolve,
    this.onTapFarewell,
    this.actionBusy = false,
  }) : assert(streakSlots.length == 7, 'streakSlots 는 7칸이어야 합니다.');

  final Character character;
  final int streakDays;
  final List<bool> streakSlots;
  final bool isRewardClaimable;
  final bool isClaimingReward;

  /// "이번 7일 블록을 다 채웠고 이미 보상까지 받은 상태" 여부. true 면 7번째 슬롯이
  /// claim CTA 도, dim placeholder 도 아닌 "수령 완료" 시각(체크) 으로 표시된다.
  /// [claimSuccessFlash] 는 수령 직후의 단발성 신호고, 이건 다음 refresh 이후에도
  /// 블록이 그대로면 계속 유지되는 정적 상태 (다음 블록으로 넘어가면 자동 해제).
  final bool isRewardClaimed;

  /// 보상 수령 성공 직후 잠깐 true 로 유지되는 플래시 신호. 호출자(page) 가
  /// 성공 응답 시 setState 로 true 로 바꾸고 ~1.2s 뒤 false 로 되돌린다.
  /// true 동안 7번째 슬롯이 [_StreakRewardSuccess] (초록 체크) 로 표시되고,
  /// 이게 false 로 떨어지는 시점에 popover 가 자동으로 닫힌다 — 사용자가
  /// "받았다" 를 충분히 인지한 후 화면이 정리된다.
  final bool claimSuccessFlash;
  final VoidCallback? onClaimReward;
  final VoidCallback? onTapEvolve;
  final VoidCallback? onTapFarewell;
  final bool actionBusy;

  @override
  State<StatusPill> createState() => _StatusPillState();
}

enum _BarMode { progress, evolve, farewell }

class _StatusPillState extends State<StatusPill> {
  static const double _outerHorizontalMargin = 24;
  static const double _innerHorizontalPadding = 14;
  static const double _innerVerticalPadding = 4;
  static const double _itemGap = 8;
  static const double _nameMaxWidth = 120;

  final GlobalKey _stageKey = GlobalKey();
  final GlobalKey _expKey = GlobalKey();
  final GlobalKey _streakKey = GlobalKey();

  OverlayEntry? _entry;
  Timer? _percentTimer;

  @override
  void dispose() {
    _hidePopover();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StatusPill old) {
    super.didUpdateWidget(old);
    // 보상 수령 흐름의 popover 자동 닫기 타이밍:
    //   - 실패: isClaimingReward true→false, 그 즉시 success flash 도 false →
    //     바로 닫힘 (page 가 에러 스낵바 안내).
    //   - 성공: isClaimingReward true→false 와 함께 claimSuccessFlash 가 true 가
    //     올라와 닫지 않고 [_StreakRewardSuccess] 체크를 보여준다. 이후 page 가
    //     ~1.2s 뒤 flash 를 false 로 되돌리는 그 전환 시점에 닫힘.
    final claimingDone = old.isClaimingReward && !widget.isClaimingReward;
    final flashCleared =
        old.claimSuccessFlash && !widget.claimSuccessFlash;
    final shouldClose =
        (claimingDone && !widget.claimSuccessFlash) || flashCleared;
    if (shouldClose && _entry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _hidePopover();
      });
    }
    // didUpdateWidget 은 부모 build 페이즈 안에서 실행되는데, OverlayEntry 는
    // 별도 Overlay 트리(sibling) 에 살아서 그 시점에 동기 markNeedsBuild 를
    // 호출하면 "marked dirty during build" 가 던져진다 (스트릭 팝오버 떠있는
    // 상태에서 ref.watch refresh 가 일어나면 간헐적으로 재현). 다음 프레임으로
    // 미뤄 안전한 시점에 dirty 마킹.
    if (_entry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _entry?.markNeedsBuild();
      });
    }
  }

  void _hidePopover() {
    _percentTimer?.cancel();
    _percentTimer = null;
    _entry?.remove();
    _entry = null;
  }

  void _showPopover({
    required GlobalKey anchorKey,
    required Widget Function(BuildContext) builder,
    double? maxWidth,
  }) {
    // 탭 콜백 발화 시 부모 rebuild 로 이 State 가 deactivate 직전일 수 있다.
    // 그 상태에서 Overlay.of(context) 호출 시 ancestor unsafe 가 던져지므로 가드.
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

    final double? cardLeft;
    final double? cardRight;
    final double? cardWidth;
    final double tailRelX;
    if (maxWidth != null) {
      final w = maxWidth;
      final left = (anchorCenterX - w / 2).clamp(
        horizontalPadding,
        screen.width - horizontalPadding - w,
      );
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
    _showPopover(
      anchorKey: _stageKey,
      maxWidth: 260.w,
      builder: (_) => _StageInfoContent(character: widget.character),
    );
  }

  void _onExpTap() {
    final pct = widget.character.growthPercent.clamp(0, 100).toStringAsFixed(0);
    _showToast(
      anchorKey: _expKey,
      child: _ToastBubble(text: '$pct%'),
    );
  }

  /// stage/streak 의 흰 카드 popover 와 달리, anchor 위에 1.5초만 떠있다 사라지는
  /// 검은 토스트. intrinsic 폭으로 자기 텍스트만큼만 차지하고 꼬리도 없다.
  void _showToast({
    required GlobalKey anchorKey,
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    if (!mounted) return;
    _hidePopover();

    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlayState = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final screen = overlayBox.size;
    final anchorCenterX = pos.dx + box.size.width / 2;

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hidePopover,
              ),
            ),
            // anchor 중앙 좌표에 배치 후 FractionalTranslation 으로 -50% 이동 →
            // 토스트가 자기 폭만큼만 잡고 가운데 정렬됨 (Positioned 단독으론
            // intrinsic 가운데 불가능).
            Positioned(
              left: anchorCenterX,
              bottom: screen.height - pos.dy + 8.h,
              child: FractionalTranslation(
                translation: const Offset(-0.5, 0),
                child: child,
              ),
            ),
          ],
        );
      },
    );
    overlayState.insert(_entry!);

    _percentTimer = Timer(duration, () {
      if (mounted) _hidePopover();
    });
  }

  void _onStreakTap() {
    _showPopover(
      anchorKey: _streakKey,
      maxWidth: 300.w,
      builder: (_) => _StreakInfoContent(
        streakDays: widget.streakDays,
        slots: widget.streakSlots,
        isRewardClaimable: widget.isRewardClaimable,
        isRewardClaimed: widget.isRewardClaimed,
        isClaimingReward: widget.isClaimingReward,
        claimSuccessFlash: widget.claimSuccessFlash,
        // 즉시 닫지 않고 그대로 두면 7번째 슬롯이 흐려진 gift 로 전환되어
        // 응답을 기다린다. 응답 후 page 가 success flash 를 켜면
        // 초록 체크가 잠깐 떴다, flash 가 꺼지는 시점에 popover 가 닫힌다
        // (실패 시엔 flash 없이 즉시 닫힘) — didUpdateWidget 가 처리.
        onClaimReward: widget.onClaimReward,
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
      margin: EdgeInsets.symmetric(horizontal: _outerHorizontalMargin.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
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
            padding: EdgeInsets.symmetric(
              horizontal: _innerHorizontalPadding.w,
              vertical: _innerVerticalPadding.h,
            ),
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
                SizedBox(width: _itemGap.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _nameMaxWidth.w),
                  child: Text(
                    c.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                SizedBox(width: _itemGap.w),
                Expanded(
                  child: KeyedSubtree(
                    key: _expKey,
                    child: _ExpBar(
                      progress: progress,
                      mode: c.canFarewell
                          ? _BarMode.farewell
                          : c.canEvolve
                          ? _BarMode.evolve
                          : _BarMode.progress,
                      onTap: widget.actionBusy
                          ? null
                          : c.canFarewell
                          ? widget.onTapFarewell
                          : c.canEvolve
                          ? widget.onTapEvolve
                          : _onExpTap,
                    ),
                  ),
                ),
                SizedBox(width: _itemGap.w),
                GestureDetector(
                  key: _streakKey,
                  onTap: _onStreakTap,
                  behavior: HitTestBehavior.opaque,
                  child: _StreakBadge(days: widget.streakDays),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EXP 진행 바. evolve / farewell 모드면 막대 자리에 캡슐 CTA 로 갈아낀다.
class _ExpBar extends StatelessWidget {
  const _ExpBar({
    required this.progress,
    this.mode = _BarMode.progress,
    this.onTap,
  });

  final double progress;
  final _BarMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case _BarMode.farewell:
        return _CallToAction(
          label: '독립하기',
          gradient: const [Color(0xFFB69CFF), Color(0xFFFF8FBA)],
          borderColor: const Color(0xFFE5D6FF),
          glowColor: const Color(0xFFC4A8FF),
          onTap: onTap,
        );
      case _BarMode.evolve:
        return _CallToAction(
          label: '진화하기',
          gradient: const [Color(0xFFFFD27A), Color(0xFFE9A23B)],
          borderColor: const Color(0xFFFFE9B6),
          glowColor: const Color(0xFFE9A23B),
          onTap: onTap,
        );
      case _BarMode.progress:
        break;
    }

    final radius = BorderRadius.circular(999);
    final bar = Container(
      height: 9.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E4D6),
        borderRadius: radius,
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
    if (onTap == null) return bar;
    // 9.h 막대 자체는 너무 얇아 탭이 어려움 → streak/stage 와 같은 20.h hit 영역
    // 안에 막대를 vertical center 로 배치.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 20.h,
        child: Center(child: bar),
      ),
    );
  }
}

/// 진화 / 독립 등 EXP 바 자리를 차지하는 펄스형 CTA 캡슐.
/// 색만 다르고 펄스/사이즈/타이포는 공통.
class _CallToAction extends StatefulWidget {
  const _CallToAction({
    required this.label,
    required this.gradient,
    required this.borderColor,
    required this.glowColor,
    this.onTap,
  });

  final String label;
  final List<Color> gradient;
  final Color borderColor;
  final Color glowColor;
  final VoidCallback? onTap;

  @override
  State<_CallToAction> createState() => _CallToActionState();
}

class _CallToActionState extends State<_CallToAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cap = Container(
      height: 20.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.gradient,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: widget.glowColor.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final pulsing = ScaleTransition(scale: _scale, child: cap);
    if (widget.onTap == null) return pulsing;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: pulsing,
    );
  }
}

/// 🔥 + 일수. 폰트 / 보더 색은 단계 뱃지와 무관한 고정 따뜻한 톤.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD9A8), width: 1),
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
            '$days',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFFD86A1F),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// `[유년기]` 같은 단계 라벨. compact 면 streak 뱃지와 같은 20.h 캡슐로.
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
    final hPad = compact ? 8.w : 10.w;
    final vPad = compact ? 0.0 : 6.h;
    final radius = compact ? 999.0 : 8.r;
    final textStyle = compact
        ? AppTextStyles.labelSmall
        : AppTextStyles.labelMedium;
    return Container(
      height: compact ? 20.h : null,
      alignment: compact ? Alignment.center : null,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
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
              borderRadius: BorderRadius.circular(16.r),
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

// ─── EXP 토스트 ──────────────────────────────────────────────────

class _ToastBubble extends StatelessWidget {
  const _ToastBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

// ─── 단계 안내 팝오버 컨텐츠 ──────────────────────────────────────

class _StageInfoContent extends StatelessWidget {
  const _StageInfoContent({required this.character});

  final Character character;

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
            style: AppTextStyles.labelMedium.copyWith(color: Colors.black),
          ),
          SizedBox(height: 10.h),
          _StageBreadcrumb(current: character.stage, stages: _stages),
          SizedBox(height: 12.h),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          SizedBox(height: 10.h),
          Text(
            '할 일을 완료할 때마다 경험치가 쌓이고\n성숙기를 모두 채우면 ${character.name}는 독립할 수 있어요',
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
    required this.isRewardClaimed,
    required this.isClaimingReward,
    required this.claimSuccessFlash,
    required this.onClaimReward,
  });

  final int streakDays;
  final List<bool> slots;
  final bool isRewardClaimable;

  /// 7일 블록 채움 + 이미 수령된 상태. true 면 placeholder 대신 정적 success 체크.
  final bool isRewardClaimed;
  final bool isClaimingReward;

  /// 보상 수령 성공 직후 ~1.2s 동안 true. true 일 때 7번째 슬롯이 초록 체크
  /// ([_StreakRewardSuccess]) 로 표시되어 사용자에게 "받았다" 를 인지시킨다.
  final bool claimSuccessFlash;
  final VoidCallback? onClaimReward;

  @override
  Widget build(BuildContext context) {
    final showReward = isRewardClaimable && onClaimReward != null;

    // 우선순위: success flash > claimable CTA > already claimed > placeholder.
    // - flash: 수령 직후 단발성 (1.2s)
    // - showReward: 지금 받을 수 있음 → 펄스 CTA
    // - isRewardClaimed: 이번 블록 이미 수령 완료 → 정적 체크 (다음 블록 시작
    //   되면 자동 해제)
    // - placeholder: 미달성 (블록 진행 중) → 흐린 선물
    Widget rewardSpot;
    if (claimSuccessFlash) {
      rewardSpot = const _StreakRewardSuccess();
    } else if (showReward) {
      rewardSpot = _StreakRewardSpot(
        isLoading: isClaimingReward,
        onTap: onClaimReward!,
      );
    } else if (isRewardClaimed) {
      rewardSpot = const _StreakRewardSuccess();
    } else {
      rewardSpot = const _StreakRewardPlaceholder();
    }

    // success flash 동안엔 라인이 풀컬러로 reward 까지 이어지도록 슬롯을 전부
    // 달성으로 오버라이드 — refresh 로 streak 데이터가 다음 블록(예: [T,F,F,...])
    // 으로 바뀌어도 1.2s 동안은 "방금 7일 채웠다" 라는 시각이 깨지지 않는다.
    final renderedSlots =
        claimSuccessFlash ? List<bool>.filled(7, true) : slots;

    final iconWidgets = <Widget>[
      for (var i = 0; i < 6; i++) _StreakFireSpot(achieved: renderedSlots[i]),
      rewardSpot,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '$streakDays일째 함께하고 있어요',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 트레일 라인 없이 7개 아이콘을 균등 분배. 달성 여부는 각 아이콘
          // 자체의 톤(컬러 vs 그레이스케일) 으로만 표현 — 선이 빠지니 선물의
          // 펄스/뱃지가 더 또렷하게 시선을 가져간다.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: iconWidgets,
          ),
          SizedBox(height: 12.h),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          SizedBox(height: 10.h),
          Text(
            '매일 할 일을 하나만 완료해도 스트릭이 쌓여요\n7일 연속 달성 시 보상을 받을 수 있어요!',
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

/// 스트릭 1~6일 자리에 들어가는 불씨 아이콘. 달성 = 풀컬러, 미달성 = 흐리게.
/// 팝오버 상단의 fire.png 와 같은 에셋을 써 "스트릭 = 불씨 누적" 톤을 일관되게.
/// 슬롯 자체가 아이콘 사이즈 (22sp) — 부모 Row 가 spaceBetween 으로 균등 분배.
class _StreakFireSpot extends StatelessWidget {
  const _StreakFireSpot({required this.achieved});

  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final size = 22.sp;
    final fire = Image.asset(
      'assets/images/fire.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
    if (!achieved) {
      // 미달성: 채도/명도까지 떨어뜨려 "아직 안 채운 칸" 임을 더 명확히.
      // Opacity 만 낮추면 색이 그대로라 달성과 톤 차이가 약했음.
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0,    0,    0,    1, 0,
        ]),
        child: Opacity(opacity: 0.45, child: fire),
      );
    }
    return fire;
  }
}

/// 스트릭 7번째 자리에 평소(claimable 아님) 들어가는 흐린 보상 아이콘.
/// 사용자가 1일째부터 "이 자리가 보상" 임을 알 수 있게 미리 미리보기 형태로
/// 노출 — claimable 되는 순간 [_StreakRewardSpot] 으로 교체되어 컬러+펄스로 살아난다.
class _StreakRewardPlaceholder extends StatelessWidget {
  const _StreakRewardPlaceholder();

  @override
  Widget build(BuildContext context) {
    // 다른 슬롯(22sp) 보다 살짝 큰 26sp — 여기가 "도착점" 임을 시각적으로 표시.
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0,    0,    0,    1, 0,
      ]),
      child: Opacity(
        opacity: 0.45,
        child: Image.asset(
          'assets/images/streak_reward.png',
          width: 26.sp,
          height: 26.sp,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// "이미 보상을 받은" 정적 표시 — 풀컬러 선물 + 우하단 초록 체크 뱃지.
/// 펄스/할로 없음 ("수령 후엔 반짝이지 않게"). 보상 수령 직후의 성공 flash
/// 와 다음 refresh 이후의 정적 claimed 상태가 동일 시각이라 전환이 부드럽다.
class _StreakRewardSuccess extends StatelessWidget {
  const _StreakRewardSuccess();

  @override
  Widget build(BuildContext context) {
    final size = 26.sp;
    final badge = 11.sp;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Image.asset(
            'assets/images/streak_reward.png',
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
          ),
          // 우하단 작은 체크 뱃지. 흰 보더로 선물 위에서도 또렷.
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: badge,
              height: badge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34A853),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                size: badge * 0.7,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 스트릭 7번째 자리에 박히는 🎁 보상 버튼. 일반 dot 사이즈에 가까운 인라인
/// 액션이며, 가벼운 scale 펄스 + halo glow 로 "탭해도 된다" 는 어포던스를 준다.
/// 로딩(수령 중) 에는 같은 자리에서 흐려지고, 응답이 도착하면 부모가
/// success flash → popover close 흐름으로 처리한다 ([_StatusPillState.didUpdateWidget]).
class _StreakRewardSpot extends StatefulWidget {
  const _StreakRewardSpot({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_StreakRewardSpot> createState() => _StreakRewardSpotState();
}

class _StreakRewardSpotState extends State<_StreakRewardSpot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 다른 슬롯(22sp) 보다 26sp 로 살짝 큼 — "도착점/보상" 시각적 위계.
    final size = 26.sp;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: widget.isLoading
                // 응답 대기: 스피너 대신 같은 자리의 gift 를 흐리게 + 펄스/halo
                // 끔. "탭 받음, 잠깐 기다리는 중" 만 표현.
                ? Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/images/streak_reward.png',
                      width: size,
                      height: size,
                      filterQuality: FilterQuality.medium,
                    ),
                  )
                : AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      // 부드러운 듀얼 글로우.
                      // 이전 (spread 0.5+1.5t, blur 8+8t) 은 spread 가 살아 있어
                      // 가장자리가 단단한 "주황 디스크" 처럼 보였다 → 디자인 부조화.
                      // spread=0 으로 글로우만 남기고, blur 를 키워 페더링을 길게,
                      // 바깥 글로우 + 안쪽 부스트 두 겹으로 입체감을 살린다.
                      final t = _pulseCtrl.value;
                      final color = context.colors.streakDotActive;
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            // 바깥 글로우: 넓고 옅게.
                            BoxShadow(
                              color: color.withValues(alpha: 0.18 + 0.12 * t),
                              blurRadius: 14 + 8 * t,
                              spreadRadius: 0,
                            ),
                            // 안쪽 부스트: 좁고 살짝 진하게 — 아이콘 가장자리에
                            // 따뜻한 림 라이트가 도는 느낌.
                            BoxShadow(
                              color: color.withValues(alpha: 0.22 + 0.10 * t),
                              blurRadius: 5 + 3 * t,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ScaleTransition(
                      scale: _scale,
                      child: Image.asset(
                        'assets/images/streak_reward.png',
                        width: size,
                        height: size,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
