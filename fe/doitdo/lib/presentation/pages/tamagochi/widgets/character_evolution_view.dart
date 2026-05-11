import 'dart:async';

import 'package:flutter/material.dart';

import 'package:doitdo/domain/entities/evolution.dart';

/// 캐릭터 슬롯 자리에서 그대로 진행되는 진화 연출.
///
/// 흐름:
///   1. silhouette  : 진화 전 캐릭터를 검은 실루엣 + 살짝 펄스
///   2. animation   : 위에 [Evolution.animationUrl] gif 재생, 실루엣 유지
///   3. reveal      : 실루엣 → 새 캐릭터(`characterImageUrl`) 크로스페이드
///   4. complete(hold): 새 캐릭터를 잠깐 보여준 뒤 [onComplete] 호출
///
/// 탭하면 reveal 단계로 바로 점프. [onRevealStart] 는 reveal 진입 시점에
/// 한 번 호출되며, 호출자는 이때 home state refresh 를 트리거해 hold 안에
/// 새 캐릭터로 동기화가 끝나게 한다.
///
/// gif 가 캐릭터 본체보다 살짝 커야 반짝임이 캐릭터 주변까지 닿아 보이므로
/// 안쪽 Stack 은 [Clip.none] 으로 둔다 — 부모(character_card 의 Positioned)
/// 가 충분한 공간을 갖고 있어 약간의 overflow 는 자연스럽게 그려진다.
class CharacterEvolutionView extends StatefulWidget {
  const CharacterEvolutionView({
    super.key,
    required this.beforeImageUrl,
    required this.evolution,
    required this.size,
    this.beforeCharacterId,
    this.afterCharacterId,
    this.onAnimationStart,
    this.onComplete,
  });

  /// 진화 직전 캐릭터 썸네일(network). [beforeCharacterId] 의 eye gif 로딩 실패
  /// 시 fallback 으로 사용된다.
  final String beforeImageUrl;

  /// 진화 직전 캐릭터 종(species) ID. 홈에서 캐릭터를 그리는 로컬 eye gif
  /// (`assets/animations/eye/{id}.gif`) 와 동일한 에셋으로 silhouette 을 만들어
  /// 위치·크기가 홈 캐릭터와 정확히 일치하게 한다. null 이면 [beforeImageUrl]
  /// 만으로 그린다.
  final int? beforeCharacterId;

  /// 진화 후 캐릭터 종(species) ID. reveal 단계에서 홈과 동일한 eye gif 로
  /// 새 캐릭터를 그려, 연출 종료 후 home 으로 복귀할 때 크기/비율이 점프하지
  /// 않게 한다. null 이면 [Evolution.characterImageUrl] (network) fallback —
  /// 호출자는 [onAnimationStart] 콜백에서 home state refresh 를 트리거해 reveal
  /// 도달 전(animation 2.4s 동안)에 이 값을 채워 넣는다.
  final int? afterCharacterId;

  /// 진화 응답. animation gif 와 새 캐릭터 이미지 추출용.
  final Evolution evolution;

  /// 캐릭터 본체 표시 크기. silhouette / 새 캐릭터가 이 사이즈로 그려지고,
  /// gif 만 살짝 더 크게 깔린다.
  final double size;

  /// silhouette → animation 전환 시점(또는 tap-to-skip) 에 한 번 호출.
  /// 호출자는 이때 home state refresh 를 트리거 — animation 2.4s 동안 새
  /// 캐릭터의 characterId 를 받아오면 reveal 부터 eye gif 로 그릴 수 있다.
  final VoidCallback? onAnimationStart;

  /// hold 종료 후 호출. 호출자는 이걸 받아 active evolution 상태를 해제하고
  /// 카드가 일반 캐릭터 슬롯으로 복귀하게 한다.
  final VoidCallback? onComplete;

  @override
  State<CharacterEvolutionView> createState() => _CharacterEvolutionViewState();
}

