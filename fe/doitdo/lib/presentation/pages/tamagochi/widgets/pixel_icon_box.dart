import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 픽셀 아트 풍 정사각 아이콘 박스.
///
/// `assets/images/eg_icon_box.png` 의 노치 모서리 + 다크브라운 외곽선 +
/// 크림 내부 + 우하단 하드 픽셀 섀도 형태를 코드로 재현해, 임의의 자식
/// 위젯(보통 [Icon])을 감싸 픽셀 톤 진입 버튼처럼 보이게 한다.
///
/// 다마고치 홈 우상단의 상점 / 도감 진입 버튼이 첫 사용처.
class PixelIconBox extends StatelessWidget {
  const PixelIconBox({
    super.key,
    required this.child,
    this.onTap,
    this.size,
    this.fillColor = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFF2A1A0E),
    this.shadowColor = const Color(0xFF2A1A0E),
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 박스 한 변 길이(반응형). null 이면 40.w.
  final double? size;

  /// 내부 크림 면 색.
  final Color fillColor;

  /// 다크브라운 외곽선 색.
  final Color borderColor;

  /// 우하단 하드 픽셀 섀도 색.
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 40.w;
    const double shadowOffset = 3.0;

    final box = SizedBox(
      // 섀도가 박스 우하단으로 한 칸 떨어지므로 그만큼 슬롯을 확장.
      width: s + shadowOffset,
      height: s + shadowOffset,
      child: CustomPaint(
        painter: _PixelFramePainter(
          frameSize: s,
          shadowOffset: shadowOffset,
          fillColor: fillColor,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        child: Padding(
          // 우/하단은 섀도 만큼, 전 방향은 외곽선 두께만큼 안쪽으로 컨텐츠 밀어냄.
          padding: const EdgeInsets.fromLTRB(4, 4, 4 + shadowOffset, 4 + shadowOffset),
          child: Center(child: child),
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

/// 모서리를 2단 계단(stair-step) 으로 깎은 16각형을 두 번(섀도 + 본체)
/// 그린다. 사선 컷 대신 직각 스텝을 쌓아 픽셀 아트 결을 강조.
class _PixelFramePainter extends CustomPainter {
  const _PixelFramePainter({
    required this.frameSize,
    required this.shadowOffset,
    required this.fillColor,
    required this.borderColor,
    required this.shadowColor,
  });

  final double frameSize;
  final double shadowOffset;
  final Color fillColor;
  final Color borderColor;
  final Color shadowColor;

  /// 한 계단 픽셀의 변 길이. 2단을 쌓으므로 모서리에서 총 2*_step 만큼 깎임.
  static const double _step = 2.0;

  /// 외곽선(border) 두께.
  static const double _border = 2.0;

  /// 시계 방향으로 한 바퀴 돌며 각 모서리를 2단 계단으로 깎은 path.
  Path _framePath(double x, double y, double s) {
    const double k = _step;
    return Path()
      // 상단 (좌→우)
      ..moveTo(x + 2 * k, y)
      ..lineTo(x + s - 2 * k, y)
      // 우상단 계단
      ..lineTo(x + s - 2 * k, y + k)
      ..lineTo(x + s - k, y + k)
      ..lineTo(x + s - k, y + 2 * k)
      ..lineTo(x + s, y + 2 * k)
      // 우측 (상→하)
      ..lineTo(x + s, y + s - 2 * k)
      // 우하단 계단
      ..lineTo(x + s - k, y + s - 2 * k)
      ..lineTo(x + s - k, y + s - k)
      ..lineTo(x + s - 2 * k, y + s - k)
      ..lineTo(x + s - 2 * k, y + s)
      // 하단 (우→좌)
      ..lineTo(x + 2 * k, y + s)
      // 좌하단 계단
      ..lineTo(x + 2 * k, y + s - k)
      ..lineTo(x + k, y + s - k)
      ..lineTo(x + k, y + s - 2 * k)
      ..lineTo(x, y + s - 2 * k)
      // 좌측 (하→상)
      ..lineTo(x, y + 2 * k)
      // 좌상단 계단
      ..lineTo(x + k, y + 2 * k)
      ..lineTo(x + k, y + k)
      ..lineTo(x + 2 * k, y + k)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // 1) 우하단 하드 섀도 (블러 없이 한 칸 떨어진 동일 노치 8각형).
    canvas.drawPath(
      _framePath(shadowOffset, shadowOffset, frameSize),
      Paint()..color = shadowColor,
    );

    // 2) 외곽선 면(다크브라운) — 그 위에 한 픽셀 안쪽으로 크림 면을 덮어
    //    "프레임 + 채움" 두 단으로 보이게 한다.
    canvas.drawPath(
      _framePath(0, 0, frameSize),
      Paint()..color = borderColor,
    );
    canvas.drawPath(
      _framePath(_border, _border, frameSize - _border * 2),
      Paint()..color = fillColor,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelFramePainter old) =>
      old.frameSize != frameSize ||
      old.shadowOffset != shadowOffset ||
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.shadowColor != shadowColor;
}