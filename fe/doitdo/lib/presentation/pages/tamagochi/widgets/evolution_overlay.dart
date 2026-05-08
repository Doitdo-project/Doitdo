import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/domain/entities/character.dart';

/// 진화 연출 풀스크린 오버레이.
///
/// 흐름:
///   1. silhouette  : 기존 캐릭터를 검은 실루엣으로 표시 (살짝 펄스)
///   2. animation   : 위에 [animationUrl] 반짝임 gif 재생, 실루엣은 그대로 유지
///   3. reveal      : 실루엣 → 새 캐릭터 이미지로 크로스페이드 + 살짝 scale up
///   4. complete    : 새 캐릭터를 잠깐 정지 화면으로 보여준 뒤 자동 dismiss
///
/// 화면 어디든 탭하면 reveal/complete 단계로 점프 → 자동 닫힘.
/// gif 자체는 길이를 알 수 없어 [_animationDur] 만큼만 노출하고 다음 단계로 넘긴다.
class EvolutionOverlay extends StatefulWidget {
  const EvolutionOverlay({
    super.key,
    required this.beforeImageUrl,
    required this.animationUrl,
    required this.afterImageUrl,
    this.beforeStage,
    this.afterStage,
  });

  /// 진화 전 캐릭터 썸네일 — overlay 열기 직전에 호출자가 캡처해서 넘긴다
  /// (`evolve()` 직후엔 home state 가 이미 새 캐릭터로 바뀌어 있음).
  final String beforeImageUrl;

  /// 응답으로 받은 반짝임 gif. animation 단계에서 한 번 재생.
  final String animationUrl;

  /// 응답으로 받은 진화 후 캐릭터 이미지. reveal 단계 페이드인 대상.
  final String afterImageUrl;

  /// 응답의 raw stage 값 (예: BABY/INFANT). 화면 하단 라벨용. null 이면 라벨 숨김.
  final String? beforeStage;
  final String? afterStage;

