import 'dart:math';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// 알을 두드려 부화시키는 전용 전체 화면.
class CharacterHatchPage extends ConsumerStatefulWidget {
  const CharacterHatchPage({super.key});

  static const int requiredTaps = 10;
  static const List<String> eggAssets = [
    'assets/images/egg_1.png',
    'assets/images/egg_2.png',
    'assets/images/egg_3.png',
    'assets/images/egg_4.png',
    'assets/images/egg_5.png',
  ];

  @override
  ConsumerState<CharacterHatchPage> createState() => _CharacterHatchPageState();
}

class _CharacterHatchPageState extends ConsumerState<CharacterHatchPage>
    with TickerProviderStateMixin {
  static const Duration _eggPopDuration = Duration(milliseconds: 750);
  static const Duration _preRevealGlowDuration = Duration(milliseconds: 450);
  static const Duration _silhouetteDuration = Duration(milliseconds: 1100);
  static const Duration _faceHoldDuration = Duration(milliseconds: 1300);

  int _tapCount = 0;
  bool _hatching = false;
  bool _waitingForHatch = false;
  bool _birthTransitioning = false;
  bool _revealingCharacter = false;
  bool _showCharacterFace = false;

  String? _hatchedCharacterUrl;
  Future<bool>? _hatchFuture;

  late final AnimationController _bump;
  late final Animation<double> _shake;
  late final AnimationController _birthPulse;

  @override
  void initState() {
    super.initState();

    _bump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _shake = CurvedAnimation(parent: _bump, curve: Curves.easeOutCubic);

    _birthPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );

    // 페이지 진입 즉시 부화 API 선호출.
    // 사용자가 탭하는 동안 백그라운드에서 캐릭터를 미리 준비한다.
    _hatchFuture = _startHatch();
  }

  Future<bool> _startHatch() {
    return ref.read(characterViewModelProvider.notifier).hatchEgg();
  }

  @override
  void dispose() {
    _bump.dispose();
    _birthPulse.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_hatching) return;

    final previousStage = _eggStage;
    HapticFeedback.lightImpact();
    _bump.forward(from: 0).then((_) => _bump.reverse());

    final next = _tapCount + 1;
    if (next < CharacterHatchPage.requiredTaps) {
      setState(() => _tapCount = next);

      if (_eggStage != previousStage) {
        HapticFeedback.mediumImpact();
      }
      return;
    }

    setState(() {
      _tapCount = next;
      _hatching = true;
      _waitingForHatch = true;
      _birthTransitioning = false;
      _revealingCharacter = false;
      _showCharacterFace = false;
    });

    HapticFeedback.heavyImpact();

    // 마지막 알은 한 번만 뽀용.
    // repeat 금지: API가 느려도 계속 흔들리지 않게 함.
    _birthPulse.forward(from: 0);

    final ok = await Future.wait<dynamic>([
      _hatchFuture ?? _startHatch(),
      Future<void>.delayed(_eggPopDuration),
    ]).then((values) => values.first as bool);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _tapCount = 0;
        _hatching = false;
        _waitingForHatch = false;
        _birthTransitioning = false;
        _revealingCharacter = false;
        _showCharacterFace = false;
        _hatchedCharacterUrl = null;
      });

      _birthPulse.stop();
      _birthPulse.value = 0;

      // 실패 후 재시도 가능하도록 API future 갱신.
      _hatchFuture = _startHatch();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알을 깨우는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final character = ref.read(characterViewModelProvider).valueOrNull;
    final imageUrl = character?.thumbnailUrl ?? '';

    if (imageUrl.isNotEmpty) {
      await Future.any<void>([
        precacheImage(NetworkImage(imageUrl), context).catchError((_) {}),
        Future<void>.delayed(const Duration(milliseconds: 260)),
      ]);
      if (!mounted) return;
    }

    _birthPulse.stop();
    _birthPulse.value = 0;

    // 둥근 빛이 먼저 차오르고
    // 알 잠깐 더 보여주기
    await Future<void>.delayed(_preRevealGlowDuration);

    if (!mounted) return;

    // 실루엣 + glow 동시 등장
    setState(() {
      _waitingForHatch = false;
      _birthTransitioning = true;
      _revealingCharacter = true;
      _showCharacterFace = false;
      _hatchedCharacterUrl = imageUrl;
    });
    _birthPulse.forward(from: 0);

    await Future<void>.delayed(_preRevealGlowDuration);
    if (!mounted) return;

    // 실루엣 등장
    setState(() {
      _revealingCharacter = true;
      _showCharacterFace = false;
    });

    await Future<void>.delayed(_silhouetteDuration);
    if (!mounted) return;

    // 얼굴 공개
    HapticFeedback.lightImpact();
    _birthPulse.forward(from: 0);
    setState(() => _showCharacterFace = true);

    await Future<void>.delayed(_faceHoldDuration);
    if (!mounted) return;

    context.pushReplacement(AppRoutes.tamagochiNaming);
  }

  int get _eggStage {
    if (_tapCount >= CharacterHatchPage.requiredTaps) return 5;
    if (_tapCount >= 7) return 4;
    if (_tapCount >= 5) return 3;
    if (_tapCount >= 3) return 2;
    return 1;
  }

  String get _eggAsset => CharacterHatchPage.eggAssets[_eggStage - 1];

  static const Color _birthGlowColor = Color(0xFFFFECA8);
  static const Color _birthBackdropColor = Color(0xFFFFFBEE);

  Widget _buildAnimatedEggOrCharacter(Widget child) {
    if (_waitingForHatch) {
      final t = Curves.easeOutBack.transform(_birthPulse.value);
      final settle = sin(t * pi);

      return Transform.translate(
        offset: Offset(0, -settle * 4.h),
        child: Transform.scale(scale: 1.0 + settle * 0.045, child: child),
      );
    }

    final t = _revealingCharacter ? 0.0 : _shake.value;
    final wave = t == 0
        ? 0.0
        : (t * 6).round().isEven
        ? 1.0
        : -1.0;
    final dx = wave * 7.w * t;
    final angle = wave * 0.055 * t;
    final scale = 1.0 + t * 0.08;

    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = CharacterHatchPage.requiredTaps - _tapCount;
    final title = _hatching
        ? '곧 만나요'
        : remaining <= 0
        ? '짠!'
        : '$remaining번 더';

    return DoitdoScaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _birthTransitioning ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: const ColoredBox(color: _birthBackdropColor),
            ),
          ),
          GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: (_waitingForHatch || _birthTransitioning) ? 0 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 40.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  AnimatedBuilder(
                    animation: Listenable.merge([_shake, _birthPulse]),
                    builder: (context, child) {
                      final pulse = _birthTransitioning
                          ? Curves.easeOutCubic.transform(_birthPulse.value)
                          : 0.0;

                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          if (_birthTransitioning)
                            CustomPaint(
                              size: Size.square(360.sp),
                              painter: _BirthBubblePainter(
                                progress: _showCharacterFace ? 1 : pulse,
                                color: _birthGlowColor,
                                fillColor: Colors.white,
                                isReveal: _showCharacterFace,
                              ),
                            ),
                          _buildAnimatedEggOrCharacter(child!),
                        ],
                      );
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.96,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _revealingCharacter
                          ? _BornCharacterImage(
                              key: ValueKey(
                                'born-${_hatchedCharacterUrl ?? ''}-$_showCharacterFace',
                              ),
                              imageUrl: _hatchedCharacterUrl ?? '',
                              size: 170.sp,
                              fallbackColor: colors.textPrimary,
                              showFace: _showCharacterFace,
                            )
                          : _HatchEggImage(
                              key: ValueKey(_eggAsset),
                              assetPath: _eggAsset,
                              size: 180.sp,
                              fallbackColor: colors.textPrimary,
                            ),
                    ),
                  ),
                  SizedBox(height: 60.h),
                  AnimatedOpacity(
                    opacity: (_waitingForHatch || _birthTransitioning) ? 0 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.touch_app,
                      size: 40.sp,
                      color: colors.textHint,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AnimatedOpacity(
                    opacity: (_waitingForHatch || _birthTransitioning) ? 0 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      '화면을 톡톡 두드려 알을 깨워주세요',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HatchEggImage extends StatelessWidget {
  const _HatchEggImage({
    super.key,
    required this.assetPath,
    required this.size,
    required this.fallbackColor,
  });

  final String assetPath;
  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Icon(Icons.egg, size: size, color: fallbackColor);
}

class _BirthBubblePainter extends CustomPainter {
  const _BirthBubblePainter({
    required this.progress,
    required this.color,
    required this.fillColor,
    required this.isReveal,
  });

  final double progress;
  final Color color;
  final Color fillColor;
  final bool isReveal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));

    final mainRadius =
        size.shortestSide * (isReveal ? 0.33 : 0.24 + eased * 0.1);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: isReveal ? 0.46 : 0.26 + eased * 0.28)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        isReveal ? 34 : 18 + eased * 18,
      );

    final fillPaint = Paint()
      ..color = fillColor.withValues(
        alpha: isReveal ? 0.72 : 0.42 + eased * 0.24,
      );

    canvas.drawCircle(center, mainRadius * 1.18, glowPaint);
    canvas.drawCircle(center, mainRadius, fillPaint);

    final bubblePaint = Paint()
      ..color = color.withValues(alpha: isReveal ? 0.28 : 0.18 + eased * 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + eased * 8);

    const bubbleCount = 8;
    for (var i = 0; i < bubbleCount; i++) {
      final angle = -pi / 2 + i * pi * 2 / bubbleCount;
      final distance = mainRadius * (0.78 + eased * 0.52);
      final bubbleRadius = size.shortestSide * (0.025 + (i % 3) * 0.007);

      final offset = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );

      canvas.drawCircle(offset, bubbleRadius, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BirthBubblePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.isReveal != isReveal;
  }
}

class _BornCharacterImage extends StatelessWidget {
  const _BornCharacterImage({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.fallbackColor,
    required this.showFace,
  });

  final String imageUrl;
  final double size;
  final Color fallbackColor;
  final bool showFace;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _fallback();

    final image = Image.network(
      imageUrl,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _fallback(),
    );
    final heroTag = 'character-birth-$imageUrl';

    if (showFace) {
      return Hero(tag: heroTag, child: image);
    }

    return Hero(
      tag: heroTag,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        child: image,
      ),
    );
  }

  Widget _fallback() =>
      Icon(Icons.pets, size: size * 0.72, color: fallbackColor);
}
