import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/entities/evolution.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/character_evolution_view.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/room_layer.dart';
import 'package:doitdo/presentation/widgets/common/room_furniture_slots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
    this.onPoopTap,
    this.isCleaningPoop = false,
    this.suppressPoop = false,
    this.poopLeftRatio,
    this.poopBottomRatio,
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

  /// 부화 이후 캐릭터 본체를 탭했을 때 호출. 인자는 사용자가 탭한 글로벌 좌표로,
  /// 호출자(page) 가 그 위치에서 floating "+코인" 위젯을 띄우는 데 사용한다.
  final ValueChanged<Offset>? onCharacterTap;

  /// 방 안 똥을 탭했을 때 호출. 인자는 사용자가 탭한 글로벌 좌표(손가락 위치).
  /// 페이지가 brush.gif 오버레이 2초 + POOP action 호출을 함께 처리하고, 응답의
  /// earnedAmount > 0 이면 이 좌표에서 floating "+N" 위젯을 띄운다.
  final ValueChanged<Offset>? onPoopTap;

  /// 똥 청소 진행 중 여부. true 면 캐릭터 카드에 brush.gif 가 그려진다.
  final bool isCleaningPoop;

  /// 청소 흐름의 phase 2 — 서버 응답 전이라 character.poop 은 여전히 true 지만
  /// 시각적으로는 poop 을 먼저 사라지게 한다. brush.gif 는 [isCleaningPoop] 가
  /// 끝날 때까지 계속 보인다.
  final bool suppressPoop;

  /// 똥 위치 (캔버스 비율). page 가 새 똥 발생 시점에 안전 범위 안에서 random 으로
  /// 뽑아 흘려보낸다. null 이면 RoomLayer 의 default 위치 사용.
  final double? poopLeftRatio;
  final double? poopBottomRatio;

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
      //
      // height 의 raw 디자인 값([kRoomFrameDesignHeight]) 은 SSOT 로 추출되어
      // 상점 미리보기 등 외곽 박스 비율을 재현해야 하는 다른 화면에서 동일 기준으로
      // 참조한다 ([computeRoomFrameAspect]).
      width: double.infinity,
      height: kRoomFrameDesignHeight.h + topSafePadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 가구 캔버스와 동일한 AR 로 잠가, 캐릭터 발 위치도 가구 바닥선과 함께
          // 디바이스에 무관하게 정렬되도록 한다.
          final canvas = computeRoomCanvasLayout(
            parentWidth: constraints.maxWidth,
            parentHeight: constraints.maxHeight,
            aspect: kRoomCanvasAspect,
          );
          // 바닥선(러그 슬롯 bottom 비율) 위에 발이 닿도록 동일 비율을 공유.
          // 슬롯 정의(`kRoomFurnitureSlots[rug].bottom = 0.14`) 와 1:1.
          const floorInsetRatio = 0.14;
          final floorInset = canvas.height * floorInsetRatio;

          // 똥 / 청소(brush) 는 [RoomLayer] 의 가구 Stack 마지막 자리에 그려
          // rug 같은 가구 위에 z-stack 되는 게 보장된다. 알 상태에서는 숨김.
          //
          // 청소 phase 2 에서는 [suppressPoop] 로 poop 을 먼저 사라지게 하고
          // brush.gif 만 잠시 더 그려, 빗자루로 똥을 쓸어낸 듯한 흐름을 만든다.
          final showPoop = character != null &&
              !character!.isEgg &&
              character!.poop &&
              !suppressPoop;
          final showBrush =
              character != null && !character!.isEgg && isCleaningPoop;

          return Stack(
            children: [
              // 방 배경 + 가구 + 똥/brush 합성. 한 캔버스 안에서 z-order 가 잡혀,
              // 외부 Stack 으로 끌어올리지 않아도 가구 위로 떠 있는다.
              Positioned.fill(
                child: RoomLayer(
                  showPoop: showPoop,
                  showBrush: showBrush,
                  onPoopTap: onPoopTap,
                  poopLeftRatio: poopLeftRatio,
                  poopBottomRatio: poopBottomRatio,
                ),
              ),

              // 좌상단 갱신 스피너는 의도적으로 제거 — 평상시 캐릭터 카드가
              // 안정적으로 그려지는 인상을 주는 게 더 중요하다. 진화/부화/독립
              // 진행 상태는 별도의 evolution 연출이 표현하므로 추가 알림 불요.

              // 중앙 하단: 말풍선 + 캐릭터. 캔버스 하단에 발이 닿도록 bottom anchor
              // 로 잡고, 캔버스 높이 비율(`floorInsetRatio`)만큼 띄워 러그 위에
              // 정확히 서있는 것처럼 보이게 한다. 디바이스가 달라져 카드 / 캔버스
              // 높이가 바뀌어도 캐릭터-바닥 관계는 동일하게 유지된다.
              //
              // 말풍선과 캐릭터는 [_WalkingSlot] 안에서 함께 한 Column 으로 묶여 있어,
              // 캐릭터가 방을 돌아다닐 때 말풍선도 같은 transform 으로 따라간다 —
              // 꼬리가 늘 캐릭터 머리를 가리키는 형태가 유지된다. 말풍선 본체의
              // Transform.translate(0, 10.h) 는 그대로 — layout 슬롯은 안 흔들고
              // 렌더링만 살짝 아래로 밀어 캐릭터 머리에 겹치게 하는 시각 트릭이다.
              Positioned(
                left: 0,
                right: 0,
                bottom: floorInset,
                child: _WalkingSlot(
                  enableWalk: _shouldWalk,
                  // 진화 진입 시점에는 walking 좌표가 아닌 가운데에서 연출이
                  // 시작되어야 자연스럽다. 액션(탭) 은 그 자리에서 반응해야
                  // 하므로 false 유지.
                  snapToCenterOnDisable: evolution != null,
                  onCharacterTap: _isGrown ? onCharacterTap : null,
                  bubble: _speechText != null
                      ? Transform.translate(
                          offset: Offset(0, 10.h),
                          child: _AutoToggledBubble(text: _speechText!),
                        )
                      : null,
                  characterBuilder: (_, isWalking) =>
                      _buildCharacterSlot(isWalking),
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
          );
        },
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

  /// _buildCharacterSlot 의 grown 분기에 도달하는 조건과 동일 — 캐릭터가 부화 이후
  /// 의 평상시(또는 액션) 상태로 렌더되는가. _WalkingSlot 이 탭 영역을 활성화할지
  /// 결정하는 데 쓴다.
  bool get _isGrown {
    if (evolution != null) return false;
    if (isCharacterLoading && character == null) return false;
    final c = character;
    if (c == null) return false;
    if (c.isEgg) return false;
    return true;
  }

  /// _WalkingSlot 이 실제로 보행을 돌릴지. 평상시 grown 상태에서만 true 이고, 액션
  /// gif 가 떨어진 동안은 false 로 떨어뜨려 _WalkingSlot 이 마지막 위치에서 정지한
  /// 채 액션 gif 가 재생되게 한다.
  bool get _shouldWalk {
    if (!_isGrown) return false;
    final url = state.actionUrl;
    return url == null || url.isEmpty;
  }

  Widget _buildCharacterSlot(bool isWalking) {
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
      // 첫 진입에서 캐릭터 데이터가 도착할 때까지의 짧은 윈도우. 큰 주황 스피너가
      // 캐릭터 자리에 박히면 시각적으로 거슬리고 캐릭터가 "확" 등장하는 인상을 줘서
      // 빈 슬롯으로 두고 grass 배경만 보이게 한다 — 데이터 도착 직후 캐릭터가
      // 자연스럽게 자리에 그려진다.
      return SizedBox(height: 100.h);
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
      // key 는 슬롯 단위로 stable 하게 유지 — 캐릭터 종(species) 변경(진화) 시
      // 에도 같은 widget instance 가 prop diff 로 처리하도록 한다. CachedNetworkImage
      // 의 useOldImageOnUrlChange 가 효과를 발휘해 새 PNG 디코드 끝날 때까지
      // 이전 캐릭터 이미지가 그대로 painted 상태로 남아 진화 직후 invisible
      // 윈도우가 안 생긴다 (key 가 바뀌면 새 instance 라 이전 frame 유지 불가).
      key: const ValueKey('grown'),
      thumbnailUrl: imageUrl,
      eyeGifCharacterId: isAction ? null : c.characterId,
      imageHeight: 80.h,
      // 액션 중에는 walking 으로 보이면 안 된다(공용 10.gif 대신 액션 gif 가
      // base 여야 함). _WalkingSlot 이 enableWalk=false 일 때도 builder 를
      // isWalking=false 로 호출하지만, 안전하게 isAction 도 OR 로 묶어 명시.
      isWalking: isWalking && !isAction,
      // 탭은 바깥 _WalkingSlot 이 받아 walk 정지 + 콜백 호출까지 한 번에 처리한다.
      // 여기서 또 GestureDetector 를 만들면 hit-test 가 중첩되어 어느 한 쪽만
      // 동작하는 회색지대가 생긴다.
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

/// [_SpeechBubble] 을 "트리거 시 잠깐 표시 후 사라짐" 패턴으로 감싸는 래퍼.
///
/// - 초기 mount: 첫 [text] 한 번 노출 → 4~5초 후 fade out → 다음 트리거 전까지 hidden
/// - [text] 가 바뀌면(예: 캐릭터 탭으로 ViewModel 이 새 문구를 뽑음) 즉시 visible
///   + hide 타이머 재시작
/// - 평상시엔 화면이 캐릭터 위주로 깔끔하고, 인터랙션 직후에만 말풍선이 반응 —
///   TODO 완료 / 크레딧 획득 등 다른 트리거로 확장하기 좋은 구조.
/// - Layout 슬롯은 항상 유지(opacity 만 토글). Column 의 character 위치가 흔들리지
///   않게 하기 위함.
class _AutoToggledBubble extends StatefulWidget {
  const _AutoToggledBubble({required this.text});

  final String text;

  @override
  State<_AutoToggledBubble> createState() => _AutoToggledBubbleState();
}

class _AutoToggledBubbleState extends State<_AutoToggledBubble> {
  static final _rng = Random();

  static const int _showDurationMinMs = 4000;
  static const int _showDurationMaxMs = 5000;
  static const Duration _fadeDuration = Duration(milliseconds: 300);

  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(covariant _AutoToggledBubble old) {
    super.didUpdateWidget(old);
    if (widget.text != old.text) {
      _hideTimer?.cancel();
      setState(() => _visible = true);
      _scheduleHide();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    final span = _showDurationMaxMs - _showDurationMinMs;
    final ms = _showDurationMinMs + _rng.nextInt(span + 1);
    _hideTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: _fadeDuration,
        child: _SpeechBubble(text: widget.text),
      ),
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

/// 캐릭터 thumbnailUrl / 액션 gif 를 위한 캐시 + 다운샘플 wrapper.
///
/// `useOldImageOnUrlChange: true` 로 url 이 바뀌어도 새 이미지가 디코드 완료될
/// 때까지 이전 frame 을 유지 — 액션 gif 시작/종료, 진화 캐릭터 변경 등 모든
/// url 전환에서 빈 placeholder 가 한 frame 깜빡이는 것을 막는다.
/// `_GrownCharacter` 가 stable key 라 같은 instance 를 유지하므로 이 효과가 살아있다.
class _CachedCharacterImage extends StatelessWidget {
  const _CachedCharacterImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // 캐릭터 본체는 ~80.h (3x DPI 환산 ≈ 240px). 여유 잡아 320 캡.
      memCacheHeight: 320,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => const _CharacterPlaceholder(),
    );
  }
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

/// 아직 알을 수령하지 않은 상태의 방어용 빈 슬롯.
/// 일반 플로우에서는 거의 보이지 않는 매우 좁은 윈도우 — 별도 스피너 없이
/// grass 배경만 비춰지게 둔다.
class _UnreceivedSlot extends StatelessWidget {
  const _UnreceivedSlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 100.h);
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
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // 알 이미지는 ~100.h (3x DPI 환산 ≈ 300px). 여유 잡아 400 캡 — 메모리/디코드
      // 부담을 줄이면서 시각 품질은 유지.
      memCacheHeight: 400,
      // 디스크 캐시 적중시엔 페이드 없이 즉시. 첫 다운로드시에도 placeholder 없이
      // 그대로 빈 자리에서 등장 — 알 상태는 어차피 진입 동선이 짧다.
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => _fallback(),
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
    this.isWalking = false,
  });

  final String thumbnailUrl;
  final double imageHeight;
  final int? eyeGifCharacterId;

  /// 보행 중인지 여부. true 면 base 를 공용 둠칫둠칫 gif (`10.gif`) 로 그리고
  /// blink overlay 는 비활성한다 — 10.gif 위에 다른 캐릭터의 eye gif 가 겹쳐
  /// 두 그림이 동시에 보이는 현상 방지. false (정지/액션) 면 캐릭터별 PNG /
  /// 액션 gif 를 base 로 쓰고 평소처럼 간헐 blink.
  final bool isWalking;

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
  // 매 blink 마다 GIF 위젯이 frame 0 부터 재생되도록 부여하는 키.
  int _blinkTick = 0;

  bool _assetsPrecached = false;

  @override
  void initState() {
    super.initState();
    // 시작 시점이 walking 이면 base 가 10.gif 라 blink overlay 는 의미 없음.
    // idling/액션 진입 시 didUpdateWidget 에서 켜진다.
    if (!widget.isWalking) _scheduleNextBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // GIF/PNG 모두 미리 디코드해 두면 첫 표시·swap 모두 디코드 지연 없이 즉시 그려진다.
    // Stack 으로 동시에 띄워도 깜빡임이 보이지 않으려면 이 단계가 필수.
    if (!_assetsPrecached) {
      _assetsPrecached = true;
      _precacheAll();
    }
  }

  @override
  void didUpdateWidget(covariant _GrownCharacter old) {
    super.didUpdateWidget(old);
    final assetChanged = widget.eyeGifCharacterId != old.eyeGifCharacterId ||
        widget.thumbnailUrl != old.thumbnailUrl;
    if (assetChanged) {
      _cancelTimers();
      _blinkAsset = null;
      _assetsPrecached = false;
      _precacheAll();
      _assetsPrecached = true;
      if (!widget.isWalking) _scheduleNextBlink();
      return;
    }
    if (widget.isWalking != old.isWalking) {
      if (widget.isWalking) {
        // walking 진입 — blink 스케줄러 정지 + 현재 떠있는 blink 도 즉시 내림.
        _cancelTimers();
        _blinkAsset = null;
      } else {
        // 정지/액션 진입 — idling 이 1~2초로 짧아 평상시 간격(2~4초) 으론 blink 가
        // 한 번도 안 발화되고 walking 으로 돌아가는 일이 생긴다. 빠르게는 발화.
        // 단, 0ms (=즉시) 면 base 가 walking gif → PNG 로 visibility 토글되는
        // 직후라 PNG 디코드/paint 가 한 frame 늦으면 그 사이에 eye gif 만 떠
        // 있는 시점이 생기거나, walking gif 마지막 frame 위에 eye gif 가 덮여
        // 두 캐릭터가 잠깐 겹쳐 보인다. ~200ms 의 안전 마진을 둔다.
        _scheduleNextBlink(initialDelay: const Duration(milliseconds: 200));
      }
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

  void _precacheAll() {
    final id = widget.eyeGifCharacterId;
    if (id != null) {
      precacheImage(AssetImage('assets/animations/eye/$id.gif'), context);
      precacheImage(AssetImage('assets/animations/eye/${id}_2.gif'), context)
          .catchError((_) {}); // 변형이 없을 수 있어 실패는 무시.
    }
    if (widget.thumbnailUrl.isNotEmpty) {
      // 표시는 CachedNetworkImage(= CachedNetworkImageProvider) 를 쓰므로
      // 같은 provider 로 워밍해야 캐시 적중. memCacheHeight 다운샘플은
      // CachedNetworkImage 가 내부적으로 ResizeImage 로 처리하므로 precache 도
      // 동일 형태가 매칭되긴 하지만, ResizeImage 를 명시하면 추가 디코드 단계가
      // 끼어 첫 표시가 오히려 늦어지는 경우가 있어 raw provider 만 워밍한다.
      precacheImage(CachedNetworkImageProvider(widget.thumbnailUrl), context)
          .catchError((_) {});
    }
    // 보행 중 base 로 쓰는 캐릭터별 idle gif. walking ↔ idling swap 시 디코드
    // 지연으로 한 frame 비는 걸 막기 위해 미리 디코드. 일부 캐릭터는 idle gif
    // 가 아직 없을 수 있어 실패는 무시.
    if (id != null) {
      precacheImage(AssetImage('assets/animations/idle/$id.gif'), context)
          .catchError((_) {});
    }
  }

  void _scheduleNextBlink({Duration? initialDelay}) {
    if (widget.eyeGifCharacterId == null) return;
    // 호출측이 [initialDelay] 를 주면 그 시간 후 첫 발화. 평상시 후속 스케줄은
    // _intervalMin~_intervalMax 간격.
    final delay = initialDelay ?? _randomDuration(_intervalMin, _intervalMax);
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
    setState(() {
      _blinkAsset = path;
      _blinkTick++;
    });
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
    // walking 중에는 blink 를 띄우지 않음 — idle gif 위에 다른 캐릭터의 eye gif 가
    // 겹쳐 두 그림이 동시에 보이는 현상을 차단.
    final blinkAsset = widget.isWalking ? null : _blinkAsset;

    // walking: 캐릭터별 idle gif (`assets/animations/idle/$id.gif`). 일부 캐릭터는
    // 아직 idle gif 가 없을 수 있어 PNG 로 폴백.
    // idling/액션: 캐릭터별 PNG (또는 호출측에서 넣은 액션 gif URL).
    //
    // 두 base 모두 항상 트리에 두고 Visibility 로 토글한다 — 같은 widget type
    // 으로 강제 swap 하면 type-mismatch (Image.asset / CachedNetworkImage) 으로
    // element 가 mount/unmount 되어 1 frame 비는 케이스가 생긴다.
    // CachedNetworkImage 쪽은 useOldImageOnUrlChange 로 url 변경 (PNG ↔ 액션
    // gif, 진화로 캐릭터 변경 등) 시 이전 frame 을 유지해 매끄럽게 swap.
    final hasIdleGif = id != null;
    final showWalking = widget.isWalking && hasIdleGif;
    final walkingBase = !hasIdleGif
        ? const SizedBox.shrink()
        : Image.asset(
            'assets/animations/idle/$id.gif',
            height: widget.imageHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            // idle gif 가 없는 캐릭터는 빈 자리. idleBase 가 옆에서 항상 켜져
            // 있으니 Visibility 가 그쪽으로 흐르도록 useFallback 로직은 두지 않음.
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
    final idleBase = widget.thumbnailUrl.isEmpty
        ? const _CharacterPlaceholder()
        : _CachedCharacterImage(
            url: widget.thumbnailUrl,
            height: widget.imageHeight,
          );

    Widget? blinkOverlay;
    if (id != null && blinkAsset != null) {
      final basePath = 'assets/animations/eye/$id.gif';
      // ValueKey 로 매 blink 마다 GIF 위젯을 새로 mount → frame 0 부터 재생.
      blinkOverlay = Image.asset(
        blinkAsset,
        key: ValueKey('blink-$blinkAsset-$_blinkTick'),
        height: widget.imageHeight,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => blinkAsset == basePath
            ? const SizedBox.shrink()
            : Image.asset(
                basePath,
                key: ValueKey('blink-fallback-$_blinkTick'),
                height: widget.imageHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
      );
    }

    // widthFactor: 1.0 으로 Center 가 child 의 자연 폭(이미지 BoxFit.contain 결과
    // = 자연 종횡비 폭) 만큼만 차지하도록 한다. 기본 widthFactor=null 이면 Center 가
    // 부모의 max 폭(= 캔버스 전체) 으로 확장돼 _WalkingSlot 의 GestureDetector hit 영역도
    // 캐릭터 양옆의 빈 여백까지 덮어, "캐릭터 아닌 곳을 눌러도 말풍선이 바뀌는" 버그가
    // 생긴다.
    return SizedBox(
      height: widget.imageHeight,
      child: Center(
        widthFactor: 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // walking gif. maintainState/maintainAnimation 으로 inactive 동안에도
            // ImageStream 을 살려두어 visibility 토글 순간 즉시 paint 된다.
            Visibility(
              visible: showWalking,
              maintainState: true,
              maintainAnimation: true,
              child: walkingBase,
            ),
            Visibility(
              visible: !showWalking,
              maintainState: true,
              maintainAnimation: true,
              child: idleBase,
            ),
            ?blinkOverlay,
          ],
        ),
      ),
    );
  }
}

/// 말풍선 + 캐릭터 슬롯을 함께 감싸 방 안을 자유롭게 돌아다니게 한다.
///
/// - 매 사이클마다 카드 가운데(0) 기준 random target (±_walkRangeX.w, -_walkRangeY..0.h)
///   을 뽑아 그쪽으로 easeInOut 보간 이동. 도착하면 다음 target 으로 끊김 없이 연결.
/// - 사이클 시간도 매번 [_walkDurationMinMs, _walkDurationMaxMs] 에서 랜덤 — 모든
///   발걸음이 같은 박자로 안 떨어져 살아있는 느낌.
/// - 메인 이동 위에 sin bob 을 얹어 발걸음 톤의 잔진동.
/// - 진행 방향(target x 부호)을 따라 X 축 반전 — 향하는 쪽을 본다.
/// - 캐릭터 탭 시 walk 가 즉시 멈추고 콜백을 호출. 외부에서 액션 사이클이
///   끝나(=[enableWalk] 가 false 였다가 다시 true) 면 새 target 으로 부드럽게 재개.
///   서버 호출 실패 등으로 액션 사이클 자체가 안 들어와도 [_tapPauseTimeout] 안에
///   자동 재개 — 영구 정지 방지.
/// - 알/미수령/진화/액션 등 [enableWalk] 가 false 인 상태에서는 transform 없이
///   가운데에 정적으로 표시.
/// 보행 사이클의 두 단계 — [walking] 은 좌우상하 random target 보행 (base 가
/// 공용 둠칫둠칫 gif), [idling] 은 도착점에서 잠깐 멈춰서 캐릭터별 PNG + 간헐
/// blink 를 보여주는 단계. 한 사이클 = walking → idling → walking ... 반복.
enum _WalkPhase { walking, idling }

class _WalkingSlot extends StatefulWidget {
  const _WalkingSlot({
    required this.enableWalk,
    required this.characterBuilder,
    this.bubble,
    this.onCharacterTap,
    this.snapToCenterOnDisable = false,
  });

  /// true 면 캐릭터가 방 안을 자유 보행. false 면 transform 없이 가운데 고정.
  final bool enableWalk;
  // 자식 캐릭터 위젯 — 현재 phase 가 walking 인지를 받아 base / blink 표현을
  // 적절히 선택할 수 있게 한다. _GrownCharacter 는 isWalking 으로 분기하고,
  // 알/미수령 등 다른 분기는 그 값을 무시한다.
  final Widget Function(BuildContext, bool isWalking) characterBuilder;
  final Widget? bubble;

  /// 캐릭터 본체 탭 콜백. 인자는 글로벌 좌표(손가락 위치). null 이면 탭 영역 자체가 비활성.
  final ValueChanged<Offset>? onCharacterTap;

  /// [enableWalk] 가 false 로 전환될 때 현재 walking 위치를 고정(기본) 하지 않고
  /// 가운데(0,0) 로 즉시 snap 한다. 진화 연출처럼 캐릭터가 늘 카드 중앙에서
  /// 시작해야 자연스러운 케이스에 사용. 액션(탭) 처럼 그 자리에서 반응해야 하는
  /// 케이스는 false 로 둔다.
  final bool snapToCenterOnDisable;

  @override
  State<_WalkingSlot> createState() => _WalkingSlotState();
}

class _WalkingSlotState extends State<_WalkingSlot>
    with SingleTickerProviderStateMixin {
  static final _rng = Random();

  // 한 구간(현재 위치 → 다음 random target) 이동 시간 범위(ms). 매 사이클마다 이
  // 범위에서 랜덤 선택해, 모든 발걸음이 같은 박자로 안 떨어진다.
  static const int _walkDurationMinMs = 5500;
  static const int _walkDurationMaxMs = 6000;
  // 좌우 이동 범위(.w). 베이스(0) 기준 ±이 만큼 사이에서 다음 target 의 x 좌표를 뽑음.
  static const double _walkRangeX = 60.0;
  // 한 구간당 X 가 이전 X 에서 변화할 수 있는 폭(.w). 매 구간마다 ±_walkRangeX 안에서
  // 새로 뽑으면 가운데 기준으로 좌-우-좌-우 왕복하는 느낌이 강해서 지그재그처럼
  // 보임. 이전 X 기준 ±이 만큼만 변동 + clamp 으로, 한 방향으로 흘러가다 끝에서
  // 자연스럽게 turn 하는 보행 패턴이 된다.
  static const double _walkXJitter = 40.0;
  // 상하 이동 범위(.h). 베이스(0) 기준 -이 만큼 위쪽까지만 — 아래로 가면 카드 바닥선을
  // 넘어 발이 잘릴 수 있어 위쪽 방향으로만 한정.
  static const double _walkRangeY = 30.0;
  // 한 구간당 Y 가 이전 Y 에서 변화할 수 있는 폭(.h). 매 구간마다 Y 를 0..
  // -_walkRangeY 안에서 새로 뽑으면 위아래로 휙휙 튀어 지그재그처럼 보이기 때문에,
  // 이전 Y 기준 ±이 만큼만 변동하고 결과를 _walkRangeY 안으로 clamp — 천천히 위/
  // 아래로 흘러가는 부드러운 보행 패턴이 된다.
  static const double _walkYJitter = 10.0;
  // 한 구간 이동 동안의 발걸음 톤 바운스. 메인 이동 위에 살짝 얹는 sin 떨림.
  static const double _walkBobHeight = 3.0;
  static const int _walkBobsPerStride = 2;
  // 한 walk 사이클(도착) 후 정지해서 캐릭터별 PNG + blink 를 보여주는 시간 범위.
  // 너무 길면 답답, 너무 짧으면 깜빡임을 못 보고 다시 출발 — 1~2초가 다마고치 톤.
  static const int _idleDurationMinMs = 1000;
  static const int _idleDurationMaxMs = 2000;
  // 진입 시 walk 모드(돌아다님)가 활성화될 확률. 1/3 — 평균 3번 들어오면 1번
  // 정도만 자유 보행이고 나머지는 기존처럼 가만히 + 간헐 깜빡임. 다마고치가
  // 매번 돌아다니면 산만하기 때문에 평소엔 가만히 있다가 가끔 신난 듯 걷는 톤.
  static const double _roamingProbability = 1 / 3;
  // 탭 직후, 외부에서 액션 사이클 진입(=enableWalk false 전환) 까지의 최대 대기 시간.
  // 서버 호출이 실패해 액션 자체가 안 들어와도 무한 정지 방지.
  static const Duration _tapPauseTimeout = Duration(seconds: 5);

  late final AnimationController _walkController;
  // true 면 좌측을 바라보고 있는 상태 — Transform 으로 X 축 반전한다.
  bool _facingLeft = false;
  // 현재 구간의 시작/도착 지점(raw double, .w/.h 미적용). 매 사이클 완료 시 _walkTo
  // 가 새 _walkFrom 으로 인계되고 _walkTo 는 다음 random target 으로 갱신된다.
  Offset _walkFrom = Offset.zero;
  Offset _walkTo = Offset.zero;
  // 사용자가 탭한 직후, 외부 액션 사이클 진입(=enableWalk false)·완료 신호를
  // 기다리는 동안 true. 타임아웃이 먼저 끝나면 안전망으로 false 복귀.
  bool _tapPaused = false;
  Timer? _tapPauseTimer;
  // 현재 사이클의 phase. walking 동안은 idle gif base + blink off, idling 동안은
  // 캐릭터별 PNG base + 간헐 blink. enableWalk=false 면 항상 idling 으로 고정.
  _WalkPhase _phase = _WalkPhase.idling;
  Timer? _idleTimer;
  // 자유 보행 모드 여부. initState 에서 첫 추첨, 그 후 화면이 hidden→visible
  // (다른 탭/화면에서 돌아오는 시점) 으로 전환될 때마다 [_rerollRoaming] 으로 재추첨.
  // 외부 enableWalk 의 false↔true (액션 사이클) 에는 영향받지 않는다.
  bool _roamingThisSession = false;
  // VisibilityDetector 의 첫 콜백은 mount 직후 1 frame 만에 호출되는데, initState
  // 에서 이미 한 번 추첨했으니 이 첫 콜백은 무시한다. 두 번째부터 진짜 화면 전환.
  bool _firstVisibilityCallback = true;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    // VisibilityDetector 의 기본 250ms 디바운스를 끄지 않으면 빠른 탭 전환 시
    // hidden 콜백이 누락되어, 다른 탭에 있는 동안에도 walkController 가 계속
    // tick → 돌아왔을 때 캐릭터가 "딴 데 가있는" 순간이동처럼 보인다.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    _roamingThisSession = _rng.nextDouble() < _roamingProbability;
    _walkController = AnimationController(vsync: this)
      ..addStatusListener(_onWalkStatus);
    if (widget.enableWalk && _roamingThisSession) {
      _phase = _WalkPhase.walking;
      _pickNextWalkTarget();
      _walkController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _WalkingSlot old) {
    super.didUpdateWidget(old);
    if (old.enableWalk == widget.enableWalk) return;
    if (widget.enableWalk) {
      // 액션 종료(또는 알→캐릭터 등). 탭/idle pause 해제 후 — roaming 세션이면 새
      // target 으로 walking 재개, 아니면 그대로 idling 유지.
      _cancelTapPauseTimer();
      _cancelIdleTimer();
      _tapPaused = false;
      if (_roamingThisSession) {
        _phase = _WalkPhase.walking;
        _pickNextWalkTarget();
        _walkController.forward(from: 0);
      } else {
        _phase = _WalkPhase.idling;
      }
    } else {
      // 액션/진화/알 등 진입. 호출측이 [snapToCenterOnDisable] 를 켰으면 (진화)
      // 가운데로 즉시 snap — 진화 연출이 walking 좌표에서 시작되어 어색하게
      // 보이는 걸 막는다. 액션 처럼 그 자리에서 반응해야 하는 케이스는 false 라
      // 기존처럼 snapshotCurrentPosition 으로 walking 위치를 고정.
      if (widget.snapToCenterOnDisable) {
        _walkFrom = Offset.zero;
        _walkTo = Offset.zero;
        _facingLeft = false;
      } else {
        _snapshotCurrentPosition();
      }
      _walkController.stop();
      _cancelIdleTimer();
      _phase = _WalkPhase.idling;
    }
  }

  @override
  void dispose() {
    _cancelTapPauseTimer();
    _cancelIdleTimer();
    _walkController.dispose();
    super.dispose();
  }

  void _cancelTapPauseTimer() {
    _tapPauseTimer?.cancel();
    _tapPauseTimer = null;
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _snapshotCurrentPosition() {
    final t = _walkController.value;
    final eased = Curves.easeInOut.transform(t);
    final x = _walkFrom.dx + (_walkTo.dx - _walkFrom.dx) * eased;
    final y = _walkFrom.dy + (_walkTo.dy - _walkFrom.dy) * eased;
    _walkFrom = Offset(x, y);
    _walkTo = _walkFrom;
  }

  void _pickNextWalkTarget() {
    _walkFrom = _walkTo;
    // X / Y 모두 이전 위치 기준 ±jitter 변동 후 각자의 범위로 clamp. 매 구간 완전
    // random 으로 뽑으면 위치가 휙휙 튀어 지그재그처럼 보이는 걸 방지 — 한 방향으로
    // 좀 흘러가다 끝에서 clamp 에 막혀 자연스럽게 반대로 turn 하는 보행 패턴.
    final xJitter = (_rng.nextDouble() * 2 - 1) * _walkXJitter;
    final dx = (_walkFrom.dx + xJitter).clamp(-_walkRangeX, _walkRangeX);
    final yJitter = (_rng.nextDouble() * 2 - 1) * _walkYJitter;
    final dy = (_walkFrom.dy + yJitter).clamp(-_walkRangeY, 0.0);
    _walkTo = Offset(dx, dy);
    _facingLeft = _walkTo.dx < _walkFrom.dx;
    final spanMs = _walkDurationMaxMs - _walkDurationMinMs;
    final ms = _walkDurationMinMs + _rng.nextInt(spanMs + 1);
    _walkController.duration = Duration(milliseconds: ms);
  }

  void _onWalkStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status != AnimationStatus.completed) return;
    _walkController.reset();
    // walking 종료. controller.value=0 으로 reset 되었으니 walkFrom 을 도착점으로
    // 박아두지 않으면 AnimatedBuilder 가 캐릭터를 출발점으로 점프시킨다.
    setState(() {
      _walkFrom = _walkTo;
      _phase = _WalkPhase.idling;
    });
    _startIdleTimer();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final nowVisible = info.visibleFraction > 0;
    if (_firstVisibilityCallback) {
      _firstVisibilityCallback = false;
      _isVisible = nowVisible;
      return;
    }
    final wasVisible = _isVisible;
    _isVisible = nowVisible;
    if (wasVisible && !nowVisible) {
      // hidden 진입 시점에 다음 세션을 미리 준비 — visible 콜백은 화면이 그려진
      // 뒤에 도착하기 때문에 그때 추첨하면 한 frame 동안 이전 상태가 보이는
      // 깜빡임이 생긴다. 화면이 안 보이는 동안 모두 셋업해두고, visible 진입 시
      // controller forward 만 호출.
      _prepareNextSession();
    } else if (!wasVisible && nowVisible) {
      _startPreparedSession();
    }
  }

  void _prepareNextSession() {
    _cancelTapPauseTimer();
    _cancelIdleTimer();
    _walkController.stop();
    _tapPaused = false;
    // 위치 reset — roaming↔가만히 전환 시 캐릭터가 카드 가운데에서 다시 시작.
    // hidden 중이라 점프가 보이지 않는다.
    _walkFrom = Offset.zero;
    _walkTo = Offset.zero;
    _facingLeft = false;
    final newRoaming = _rng.nextDouble() < _roamingProbability;
    setState(() {
      _roamingThisSession = newRoaming;
      if (widget.enableWalk && newRoaming) {
        _phase = _WalkPhase.walking;
        _pickNextWalkTarget();
      } else {
        _phase = _WalkPhase.idling;
      }
    });
  }

  void _startPreparedSession() {
    // _prepareNextSession 에서 이미 phase / walkTo / 위치 모두 셋업됨. 여기선 walking
    // 모드일 때만 controller 를 forward — visible 진입 직후 깜빡임 없이 부드럽게 시작.
    if (widget.enableWalk &&
        _roamingThisSession &&
        _phase == _WalkPhase.walking) {
      _walkController.forward(from: 0);
    }
  }

  void _startIdleTimer() {
    _cancelIdleTimer();
    final spanMs = _idleDurationMaxMs - _idleDurationMinMs;
    final ms = _idleDurationMinMs + _rng.nextInt(spanMs + 1);
    _idleTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted ||
          !widget.enableWalk ||
          !_roamingThisSession ||
          _tapPaused) {
        return;
      }
      setState(() {
        _phase = _WalkPhase.walking;
        _pickNextWalkTarget();
      });
      _walkController.forward();
    });
  }

  void _handleCharacterTap(Offset globalPosition) {
    final cb = widget.onCharacterTap;
    if (cb == null) return;
    if (!widget.enableWalk || !_roamingThisSession) {
      // walk 비활성(액션 중) 또는 가만히 모드 세션 — 그냥 콜백만. 가만히 모드는
      // 어차피 안 움직이니까 멈춤 처리도 필요 없다.
      cb(globalPosition);
      return;
    }
    // 현재 위치를 walkFrom 에 박고 controller 정지 + phase=idling → 그 자리에 캐릭터별
    // PNG 가 떠있다가, 외부 액션 사이클이 시작되면 액션 gif 가 같은 자리에서 swap.
    _snapshotCurrentPosition();
    _walkController.stop();
    _cancelIdleTimer();
    setState(() {
      _tapPaused = true;
      _phase = _WalkPhase.idling;
    });
    _cancelTapPauseTimer();
    _tapPauseTimer = Timer(_tapPauseTimeout, () {
      if (!mounted || !_tapPaused) return;
      _tapPaused = false;
      if (widget.enableWalk) {
        setState(() {
          _phase = _WalkPhase.walking;
          _pickNextWalkTarget();
        });
        _walkController.forward(from: 0);
      } else {
        setState(() {});
      }
    });
    cb(globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    final bubble = widget.bubble;
    final cb = widget.onCharacterTap;
    final characterChild = widget.characterBuilder(
      context,
      _phase == _WalkPhase.walking,
    );
    final tapWrapped = cb == null
        ? characterChild
        : GestureDetector(
            // onTapUp 으로 받아야 details.globalPosition 으로 손가락 위치를 잡는다.
            // floating "+N" 코인 위젯이 이 좌표에서 솟아오른다.
            onTapUp: (details) => _handleCharacterTap(details.globalPosition),
            behavior: HitTestBehavior.opaque,
            child: characterChild,
          );
    // X 반전은 캐릭터 본체에만 적용 — 말풍선까지 함께 뒤집으면 글자가 거울 모드로
    // 보인다. translate(이동) 는 Column 전체에 줘서 말풍선이 캐릭터를 따라가게.
    final flippedCharacter = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scaleByDouble(_facingLeft ? -1.0 : 1.0, 1.0, 1.0, 1.0),
      child: tapWrapped,
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?bubble,
        flippedCharacter,
      ],
    );

    // 위젯 트리 root 는 모드와 무관하게 항상 AnimatedBuilder 로 통일 — column 의
    // element 위치가 안 흔들려 _GrownCharacter 의 state(blink timer 등)가 재구성
    // 되지 않는다. builder 안에서 모드별로 transform 만 분기.
    // - roaming 활성: 좌우상하 보간 + sin bob 으로 transform
    // - _tapPaused: controller stop 이라 walkFrom 위치에 freeze
    // - 그 외(가만히 / 액션 / 알 등): transform 없이 child 그대로
    final content = AnimatedBuilder(
      animation: _walkController,
      builder: (_, child) {
        final isRoamingActive = widget.enableWalk && _roamingThisSession;
        if (!isRoamingActive && !_tapPaused) return child!;
        final t = _walkController.value;
        final eased = Curves.easeInOut.transform(t);
        final dx = (_walkFrom.dx + (_walkTo.dx - _walkFrom.dx) * eased).w;
        final dy = (_walkFrom.dy + (_walkTo.dy - _walkFrom.dy) * eased).h;
        final bob =
            -(sin(t * pi * 2 * _walkBobsPerStride)).abs() * _walkBobHeight.h;
        return Transform.translate(
          offset: Offset(dx, dy + bob),
          child: child,
        );
      },
      child: column,
    );

    // VisibilityDetector 로 다마고치 탭에 다시 진입할 때마다 roaming 모드를 재추첨.
    // indexedStack 의 비활성 탭은 paint 되지 않아 visibleFraction=0 → onVisibilityChanged
    // 에서 hidden 으로 인식되고, 활성으로 돌아오면 1.0 으로 올라온다.
    return VisibilityDetector(
      key: const Key('tamagochi-walking-slot'),
      onVisibilityChanged: _onVisibilityChanged,
      child: content,
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
