import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/entities/evolution.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/character_evolution_view.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/room_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 다마고치 메인 상단의 방 일러스트 카드.
///
/// 캐릭터 단계별 분기:
/// - null    : 미수령 — 로딩 스피너 (정상 플로우에선 거의 보이지 않음)
/// - isEgg   : 알 아이콘 + TAP 배지. 탭하면 [onEggTap] 으로 부화 페이지로 이동.
/// - 그 외   : thumbnailUrl 로 캐릭터 이미지.
///
/// 우측 상단 [상점/도감] 아이콘은 부화 이후에만 노출. 이름/단계/경험치/스트릭은
/// 카드 바깥의 [StatusPill] 가 담당하므로 이 위젯에는 더 이상 표시되지 않는다.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.state,
    this.character,
    this.isCharacterLoading = false,
    this.evolution,
    this.beforeEvolutionImageUrl,
    this.beforeEvolutionCharacterId,
    this.afterEvolutionCharacterId,
    this.onEvolutionAnimationStart,
    this.onEvolutionComplete,
    this.onTapShop,
    this.onTapCollection,
    this.onEggTap,
    this.onCharacterTap,
    this.topSafePadding = 0,
  });

  final TamagochiState state;
  final Character? character;

  /// 최초 캐릭터 조회 중일 때 true. 캐릭터 영역만 살짝 가리는 용도.
  final bool isCharacterLoading;

  /// 진화 연출 활성화 데이터. non-null 이면 캐릭터 슬롯 자리에 진화 애니메이션
  /// (silhouette → gif → reveal) 이 재생된다. 말풍선도 자동으로 숨겨진다.
  /// null 이면 평상시 캐릭터 렌더로 복귀.
  final Evolution? evolution;

  /// 진화 직전 캐릭터 썸네일. 진화 트리거 시점에 호출자가 캡처해 넘긴다 —
  /// API 응답 후 home state 가 새 캐릭터로 바뀌어도 silhouette 단계에서
  /// 옛 캐릭터 모습이 그대로 유지된다.
  final String? beforeEvolutionImageUrl;

  /// 진화 직전 캐릭터 종(species) ID. 홈에서 그리던 eye gif 와 같은 에셋으로
  /// silhouette 을 만들어 위치/크기가 픽셀 단위로 일치하게 한다.
  final int? beforeEvolutionCharacterId;

  /// 진화 후 캐릭터 종(species) ID. reveal 단계에서 새 캐릭터를 eye gif 로
  /// 그릴 때 사용. 진화 시작 시점엔 알 수 없고, [onEvolutionAnimationStart]
  /// 에서 트리거된 refresh 가 home state 를 갱신하면 호출자가 이 값을 채워 넣는다.
  final int? afterEvolutionCharacterId;

  /// 진화 silhouette → animation 전환 콜백. 호출자는 이때 home state refresh 를
  /// 트리거 — animation 2.4s 동안 새 character 를 받아오면 reveal 부터 eye gif 로
  /// 그릴 수 있다.
  final VoidCallback? onEvolutionAnimationStart;

  /// 진화 hold 종료 후 콜백. 호출자는 active evolution 을 해제해 카드가
  /// 일반 캐릭터 슬롯으로 복귀하게 한다.
  final VoidCallback? onEvolutionComplete;

  final VoidCallback? onTapShop;
  final VoidCallback? onTapCollection;

  /// 알을 탭했을 때 호출. 부화 페이지로 이동 + 복귀 시 재조회는 부모가 담당.
  final VoidCallback? onEggTap;

  /// 부화 이후 캐릭터 본체를 탭했을 때 호출.
  final VoidCallback? onCharacterTap;

  /// 카드가 상태바 영역까지 확장될 때 content 가 상태바 아이콘과 겹치지 않도록
  /// 밀어낼 상단 여백. 배경(bg_grass)은 이 영역까지 그대로 이어지고, 내부 content
  /// 좌표만 이 값만큼 내려간다.
  final double topSafePadding;

  @override
  Widget build(BuildContext context) {
    // 미수령 중이거나 알 상태면 우측 상점/도감 아이콘은 숨긴다.
    final hideChrome = character == null || character!.isEgg;

    return SizedBox(
      // 침대/창문 일러스트가 잘리지 않도록 충분한 높이 확보. 캐릭터는 카드 하단
      // (= 바닥 영역) 에 정렬되어 발을 바닥에 두고 있는 것처럼 보이게 한다.
      // width 를 안 잡으면 부모(Column → outer Stack StackFit.loose) 가 loose 로
      // 흘려보내, 안쪽 Stack 의 자식이 모두 Positioned* 라 width 가 0 으로 collapse
      // → 카드가 통째로 빈 박스로 보이는 버그가 난다. 부모 max 까지 늘려 박는다.
      width: double.infinity,
      height: 300.h + topSafePadding,
      child: Stack(
        children: [
          // 방 배경 + 가구 합성. listMyFurnitures() 결과를 zIndex 순서로 쌓아
          // 그리고, 응답 전/실패 시 정적 자산으로 폴백.
          const Positioned.fill(child: RoomLayer()),

          // 진화/부화/독립 같은 주요 액션 중의 작은 스피너. copyWithPrevious 덕에
          // 이전 캐릭터 데이터는 그대로 남아 있고, 이 작은 스피너만 카드 좌측
          // 상단에 얹혀 "서버 갱신 중" 만 표현한다.
          if (isCharacterLoading && character != null)
            Positioned(
              top: topSafePadding + 20.h,
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

          // 중앙 하단: 말풍선 + 캐릭터. RoomLayer 가 들어올린 바닥선 위에
          // 캐릭터 발이 정확히 닿도록 같은 inset 을 공유한다 (RoomLayer.characterBottomInset).
          //
          // 말풍선은 Transform.translate 로 layout slot 은 그대로 두고 rendering 만
          // 아래로 밀어 캐릭터 머리 쪽으로 살짝 겹치게 한다 — 꼬리가 캐릭터를
          // 가리키는 형태로 자연스럽게 읽힘. 캐릭터 자체는 layout 위치 그대로
          // 유지해야 RoomLayer 바닥선에 발이 정확히 닿음.
          Positioned(
            left: 0,
            right: 0,
            top: topSafePadding + 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_speechText != null) ...[
                  Transform.translate(
                    offset: Offset(0, 10.h),
                    child: _SpeechBubble(text: _speechText!),
                  ),
                ],
                _buildCharacterSlot(),
              ],
            ),
          ),

          // 우측 상단 메뉴 — 캐릭터 수령 이후에만 노출.
          // PixelIconBox 두 개가 늘 떠있어서 뒤에 놓인 가구(TV 등)가 가려지던
          // 문제를 해결하기 위해, 평상시엔 햄버거 1개만 두고 탭 시에만 shop/book
          // 두 글래스 박스가 아래로 펼쳐진다. 톤은 StatusPill 의 글래스 스타일을
          // 그대로 따름.
          if (!hideChrome)
            Positioned(
              top: topSafePadding,
              right: 16.w,
              child: _RoomMenuButton(
                onTapShop: onTapShop,
                onTapCollection: onTapCollection,
              ),
            ),
        ],
      ),
    );
  }

  // ─── 렌더 분기 ────────────────────────────────────────────────

  String? get _speechText {
    if (character == null) return null;
    if (character?.isEgg ?? false) return null;
    // 진화 중에도 layout 안정성 + 시선 분산 방지를 위해 말풍선은 그대로 두되,
    // 안내 문구로 잠깐 갈음한다 (mainAxisAlignment.end 라 슬롯 위치 자체는 동일).
    if (evolution != null) return '쑥쑥 자라나!';
    return state.speechBubble;
  }

  Widget _buildCharacterSlot() {
    // 진화 연출 활성화: 일반 캐릭터/알/로딩 분기보다 우선해서 애니메이션 뷰로 대체.
    final ev = evolution;
    if (ev != null) {
      return CharacterEvolutionView(
        beforeImageUrl: beforeEvolutionImageUrl ?? character?.thumbnailUrl ?? '',
        beforeCharacterId:
            beforeEvolutionCharacterId ?? character?.characterId,
        afterCharacterId: afterEvolutionCharacterId,
        evolution: ev,
        size: 112.h,
        onAnimationStart: onEvolutionAnimationStart,
        onComplete: onEvolutionComplete,
      );
    }

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
    // 평상시 정적 thumbnailUrl(png) + 3-5초 간격 랜덤 깜빡임 (로컬 EYE gif).
    // 탭 후 서버가 내려준 동작 gif (idle 등) 가 있으면 그 url 로 잠시 swap.
    final overrideUrl = state.actionUrl;
    final isAction = overrideUrl != null && overrideUrl.isNotEmpty;
    final imageUrl = isAction ? overrideUrl : c.thumbnailUrl;
    return _GrownCharacter(
      key: ValueKey('grown-$imageUrl-${c.characterId}-${state.actionTick}'),
      thumbnailUrl: imageUrl,
      eyeGifCharacterId: isAction ? null : c.characterId,
      imageHeight: 112.h,
      onTap: onCharacterTap,
    );
  }
}

