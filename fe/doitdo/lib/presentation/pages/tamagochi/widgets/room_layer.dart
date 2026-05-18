import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';
import 'package:doitdo/presentation/widgets/common/room_furniture_slots.dart';

/// 다마고치 홈 캐릭터 카드의 방 배경 + 가구 합성 레이어.
///
/// `GET /api/users/me/room` 응답에서:
/// - `BACKGROUND` 카테고리는 카드를 꽉 채우는 베이스(`BoxFit.cover`).
/// - 그 외 가구는 서버가 내려준 `(x, y, width, height)` 를 무시하고
///   [kRoomFurnitureSlots] (상점 미리보기와 공유) 의 비율 슬롯에 배치한다.
///   슬롯 비율은 **카드 전체가 아니라 [kRoomCanvasAspect] 로 잠긴 가구 캔버스** 기준
///   — 디바이스 / 상태바 인셋이 달라져 카드 AR 이 변해도 가구 간 배치는 동일.
///   캔버스는 하단 anchor 라 캐릭터 발 위치(카드 하단)와 가구 바닥선이 정렬된다.
///
/// 똥/청소(brush) 레이어도 같은 가구 캔버스 Stack 의 **마지막 자리** 에 그려
/// 모든 가구(rug 포함) 위에 z-stack 되도록 보장한다 — 캐릭터/말풍선은 더
/// 바깥 Stack 에 있으므로 똥은 가구 위, 캐릭터는 똥 위가 된다.
class RoomLayer extends ConsumerWidget {
  const RoomLayer({
    super.key,
    this.showPoop = false,
    this.showBrush = false,
    this.onPoopTap,
    this.poopLeftRatio,
    this.poopBottomRatio,
  });

  /// CharacterCard 가 캐릭터 bottom 정렬에 사용하는 값.
  static const double characterBottomInset = 70;

  /// 똥 크기 (캔버스 비율). 호출측이 brush 와 시각 중심을 맞추는 데도 사용한다.
  static const double poopSizeRatio = 0.10;

  /// brush 크기. 똥보다 살짝 작게 — 똥 위에 살짝 좁게 덮이는 인상.
  static const double brushSizeRatio = 0.19;

  /// 가구/EXP 바를 피하면서도 floor 톤이 살도록 한 안전 (left, bottom) 범위.
  /// page 가 random 으로 뽑은 값이 이 범위 안에 있도록 한다.
  ///   left   ∈ [0.58, 0.62]   (캐릭터 idle 본체 x ~ [0.40, 0.60] 의 오른쪽,
  ///                            plant 슬롯 좌측(0.82) 보다 똥 폭(0.20) 만큼 왼쪽)
  ///   bottom ∈ [0.22, 0.30]   (EXP 바 위 ~ 카펫 중간 — 똥이 바닥에 떨어진 인상)
  /// 카펫과는 y 가 일부 겹치지만 z-order 가 poop > 가구 라 시각적으로 항상 위에
  /// 떠 있다. 캐릭터가 우측으로 walking 할 때만 잠깐 같은 자리를 지나가며,
  /// idle (중앙 정지) 상태에선 명확히 분리돼 보인다.
  static const double safePoopLeftMin = 0.58;
  static const double safePoopLeftMax = 0.62;
  static const double safePoopBottomMin = 0.22;
  static const double safePoopBottomMax = 0.30;

  static const double _defaultPoopLeftRatio = 0.60;
  static const double _defaultPoopBottomRatio = 0.26;

  /// true 면 가구 위에 `poop.png` 노출. brush 와 동시에 true 면 둘 다 그려진다
  /// (z 순서: poop → brush). brush 만 true 면 빗자루만 보임 (청소 phase 2).
  final bool showPoop;

  /// true 면 같은 슬롯 위에 `brush.gif` 가 그려져 청소 중 피드백이 된다.
  final bool showBrush;

  /// 똥 탭 콜백. 인자는 사용자가 탭한 글로벌 좌표(손가락 위치) — page 가 응답의
  /// earnedAmount > 0 일 때 그 좌표에서 floating "+N" 코인 위젯을 띄우는 데 쓴다.
  /// brush 진행 중에는 자동으로 비활성.
  final ValueChanged<Offset>? onPoopTap;

  /// 똥의 left 위치 (캔버스 비율). null 이면 default 위치 사용. brush 도 이 값을
  /// 기준으로 시각 중심을 맞춘다.
  final double? poopLeftRatio;

  /// 똥의 bottom 위치 (캔버스 비율). null 이면 default.
  final double? poopBottomRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRoom = ref.watch(myRoomProvider);
    final items = asyncRoom.valueOrNull ?? const <RoomFurniturePlacement>[];
    final hasItems = items.isNotEmpty;

    final background = hasItems
        ? items
            .where((it) =>
                it.category.toUpperCase() == 'BACKGROUND' &&
                it.imageUrl.isNotEmpty)
            .firstOrNull
        : null;
    final furniture = hasItems
        ? items
            .where((it) =>
                it.category.toUpperCase() != 'BACKGROUND' &&
                it.imageUrl.isNotEmpty)
            .toList(growable: false)
        : const <RoomFurniturePlacement>[];

