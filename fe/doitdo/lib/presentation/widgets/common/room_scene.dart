import 'package:cached_network_image/cached_network_image.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/widgets/common/room_furniture_slots.dart';
import 'package:flutter/material.dart';

class RoomSceneItem {
  const RoomSceneItem({required this.category, required this.imageUrl});

  final ShopCategory category;
  final String imageUrl;
}

typedef RoomSceneOverlayBuilder =
    List<Widget> Function(double canvasWidth, double canvasHeight);

/// Home and shop room renderer. The room background and furniture share the
/// same fixed-aspect canvas, so crop and slot coordinates stay aligned across
/// devices.
class RoomScene extends StatelessWidget {
  const RoomScene({
    super.key,
    this.backgroundUrl,
    this.items = const <RoomSceneItem>[],
    this.topSafePadding = 0,
    this.extendBackgroundBehindSafeArea = false,
    this.overlayBuilder,
  });

  final String? backgroundUrl;
  final List<RoomSceneItem> items;
  final double topSafePadding;
  final bool extendBackgroundBehindSafeArea;
  final RoomSceneOverlayBuilder? overlayBuilder;

  static const Alignment backgroundAlignment = Alignment(0, -0.5);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundUrl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentHeight = (constraints.maxHeight - topSafePadding).clamp(
          0.0,
          double.infinity,
        );
        final canvas = computeRoomCanvasLayout(
          parentWidth: constraints.maxWidth,
          parentHeight: contentHeight,
          aspect: kRoomCanvasAspect,
        );

        return Stack(
          children: [
            if (extendBackgroundBehindSafeArea && bg != null && bg.isNotEmpty)
              Positioned.fill(child: _RoomNetworkImage.cover(url: bg)),
            Positioned(
              left: canvas.offsetX,
              top: topSafePadding + canvas.offsetY,
              width: canvas.width,
              height: canvas.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (bg != null && bg.isNotEmpty)
                    Positioned.fill(child: _RoomNetworkImage.fill(url: bg)),
                  for (final item in items)
                    _RoomSceneFurniture(
                      item: item,
                      canvasWidth: canvas.width,
                      canvasHeight: canvas.height,
                    ),
                  ...?overlayBuilder?.call(canvas.width, canvas.height),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoomSceneFurniture extends StatelessWidget {
  const _RoomSceneFurniture({
    required this.item,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  final RoomSceneItem item;
  final double canvasWidth;
  final double canvasHeight;

  @override
  Widget build(BuildContext context) {
    final slot =
        kRoomFurnitureSlots[item.category] ?? kRoomFurnitureFallbackSlot;
    return Positioned(
      left: slot.left == null ? null : slot.left! * canvasWidth,
      right: slot.right == null ? null : slot.right! * canvasWidth,
      top: slot.top == null ? null : slot.top! * canvasHeight,
      bottom: slot.bottom == null ? null : slot.bottom! * canvasHeight,
      width: slot.width * canvasWidth,
      height: slot.height * canvasHeight,
      child: CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        memCacheWidth: 480,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _RoomNetworkImage extends StatelessWidget {
  const _RoomNetworkImage.cover({required this.url}) : fit = BoxFit.cover;

  const _RoomNetworkImage.fill({required this.url}) : fit = BoxFit.fill;

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: RoomScene.backgroundAlignment,
      memCacheWidth: 1000,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
