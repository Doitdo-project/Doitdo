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
    if (_entry != null) _entry!.markNeedsBuild();
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
    Duration duration = const Duration(milliseconds: 1500),
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
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      borderRadius: BorderRadius.circular(12.r),
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