/// 캐릭터 머리 위 말풍선. 둥근 사각형 본체 + 아래 향하는 작은 삼각형 꼬리.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  static const Color _bubbleColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _bubbleColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.black87),
          ),
        ),
        CustomPaint(
          size: Size(10.w, 6.h),
          painter: _SpeechBubbleTailPainter(color: _bubbleColor),
        ),
      ],
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  const _SpeechBubbleTailPainter({required this.color});

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
  bool shouldRepaint(covariant _SpeechBubbleTailPainter old) =>
      old.color != color;
}

/// 서버 thumbnailUrl 이 비어있거나 로드 실패했을 때 자리를 지키는 중립 플레이스홀더.
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

/// 아직 알을 수령하지 않은 상태의 방어용 스피너.
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
///
/// 슬롯 높이는 [_GrownCharacter] 와 동일한 112.h. 알 이미지는 슬롯 하단에
/// 붙여 캐릭터 부화 후의 발 위치와 같은 row 에 닿게 하고, "톡톡 두드려보세요"
/// 힌트는 알 머리 위로 살짝 띄워 말풍선 톤으로 보이게 한다.
class _EggSlot extends StatelessWidget {
  const _EggSlot({required this.imageUrl, this.onTap});

  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 140.h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: _EggImage(imageUrl: imageUrl, size: 100.h),
              ),
            ),
            Positioned(
              top: 140.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 3.h,
                  ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

/// 이미 부화한 (egg 이외의) 캐릭터.
///
/// 평상시 표시:
///   - 정적 [thumbnailUrl] (서버 png) 가 기본.
///   - [eyeGifCharacterId] 가 주어지면 자체 Timer 로 3-5초 간격마다 1-2초 동안
///     로컬 EYE gif (`assets/animations/eye/{id}.gif`) 로 swap 해 깜빡임을 표현.
///   - 같은 id 에 `_2` 변형이 있는 캐릭터는 매 깜빡임마다 50/50 으로 base / 변형
///     중 하나를 랜덤 선택. 변형이 없으면 errorBuilder 체인이 base 로 자동 회귀.
///   - 에셋 / 네트워크 모두 실패 시 중립 플레이스홀더.
///
/// 액션 중(idle 등 서버 동작 gif) 에는 호출측이 [eyeGifCharacterId] 를 null 로
/// 두고 [thumbnailUrl] 에 액션 gif URL 을 넣어 — 깜빡임 타이머는 자동으로
/// 멈추고 액션 gif 가 그대로 그려진다.
class _GrownCharacter extends StatefulWidget {
  const _GrownCharacter({
    super.key,
    required this.thumbnailUrl,
    required this.imageHeight,
    this.eyeGifCharacterId,
    this.onTap,
  });

  final String thumbnailUrl;
  final double imageHeight;
  final int? eyeGifCharacterId;
  final VoidCallback? onTap;

  @override
  State<_GrownCharacter> createState() => _GrownCharacterState();
}

class _GrownCharacterState extends State<_GrownCharacter> {
  static final _rng = Random();

  static const _intervalMin = Duration(milliseconds: 2000);
  static const _intervalMax = Duration(milliseconds: 4000);

  static const _blinkMin = Duration(milliseconds: 500);
  static const _blinkMax = Duration(milliseconds: 1000);

  Timer? _scheduleTimer;
  Timer? _blinkTimer;

  String? _blinkAsset;

  @override
  void initState() {
    super.initState();
    _scheduleNextBlink();
  }

  @override
  void didUpdateWidget(covariant _GrownCharacter old) {
    super.didUpdateWidget(old);
    if (widget.eyeGifCharacterId != old.eyeGifCharacterId) {
      _cancelTimers();
      _blinkAsset = null;
      _scheduleNextBlink();
    }
  }

  @override
  void dispose() {
    // _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _scheduleTimer?.cancel();
    _blinkTimer?.cancel();
  }

  void _scheduleNextBlink() {
    if (widget.eyeGifCharacterId == null) return;
    final delay = _randomDuration(_intervalMin, _intervalMax);
    _scheduleTimer = Timer(delay, _startBlink);
  }

  void _startBlink() {
    if (!mounted) return;
    final id = widget.eyeGifCharacterId;
    if (id == null) return;
    final useVariant = _rng.nextBool();
    final path = useVariant
        ? 'assets/animations/eye/${id}_2.gif'
        : 'assets/animations/eye/$id.gif';
    setState(() => _blinkAsset = path);
    final duration = _randomDuration(_blinkMin, _blinkMax);
    _blinkTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => _blinkAsset = null);
      _scheduleNextBlink();
    });
  }

  Duration _randomDuration(Duration min, Duration max) {
    final spanMs = max.inMilliseconds - min.inMilliseconds;
    final extra = spanMs > 0 ? _rng.nextInt(spanMs + 1) : 0;
    return Duration(milliseconds: min.inMilliseconds + extra);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.eyeGifCharacterId;

    final fallback = widget.thumbnailUrl.isEmpty
        ? const _CharacterPlaceholder()
        : Image.network(
            widget.thumbnailUrl,
            height: widget.imageHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const _CharacterPlaceholder(),
          );

    final blinkAsset = _blinkAsset;
    Widget image;
    if (blinkAsset != null && id != null) {
      final base = 'assets/animations/eye/$id.gif';
      image = Image.asset(
        blinkAsset,
        height: widget.imageHeight,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => blinkAsset == base
            ? fallback
            : Image.asset(
                base,
                height: widget.imageHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => fallback,
              ),
      );
    } else {
      image = fallback;
    }

    final slot = SizedBox(
      height: widget.imageHeight,
      child: Center(child: image),
    );
    if (widget.onTap == null) return slot;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: slot,
    );
  }
}

