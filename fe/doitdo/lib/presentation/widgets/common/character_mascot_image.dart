import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';

/// 말풍선 헤더에 사용하는 캐릭터 이미지 위젯.
///
/// URL 로드 전: 같은 크기의 빈 공간(투명) 표시 — 한라봉이 잠깐 보였다 바뀌는
/// 어색함을 없애기 위함.
/// URL 로드 후: 내 캐릭터 이미지 표시.
/// 로드 실패: 빈 공간 유지 (폴백 이미지 없음).
class CharacterMascotImage extends ConsumerStatefulWidget {
  const CharacterMascotImage({super.key, this.size = 30});

  final double size;

  @override
  ConsumerState<CharacterMascotImage> createState() =>
      _CharacterMascotImageState();
}

class _CharacterMascotImageState extends ConsumerState<CharacterMascotImage> {
  @override
  void initState() {
    super.initState();
    // 홈을 거치지 않고 직접 진입한 경우 아직 로드 안 된 상태.
    // addPostFrameCallback 으로 build 후 한 번만 load() 트리거.
    final characterAsync = ref.read(characterViewModelProvider);
    if (!characterAsync.hasValue && !characterAsync.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(characterViewModelProvider.notifier).load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = ref
        .watch(characterViewModelProvider)
        .valueOrNull
        ?.thumbnailUrl ??
        '';

    // URL 없으면 같은 크기의 빈 공간 — 이미지가 갑자기 교체되는 어색함 방지.
    if (url.isEmpty) return SizedBox(width: widget.size, height: widget.size);

    return Image.network(
      url,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) =>
          SizedBox(width: widget.size, height: widget.size),
    );
  }
}