    // 가구도 배경도 없고 똥/brush 도 없으면 빈 박스로 끝낸다 — 종전 동작 유지.
    if (background == null &&
        furniture.isEmpty &&
        !showPoop &&
        !showBrush) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = computeRoomCanvasLayout(
          parentWidth: constraints.maxWidth,
          parentHeight: constraints.maxHeight,
          aspect: kRoomCanvasAspect,
        );
        return Stack(
          children: [
            if (background != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: background.imageUrl,
                  fit: BoxFit.cover,
                  // cover 가 박스 비율과 안 맞는 쪽을 잘라낼 때, 이미지 윗부분이
                  // 더 보이도록 anchor 를 위로 이동 (-1 = top, 0 = center).
                  alignment: const Alignment(0, -0.5),
                  // 배경은 카드 풀폭 (≈ 화면폭 375 _w_ × 3x DPI = 1125px) 까지 가능.
                  // 너무 크면 메모리 부담이라 1000 정도로 캡.
                  memCacheWidth: 1000,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, _) => const SizedBox.shrink(),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            // 가구 캔버스 — 고정 AR 로 잠가 디바이스 무관하게 동일 구도 유지.
            Positioned(
              left: canvas.offsetX,
              top: canvas.offsetY,
              width: canvas.width,
              height: canvas.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final item in furniture)
                    _buildItem(item, canvas.width, canvas.height),
                  // 똥/brush 는 가구 Stack 의 마지막 자리 — 모든 가구(rug 포함)
                  // 위에 그려진다. brush 가 우선 (청소 중에는 똥 대신 빗자루만).
                  // 똥은 page 가 random 으로 뽑은 안전 위치([poopLeftRatio]/
                  // [poopBottomRatio])에 배치. 가구·EXP 바·캐릭터 idle 자리를
                  // 회피하도록 [safePoopLeftMin]~[safePoopLeftMax] 등의 범위가
                  // 정의돼 있다. brush 는 똥 시각 중심을 공유하도록 살짝 보정한다.
                  // 청소 흐름: poop 그대로 → brush 가 위에 덮임 → poop 사라짐 → brush 도 끝.
                  if (showPoop || showBrush) ...(() {
                    final poopLeft = poopLeftRatio ?? _defaultPoopLeftRatio;
                    final poopBottom =
                        poopBottomRatio ?? _defaultPoopBottomRatio;
                    // brush.gif 는 빗자루 머리가 이미지 하단에 있어, poop 과 시각
                    // 중심을 그냥 맞추면 빗자루 머리가 똥 아래 바닥을 쓰는 인상이
                    // 된다. y 를 한쪽으로 더 끌어올려 빗자루 머리가 똥에 닿게 한다.
                    //
                    // 커스텀하려면 [brushLiftY] 값을 조정 — 똥 높이의 비율로 계산:
                    //   0.00  = brush 가 똥 같은 자리 (바닥 쓸기 인상)
                    //   0.30  = brush 머리가 똥 하단 ~30% 위로 (현재)
                    //   0.50  = brush 바닥이 똥 중앙 (정중앙 sweep)
                    //   1.00  = brush 바닥이 똥 꼭대기 (위에 떠있는 인상)
                    final brushOffsetX = (poopSizeRatio - brushSizeRatio) / 2;
                    final brushLiftY = poopSizeRatio * 0.05;
                    final brushLeft = poopLeft + brushOffsetX;
                    final brushBottom = poopBottom + brushLiftY;
                    return [
                      if (showPoop)
                        _buildPoopSlot(
                          asset: 'assets/images/poop.png',
                          canvasWidth: canvas.width,
                          canvasHeight: canvas.height,
                          leftRatio: poopLeft,
                          bottomRatio: poopBottom,
                          sizeRatio: poopSizeRatio,
                          onTap: showBrush ? null : onPoopTap,
                        ),
                      if (showBrush)
                        _buildPoopSlot(
                          asset: 'assets/animations/brush.gif',
                          canvasWidth: canvas.width,
                          canvasHeight: canvas.height,
                          leftRatio: brushLeft,
                          bottomRatio: brushBottom,
                          sizeRatio: brushSizeRatio,
                          onTap: null,
                        ),
                    ];
                  })(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(RoomFurniturePlacement item, double w, double h) {
    final cat = ShopCategory.fromServer(item.category);
    final slot = kRoomFurnitureSlots[cat] ?? kRoomFurnitureFallbackSlot;
    return Positioned(
      left: slot.left == null ? null : slot.left! * w,
      right: slot.right == null ? null : slot.right! * w,
      top: slot.top == null ? null : slot.top! * h,
      bottom: slot.bottom == null ? null : slot.bottom! * h,
      width: slot.width * w,
      height: slot.height * h,
      child: CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        // 가장 큰 슬롯(bed) 도 캔버스 폭 30% ≈ 113.w. 3x DPI 환산 ≈ 340px.
        // 여유 잡아 480 캡 — 거의 모든 가구가 디스플레이 픽셀 수보다 크지 않다.
        memCacheWidth: 480,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPoopSlot({
    required String asset,
    required double canvasWidth,
    required double canvasHeight,
    required double leftRatio,
    required double bottomRatio,
    required double sizeRatio,
    required ValueChanged<Offset>? onTap,
  }) {
    return Positioned(
      left: leftRatio * canvasWidth,
      bottom: bottomRatio * canvasHeight + 10,
      width: sizeRatio * canvasWidth,
      height: sizeRatio * canvasHeight,
      child: GestureDetector(
        // onTapUp 으로 받아 details.globalPosition 을 호출자에게 전달 — page 가
        // 응답의 earnedAmount > 0 일 때 그 좌표에서 floating "+N" 을 띄운다.
        onTapUp: onTap == null ? null : (d) => onTap(d.globalPosition),
        behavior: HitTestBehavior.opaque,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
