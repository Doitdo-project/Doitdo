import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';

/// 말풍선/헤더에서 사용하는 캐릭터 이미지 조각.
///
/// 데이터 로드는 화면 진입 흐름에서만 담당하고, 이 위젯은 현재 캐시된 캐릭터 이미지만
/// 표시한다. 공용 이미지 위젯에서 네트워크 load를 트리거하면 초기 진입 후 순차 중복
/// 호출이 생길 수 있다.
class CharacterMascotImage extends ConsumerWidget {
  const CharacterMascotImage({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url =
        ref.watch(characterViewModelProvider).valueOrNull?.thumbnailUrl ?? '';

    if (url.isEmpty) return SizedBox(width: size, height: size);

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
    );
  }
}
