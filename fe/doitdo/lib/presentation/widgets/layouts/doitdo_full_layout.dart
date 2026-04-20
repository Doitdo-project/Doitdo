import 'package:flutter/material.dart';

/// 메인 홈의 다마고치 캐릭터, 지도처럼 화면 끝까지 써야 하는 본문 래퍼.
///
/// 기본적으로는 자식을 그대로 통과시키지만, "이 화면은 의도적으로
/// 풀블리드다" 라는 선언적 의미를 주고, 필요시 공통 배경(그라디언트
/// 등)을 한 곳에서 붙일 수 있는 훅 역할을 한다.
class DoitdoFullLayout extends StatelessWidget {
  const DoitdoFullLayout({
    super.key,
    required this.child,
    this.background,
  });

  final Widget child;

  /// 선택적 배경 위젯. 주어지면 child 뒤에 깔린다.
  /// 캐릭터 배경 이미지 등을 붙일 때 사용.
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    if (background == null) return SizedBox.expand(child: child);
    return Stack(
      fit: StackFit.expand,
      children: [background!, child],
    );
  }
}