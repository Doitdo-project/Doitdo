import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeScrollControllerProvider = StateProvider<ScrollController?>((ref) => null);

/// 캘린더 탭을 이미 보고 있는 상태에서 재탭할 때 증가.
/// TodoPage 가 이 값 변화를 감지해 오늘 날짜로 이동한다.
final calendarTodayTriggerProvider = StateProvider<int>((ref) => 0);

/// 타마고치 탭에 진입(전환·재탭 모두)할 때 증가.
/// TamagochiPage 가 이 값 변화를 감지해 스트릭을 silent refresh 한다.
final tamagochiEnterTriggerProvider = StateProvider<int>((ref) => 0);
