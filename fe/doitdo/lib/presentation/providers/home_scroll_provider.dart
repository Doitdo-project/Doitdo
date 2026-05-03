import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeScrollControllerProvider = StateProvider<ScrollController?>((ref) => null);

/// 캘린더 탭을 이미 보고 있는 상태에서 재탭할 때 증가.
/// TodoPage 가 이 값 변화를 감지해 오늘 날짜로 이동한다.
final calendarTodayTriggerProvider = StateProvider<int>((ref) => 0);
