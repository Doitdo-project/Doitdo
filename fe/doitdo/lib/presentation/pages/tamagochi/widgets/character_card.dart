import 'dart:async';
import 'dart:math';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/pixel_icon_box.dart';
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
      height: 250.h + topSafePadding,
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

          // 중앙 하단: 말풍선 + 캐릭터. RoomLayer 가 들어올린 바닥선 위에
          // 캐릭터 발이 정확히 닿도록 같은 inset 을 공유한다 (RoomLayer.characterBottomInset).
          Positioned(
            left: 0,
            right: 0,
            top: topSafePadding+48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_speechText != null) ...[
                  _SpeechBubble(text: _speechText!),
                  SizedBox(height: 8.h),
                ],
                _buildCharacterSlot(),
              ],
            ),
          ),

          // 우측 상단 아이콘 (상점 / 도감) — 캐릭터 수령 이후에만 노출.
          // 픽셀 톤 방 일러스트와 결을 맞추기 위해 PixelIconBox 로 감싸고,
          // 아이콘은 shop / book 으로 교체.
          if (!hideChrome)
            Positioned(
              top: topSafePadding + 8.h,
              right: 16.w,
              child: Column(
                children: [
                  PixelIconBox(
                    onTap: onTapCollection,
                    child: Image.asset(
                      'assets/images/book.png',
                      width: 24.w,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  PixelIconBox(
                    onTap: onTapShop,
                    child: Image.asset(
                      'assets/images/shop.png',
                      width: 24.w,
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

  String? get _speechText {
    if (character == null) return null;
    if (character?.isEgg ?? false) return null;
    return state.speechBubble;
  }

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
    // 평상시 정적 thumbnailUrl(png) + 3-5초 간격 랜덤 깜빡임 (로컬 EYE gif).
    // 탭 후 서버가 내려준 동작 gif (idle 등) 가 있으면 그 url 로 잠시 swap.
    final overrideUrl = state.actionUrl;
    final isAction = overrideUrl != null && overrideUrl.isNotEmpty;
    final imageUrl = isAction ? overrideUrl : c.thumbnailUrl;
    return _GrownCharacter(
      key: ValueKey('grown-$imageUrl-${c.characterId}-${state.actionTick}'),
      thumbnailUrl: imageUrl,
      eyeGifCharacterId: isAction ? null : c.characterId,
      imageHeight: 120.h,
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

  // [DEV-TEMP] 평상시 png ↔ blink gif 토글을 끄고 base eye gif 만 항상 노출한다.
  // 정식 캐릭터 png/webp 에셋이 들어오면 false 로 돌려 원래 깜빡임 흐름 복구.
  static const bool _alwaysShowBaseGif = true;

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
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _scheduleTimer?.cancel();
    _blinkTimer?.cancel();
  }

  void _scheduleNextBlink() {
    if (_alwaysShowBaseGif) return;
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
    if (_alwaysShowBaseGif && id != null) {
      // [DEV-TEMP] 토글 없이 base eye gif 만. 로드 실패 시 png 폴백.
      image = Image.asset(
        'assets/animations/eye/$id.gif',
        height: widget.imageHeight,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (blinkAsset != null && id != null) {
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
