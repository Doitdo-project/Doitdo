import 'package:flutter/material.dart';

/// 입력 폼·설정창처럼 좌우 여백이 필요한 화면의 본문 래퍼.
///
/// - 기본 좌우 24px, 상/하는 0 (필요시 파라미터로 조정)
/// - `DoitdoScaffold.body` 안에 넣어 사용.
class DoitdoPaddingLayout extends StatelessWidget {
  const DoitdoPaddingLayout({
    super.key,
    required this.child,
    this.horizontal = 24,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double horizontal;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
      child: child,
    );
  }
}