  /// 루트 Navigator 위에 push 해 시스템 UI(상태바 포함) 까지 덮는다.
  /// 호출 측은 await 으로 닫힘 시점을 받을 수 있다.
  static Future<void> show(
    BuildContext context, {
    required String beforeImageUrl,
    required String animationUrl,
    required String afterImageUrl,
    String? beforeStage,
    String? afterStage,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => EvolutionOverlay(
          beforeImageUrl: beforeImageUrl,
          animationUrl: animationUrl,
          afterImageUrl: afterImageUrl,
          beforeStage: beforeStage,
          afterStage: afterStage,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<EvolutionOverlay> createState() => _EvolutionOverlayState();
}

enum _EvolutionPhase { silhouette, animation, reveal, complete }

class _EvolutionOverlayState extends State<EvolutionOverlay> {
  _EvolutionPhase _phase = _EvolutionPhase.silhouette;

  // 단계 전환 타이머. tap-to-skip / dispose 시 모두 cancel.
  Timer? _toAnimation;
  Timer? _toReveal;
  Timer? _toComplete;
  Timer? _autoClose;

  // 단계 길이. 합산 ≈ 4.7초. gif 자체 길이를 알 수 없어 _animationDur 로 끊는다.
  static const Duration _silhouetteDur = Duration(milliseconds: 600);
  static const Duration _animationDur = Duration(milliseconds: 2400);
  static const Duration _revealDur = Duration(milliseconds: 500);
  static const Duration _holdDur = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _schedulePhases();
    // animation 단계가 시작될 때 silhouette 위로 gif 가 잠깐 깜빡일 수 있어
    // 새 캐릭터 이미지를 미리 ImageCache 에 적재 → reveal 이 즉시 첫 프레임 그림.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.afterImageUrl.isNotEmpty) {
        precacheImage(NetworkImage(widget.afterImageUrl), context);
      }
    });
  }

  void _schedulePhases() {
    _toAnimation = Timer(_silhouetteDur, () {
      if (!mounted) return;
      setState(() => _phase = _EvolutionPhase.animation);
    });
    _toReveal = Timer(_silhouetteDur + _animationDur, () {
      if (!mounted) return;
      setState(() => _phase = _EvolutionPhase.reveal);
    });
    _toComplete = Timer(_silhouetteDur + _animationDur + _revealDur, () {
      if (!mounted) return;
      setState(() => _phase = _EvolutionPhase.complete);
    });
    _autoClose = Timer(
      _silhouetteDur + _animationDur + _revealDur + _holdDur,
      _close,
    );
  }

  /// 화면 탭 시: 아직 silhouette/animation 이면 reveal 로 점프, 그 뒤면 즉시 닫기.
  void _onTapToSkip() {
    if (_phase == _EvolutionPhase.silhouette ||
        _phase == _EvolutionPhase.animation) {
      _toAnimation?.cancel();
      _toReveal?.cancel();
      _toComplete?.cancel();
      _autoClose?.cancel();
      setState(() => _phase = _EvolutionPhase.reveal);
      _toComplete = Timer(_revealDur, () {
        if (!mounted) return;
        setState(() => _phase = _EvolutionPhase.complete);
      });
      _autoClose = Timer(_revealDur + _holdDur, _close);
      return;
    }
    _close();
  }

  void _close() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _toAnimation?.cancel();
    _toReveal?.cancel();
    _toComplete?.cancel();
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onTapToSkip,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 dim + blur. 다마고치 화면이 살짝 비치는 정도.
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            Center(child: _buildStage()),
            if (_phase == _EvolutionPhase.complete) _buildCompleteBadge(),
          ],
        ),
      ),
    );
  }

  /// 실루엣 / gif / 새 캐릭터를 같은 자리에 쌓아 단계별로 opacity 만 바꾼다.
  /// 같은 위치에서 변하므로 캐릭터가 "그 자리에서 진화" 한 인상이 됨.
  Widget _buildStage() {
    final double size = 180.sp;
    final double gifSize = size * 1.6;

    final showSilhouette = _phase == _EvolutionPhase.silhouette ||
        _phase == _EvolutionPhase.animation;
    final showAnimation = _phase == _EvolutionPhase.animation;
    final showAfter = _phase == _EvolutionPhase.reveal ||
        _phase == _EvolutionPhase.complete;

    return SizedBox(
      width: gifSize,
      height: gifSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 실루엣. silhouette 단계에선 살짝 scale up 하며 펄스 느낌.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: showSilhouette ? 1.0 : 0.0,
            child: AnimatedScale(
              duration: _silhouetteDur,
              curve: Curves.easeInOut,
              scale: _phase == _EvolutionPhase.silhouette ? 1.06 : 1.0,
              child: _SilhouetteImage(
                imageUrl: widget.beforeImageUrl,
                size: size,
              ),
            ),
          ),
          // 2. 반짝임 gif. animation 단계에서만 노출.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: showAnimation ? 1.0 : 0.0,
            child: SizedBox(
              width: gifSize,
              height: gifSize,
              child: widget.animationUrl.isEmpty
                  ? const SizedBox.shrink()
                  : Image.network(
                      widget.animationUrl,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
          ),
          // 3. 새 캐릭터. reveal 부터 페이드인 + ease-out-back 으로 살짝 튀어오름.
          AnimatedOpacity(
            duration: _revealDur,
            opacity: showAfter ? 1.0 : 0.0,
            child: AnimatedScale(
              duration: _revealDur,
              curve: Curves.easeOutBack,
              scale: showAfter ? 1.0 : 0.82,
              child: widget.afterImageUrl.isEmpty
                  ? SizedBox(width: size, height: size)
                  : Image.network(
                      widget.afterImageUrl,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => SizedBox(
                        width: size,
                        height: size,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// complete 단계 하단에 떠오르는 "유년기 → 성장기 진화 완료" 알약.
  /// raw stage → 한글 라벨 변환은 [CharacterStage.fromRaw] + badgeLabel 재사용.
  Widget _buildCompleteBadge() {
    final beforeLabel = _stageLabel(widget.beforeStage);
    final afterLabel = _stageLabel(widget.afterStage);
    final hasStages = beforeLabel != null && afterLabel != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 120.h,
      child: Center(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          offset: Offset.zero,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              hasStages
                  ? '$beforeLabel → $afterLabel 진화 완료!'
                  : '진화 완료!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _stageLabel(String? rawStage) {
    if (rawStage == null || rawStage.isEmpty) return null;
    return CharacterStage.fromRaw(rawStage).badgeLabel;
  }
}

/// 캐릭터 png/webp 위에 검은 색을 srcATop 으로 덮어 알파만 살린 실루엣.
/// 네트워크 이미지가 비어있거나 실패하면 빈 박스를 반환 (overlay 흐름은 유지).
class _SilhouetteImage extends StatelessWidget {
  const _SilhouetteImage({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return SizedBox(width: size, height: size);
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
      ),
    );
  }
}
