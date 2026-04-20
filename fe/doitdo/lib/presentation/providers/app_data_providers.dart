import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/core/network/api_client.dart';

// 중앙 집중식 DI 선언 파일 (MOA 컨벤션)
// datasource → repository → service 순서로 Provider 추가.

final dioProvider = Provider<Dio>((ref) => ApiClient.create());

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('main.dart 에서 override 로 주입되어야 합니다.');
});
