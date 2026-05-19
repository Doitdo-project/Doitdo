import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';
import 'package:doitdo/presentation/widgets/common/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tamagochi home room layer.
///
/// Background and furniture are rendered through [RoomScene], the same renderer
/// used by the shop preview. Home passes [topSafePadding] so only the decorative
/// background extends behind the status bar; the actual room canvas remains the
/// same fixed aspect as the shop preview.
class RoomLayer extends ConsumerWidget {
  const RoomLayer({
    super.key,
    this.showPoop = false,
    this.showBrush = false,
    this.onPoopTap,
    this.poopLeftRatio,
    this.poopBottomRatio,
    this.topSafePadding = 0,
  });

  static const double characterBottomInset = 70;
  static const double poopSizeRatio = 0.10;
  static const double brushSizeRatio = 0.19;

  static const double safePoopLeftMin = 0.58;
  static const double safePoopLeftMax = 0.62;
  static const double safePoopBottomMin = 0.22;
  static const double safePoopBottomMax = 0.30;

  static const double _defaultPoopLeftRatio = 0.60;
  static const double _defaultPoopBottomRatio = 0.26;

  final bool showPoop;
  final bool showBrush;
  final ValueChanged<Offset>? onPoopTap;
  final double? poopLeftRatio;
  final double? poopBottomRatio;
  final double topSafePadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRoom = ref.watch(myRoomProvider);
    final items = asyncRoom.valueOrNull ?? const <RoomFurniturePlacement>[];
    final hasItems = items.isNotEmpty;

    final background = hasItems
        ? items
              .where(
                (it) =>
                    it.category.toUpperCase() == 'BACKGROUND' &&
                    it.imageUrl.isNotEmpty,
              )
              .firstOrNull
        : null;
    final furniture = hasItems
        ? items
              .where(
                (it) =>
                    it.category.toUpperCase() != 'BACKGROUND' &&
                    it.imageUrl.isNotEmpty,
              )
              .toList(growable: false)
        : const <RoomFurniturePlacement>[];

    if (background == null && furniture.isEmpty && !showPoop && !showBrush) {
      return const SizedBox.shrink();
    }

    return RoomScene(
      backgroundUrl: background?.imageUrl,
      items: [
        for (final item in furniture)
          RoomSceneItem(
            category: ShopCategory.fromServer(item.category),
            imageUrl: item.imageUrl,
          ),
      ],
      topSafePadding: topSafePadding,
      extendBackgroundBehindSafeArea: true,
      overlayBuilder: _buildOverlays,
    );
  }

  List<Widget> _buildOverlays(double canvasWidth, double canvasHeight) {
    if (!showPoop && !showBrush) return const <Widget>[];

    final poopLeft = poopLeftRatio ?? _defaultPoopLeftRatio;
    final poopBottom = poopBottomRatio ?? _defaultPoopBottomRatio;
    final brushOffsetX = (poopSizeRatio - brushSizeRatio) / 2;
    final brushLiftY = poopSizeRatio * 0.05;

    return [
      if (showPoop)
        _buildPoopSlot(
          asset: 'assets/images/poop.png',
          canvasWidth: canvasWidth,
          canvasHeight: canvasHeight,
          leftRatio: poopLeft,
          bottomRatio: poopBottom,
          sizeRatio: poopSizeRatio,
          onTap: showBrush ? null : onPoopTap,
        ),
      if (showBrush)
        _buildPoopSlot(
          asset: 'assets/animations/brush.gif',
          canvasWidth: canvasWidth,
          canvasHeight: canvasHeight,
          leftRatio: poopLeft + brushOffsetX,
          bottomRatio: poopBottom + brushLiftY,
          sizeRatio: brushSizeRatio,
          onTap: null,
        ),
    ];
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