enum _Phase { silhouette, animation, reveal, complete }

class _CharacterEvolutionViewState extends State<CharacterEvolutionView> {
  _Phase _phase = _Phase.silhouette;

  Timer? _toAnimation;
  Timer? _toReveal;
  Timer? _toComplete;
  Timer? _toDone;

  // 합산 ≈ 4초. gif 자체 길이를 알 수 없어 _animationDur 로 끊는다.
  static const Duration _silhouetteDur = Duration(milliseconds: 600);
  static const Duration _animationDur = Duration(milliseconds: 2400);
  static const Duration _revealDur = Duration(milliseconds: 500);
  static const Duration _holdDur = Duration(milliseconds: 500);

  bool _revealStartFired = false;

  @override
  void initState() {
    super.initState();
    _schedule();
    // reveal 시점에 즉시 표시되도록 새 캐릭터 이미지를 미리 캐시한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final url = widget.evolution.characterImageUrl;
      if (url.isNotEmpty) {
        precacheImage(NetworkImage(url), context);
      }
    });
  }

  void _schedule() {
    _toAnimation = Timer(_silhouetteDur, _enterAnimation);
    _toReveal = Timer(_silhouetteDur + _animationDur, () {
      if (!mounted) return;
      setState(() => _phase = _Phase.reveal);
    });
    _toComplete = Timer(_silhouetteDur + _animationDur + _revealDur, () {
      if (!mounted) return;
      setState(() => _phase = _Phase.complete);
    });
    _toDone = Timer(
      _silhouetteDur + _animationDur + _revealDur + _holdDur,
      () {
        if (!mounted) return;
        widget.onComplete?.call();
      },
    );
  }

  /// silhouette → animation 전환. [onAnimationStart] 1회 발화 가드 포함.
  /// tap-to-skip 로 silhouette 에서 곧장 reveal 로 점프하는 경우에도 동일
  /// 가드를 거쳐 refresh 가 한 번은 트리거되도록 한다.
  void _enterAnimation() {
    if (!mounted) return;
    setState(() => _phase = _Phase.animation);
    if (_revealStartFired) return;
    _revealStartFired = true;
    widget.onAnimationStart?.call();
  }

  /// 탭 시: silhouette/animation 단계면 reveal 로 점프, 그 뒤면 무시.
  /// (hold 도중 탭으로 즉시 종료시키면 화면이 너무 빨리 사라지는 인상.)
  void _onTap() {
    if (_phase != _Phase.silhouette && _phase != _Phase.animation) return;
    _toAnimation?.cancel();
    _toReveal?.cancel();
    _toComplete?.cancel();
    _toDone?.cancel();
    // animation 단계를 건너뛰더라도 onAnimationStart(refresh 트리거) 는 한 번
    // 보내야 reveal 시점에 새 characterId 를 들고 있을 가능성이 있다.
    if (!_revealStartFired) {
      _revealStartFired = true;
      widget.onAnimationStart?.call();
    }
    setState(() => _phase = _Phase.reveal);
    _toComplete = Timer(_revealDur, () {
      if (!mounted) return;
      setState(() => _phase = _Phase.complete);
    });
    _toDone = Timer(_revealDur + _holdDur, () {
      if (!mounted) return;
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _toAnimation?.cancel();
    _toReveal?.cancel();
    _toComplete?.cancel();
    _toDone?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    // gif 가 캐릭터보다 살짝 커야 반짝임이 가장자리까지 닿아 보인다. 너무 키우면
    // 카드 밖으로 새어나가 hardEdge clip 에 잘리므로 1.1배로 보수적으로.
    final gifSize = size * 1.1;

    final showSilhouette =
        _phase == _Phase.silhouette || _phase == _Phase.animation;
    final showAnimation = _phase == _Phase.animation;
    final showAfter = _phase == _Phase.reveal || _phase == _Phase.complete;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: size,
        width: double.infinity,
        // 홈의 _GrownCharacter 와 동일한 패턴: SizedBox(height) → Center → Image(height, contain).
        // Stack 안의 자식들도 height-only 로 그려 width 는 intrinsic 비율로 두면,
        // 같은 캐릭터 에셋(eye gif) 을 silhouette 으로 쓸 때 홈과 픽셀 단위로 위치/크기가 맞는다.
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. 실루엣. silhouette 단계에서 살짝 scale up 으로 펄스 느낌.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              opacity: showSilhouette ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: _silhouetteDur,
                curve: Curves.easeInOut,
                scale: _phase == _Phase.silhouette ? 1.06 : 1.0,
                child: _SilhouetteImage(
                  imageUrl: widget.beforeImageUrl,
                  characterId: widget.beforeCharacterId,
                  size: size,
                ),
              ),
            ),
            // 2. 반짝임 gif. animation 단계에서만 노출.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: showAnimation ? 1.0 : 0.0,
              child: SizedBox(
                width: gifSize,
                height: gifSize,
                child: widget.evolution.animationUrl.isEmpty
                    ? const SizedBox.shrink()
                    : Image.network(
                        widget.evolution.animationUrl,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
              ),
            ),
            // 3. 새 캐릭터. reveal 부터 페이드인 + ease-out-back.
            // afterCharacterId 가 있으면 홈과 동일한 eye gif 로 그려 연출 종료
            // 시 home 으로 복귀할 때 크기/비율이 점프하지 않게 한다. 없으면
            // 응답의 characterImageUrl(network) fallback.
            AnimatedOpacity(
              duration: _revealDur,
              opacity: showAfter ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: _revealDur,
                curve: Curves.easeOutBack,
                scale: showAfter ? 1.0 : 0.82,
                child: _AfterCharacterImage(
                  characterId: widget.afterCharacterId,
                  fallbackImageUrl: widget.evolution.characterImageUrl,
                  size: size,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 진화 전 캐릭터를 검은 실루엣으로 그린다.
///
/// 홈에서 캐릭터를 그릴 때 쓰는 `assets/animations/eye/{id}.gif` 를 우선 사용해
/// 위치·크기가 홈 화면과 정확히 일치하게 한다. 에셋 로드 실패 또는 [characterId]
/// 가 null 이면 network [imageUrl] 로 fallback. 둘 다 실패하면 빈 박스.
class _SilhouetteImage extends StatelessWidget {
  const _SilhouetteImage({
    required this.imageUrl,
    required this.characterId,
    required this.size,
  });

  final String imageUrl;
  final int? characterId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final id = characterId;
    final hasNetwork = imageUrl.isNotEmpty;

    final emptyBox = SizedBox(height: size);
    final networkFallback = hasNetwork
        ? Image.network(
            imageUrl,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => emptyBox,
          )
        : emptyBox;

    final base = id == null
        ? networkFallback
        : Image.asset(
            'assets/animations/eye/$id.gif',
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => networkFallback,
          );

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
      child: base,
    );
  }
}

/// 진화 후 캐릭터를 그린다. [characterId] 가 있으면 홈과 동일한 eye gif 에셋을
/// 사용해 연출 종료 시 home 으로 복귀할 때 크기/비율이 일치하게 한다.
/// 에셋 로드 실패 또는 id 가 null 이면 [fallbackImageUrl] 의 network 이미지로.
class _AfterCharacterImage extends StatelessWidget {
  const _AfterCharacterImage({
    required this.characterId,
    required this.fallbackImageUrl,
    required this.size,
  });

  final int? characterId;
  final String fallbackImageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final id = characterId;
    final emptyBox = SizedBox(height: size);
    final networkFallback = fallbackImageUrl.isEmpty
        ? emptyBox
        : Image.network(
            fallbackImageUrl,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => emptyBox,
          );

    if (id == null) return networkFallback;
    return Image.asset(
      'assets/animations/eye/$id.gif',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => networkFallback,
    );
  }
}
