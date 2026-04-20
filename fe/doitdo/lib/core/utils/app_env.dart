import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('환경변수 $key 가 설정되지 않았습니다.');
    }
    return value;
  }

  static String optional(String key, {String fallback = ''}) {
    return dotenv.maybeGet(key) ?? fallback;
  }
}