/// 우상단 햄버거 메뉴. 평상시엔 햄버거 한 칸만 노출되어 방 가구를 가리는 면적을
/// 최소화하고, 탭하면 그 아래로 [상점] / [도감] 글래스 박스가 펼쳐진다.
///
/// 메뉴 아이템을 탭하면 자동으로 collapse 되며 콜백을 발화 — 페이지 이동 후
/// 돌아왔을 때 펼친 상태가 남아있지 않도록.
class _RoomMenuButton extends StatefulWidget {
  const _RoomMenuButton({this.onTapShop, this.onTapCollection});

  final VoidCallback? onTapShop;
  final VoidCallback? onTapCollection;

  @override
  State<_RoomMenuButton> createState() => _RoomMenuButtonState();
}

class _RoomMenuButtonState extends State<_RoomMenuButton> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  void _onItemTap(VoidCallback? cb) {
    setState(() => _expanded = false);
    cb?.call();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colors.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _GlassIconBox(
          onTap: _toggle,
          // 햄버거 ↔ X 회전 전환은 90° 만 — 닫힘/열림 상태가 자연스럽게 읽힘.
          child: AnimatedRotation(
            turns: _expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.menu_rounded, size: 20.sp, color: iconColor),
          ),
        ),
        // ClipRect + AnimatedAlign(heightFactor) 로 펼침/접힘을 위에서 아래로
        // 슬라이드. AnimatedOpacity 로 페이드를 함께 줘 collapse 도중 컨텐츠가
        // 잘려보이는 인상이 덜하게.
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            heightFactor: _expanded ? 1.0 : 0.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _expanded ? 1.0 : 0.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 8.h),
                  _GlassIconBox(
                    onTap: () => _onItemTap(widget.onTapShop),
                    child: Image.asset(
                      'assets/images/shop.png',
                      width: 24.w,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _GlassIconBox(
                    onTap: () => _onItemTap(widget.onTapCollection),
                    child: Image.asset(
                      'assets/images/book.png',
                      width: 24.w,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// StatusPill 과 같은 글래스 톤(BackdropFilter blur + 반투명 bg + 흰 보더 +
/// 두 단 그림자)의 정사각 아이콘 박스. 픽셀 톤이 무거워서 뒤에 놓인 방 가구를
/// 가리는 게 부담스러울 때 PixelIconBox 대신 사용.
class _GlassIconBox extends StatelessWidget {
  const _GlassIconBox({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final box = Container(
      width: 36.w,
      height: 36.w,
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
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: colors.streakCardBg.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
    if (onTap == null) return box;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: box,
    );
  }
}
