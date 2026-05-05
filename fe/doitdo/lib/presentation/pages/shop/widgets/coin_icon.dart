import 'package:flutter/material.dart';

/// 상점 화면에서 재화(코인)를 표시할 때 쓰는 픽셀 도트 코인 아이콘.
/// `dduredit.png` 한 장을 가져와 호출 측이 정한 크기로만 그려준다.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, required this.size});

  static const String assetPath = 'assets/images/dduredit.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );
  }
}
