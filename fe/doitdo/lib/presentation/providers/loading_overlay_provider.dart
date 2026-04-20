import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 전역 로딩 오버레이 상태.
///
/// `DoitdoScaffold` 가 이 값을 구독해 true 일 때 화면 위에 반투명
/// CircularProgressIndicator 오버레이를 띄운다.
///
/// 사용: `ref.read(loadingOverlayProvider.notifier).state = true;`
final loadingOverlayProvider = StateProvider<bool>((ref) => false);