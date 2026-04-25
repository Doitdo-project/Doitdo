import 'package:flutter/widgets.dart';

/// 스크롤 정지 지점을 `0` 과 [snapOffset] 두 곳으로 제한하는 physics.
///
/// 다마고치 홈처럼 "헤더가 전부 보이는 상태" 와 "헤더가 완전히 사라진 상태"
/// 사이의 애매한 중간 위치에서 스크롤이 멈추는 것을 방지한다.
///
/// 동작:
/// - `pixels ∈ (0, snapOffset)` 구간에서 손을 떼면 가까운 쪽(또는 속도 방향)
///   으로 스프링 애니메이션.
/// - `pixels ≤ 0` (상단 오버스크롤) / `pixels ≥ snapOffset` (스냅 구간 이후)
///   에서는 부모 physics 에 그대로 위임해 일반적인 스크롤/리스트 감성을 유지.
class SnapScrollPhysics extends ScrollPhysics {
  const SnapScrollPhysics({required this.snapOffset, super.parent});

  /// 헤더(캐릭터 + 스트릭)의 전체 높이. 이만큼 스크롤되면 헤더가 뷰포트 밖.
  final double snapOffset;

  /// 이 속도 이상이면 위치 중점 대신 **속도 방향**으로 스냅 방향을 결정한다.
  /// "살짝 떨림" 정도는 무시하고, 의도적인 플릭은 반대편까지 밀어주기 위함.
  static const double _flingVelocityThreshold = 200;

  @override
  SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnapScrollPhysics(
      snapOffset: snapOffset,
      parent: buildParent(ancestor),
    );
  }

  /// 상단 오버스크롤(= pixels <= 0 지점에서 더 아래로 당기는 제스처) 을 막는다.
  /// 헤더가 이미 전부 보이는 상태에서 추가로 pull-down 되면 위에 생기는 빈 공간이
  /// grass 배경 위로 노출되면서 시각적 결함이 되기 때문. 하단 오버스크롤(bounce) 은
  /// 그대로 두어 리스트 스크롤감은 유지.
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final pixels = position.pixels;

    // 스냅 구간 바깥(상단 오버스크롤 or 헤더 완전히 사라진 이후)은
    // 기본 물리에 위임한다. → 아래쪽 할 일 리스트는 자유 스크롤.
    if (pixels <= 0 || pixels >= snapOffset) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double target;
    if (velocity.abs() >= _flingVelocityThreshold) {
      target = velocity > 0 ? snapOffset : 0.0;
    } else {
      target = pixels > snapOffset / 2 ? snapOffset : 0.0;
    }

    final tolerance = toleranceFor(position);
    if ((target - pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}