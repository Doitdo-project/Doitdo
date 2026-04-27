// import 'dart:io' show Platform;
//
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'
//     show SignInWithAppleButton, SignInWithAppleButtonStyle;
//
// import 'package:doitdo/core/errors/exceptions.dart';
// import 'package:doitdo/core/theme/app_text_styles.dart';
// import 'package:doitdo/core/theme/doitdo_colors.dart';
// import 'package:doitdo/core/utils/error_message_mapper.dart';
// import 'package:doitdo/presentation/navigation/app_router.dart';
// import 'package:doitdo/presentation/pages/auth/welcome_view_model.dart';
//
// /// 앱 진입 후 최초로 보이는 로그인 선택 화면.
// ///
// /// 크림 배경 + DOITDO 워드마크 + 캐릭터(생각 풍선 3개) + 소셜 로그인 4종.
// class WelcomePage extends ConsumerWidget {
//   const WelcomePage({super.key});
//
//   static const _bgColor = Color(0xFFF8F5EC);
//   static const _bubbleBg = Color(0xFFEFE8DC);
//   static const _bubbleAccent = Color(0xFFE2782B);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // AsyncNotifier 상태 변화 감지 — 성공 시 페이지 이동, 에러 시 스낵바.
//     // AuthCanceledException 은 "사용자가 직접 취소" 이므로 메시지 노출 생략.
//     ref.listen<AsyncValue<WelcomeSuccess?>>(welcomeViewModelProvider,
//             (prev, next) {
//           next.whenOrNull(
//             data: (success) {
//               if (success == null) return;
//               if (!context.mounted) return;
//               // 캐릭터 수령/프리로드는 홈(tamagochi_page) initState 의 ensureCharacter()
//               // 한 곳에서만 돌린다. 여기서 unawaited 로 또 띄우면 home 의 load 와 레이스가
//               // 나서 "GET 실패 → POST" 판정이 덮어써질 수 있음.
//               context.go(AppRoutes.tamagochi);
//             },
//             error: (error, _) {
//               if (error is AuthCanceledException) return;
//               if (!context.mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(mapErrorMessage(error))),
//               );
//             },
//           );
//         });
//
//     return Scaffold(
//       backgroundColor: _bgColor,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: Padding(
//                   padding: EdgeInsets.fromLTRB(28.w, 36.h, 24.w, 24.h),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const _Header(),
//                       SizedBox(height: 48.h),
//                       const _CharacterWithBubbles(),
//                       SizedBox(height: 16.h),
//                       _SocialButtons(ref: ref),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
// class _Header extends StatelessWidget {
//   const _Header();
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     return Column(
//       children: [
//         Image.asset(
//           'assets/images/doitdo__login_3.png',
//           height: 36.h,
//           fit: BoxFit.contain,
//         ),
//         SizedBox(height: 8.h),
//         Text(
//           '캐릭터와 함께하는 투두 리스트',
//           style: AppTextStyles.bodyMedium.copyWith(
//             color: colors.textSecondary,
//             fontSize: 13.sp,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// /// 캐릭터(중앙 하단) + 머리 위로 떠 있는 todo 풍선 3개.
// ///
// /// 풍선들은 캐릭터를 덮지 않도록 상단 영역에 배치하고, 캐릭터는 Stack 의 bottom 에 고정.
// class _CharacterWithBubbles extends StatelessWidget {
//   const _CharacterWithBubbles();
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 300.h,
//       child: Stack(
//         clipBehavior: Clip.none,
//         alignment: Alignment.bottomCenter,
//         children: [
//           Positioned(
//             bottom: 0,
//             child: Image.asset(
//               'assets/images/doitdo__login_1.png',
//               height: 160.h,
//               fit: BoxFit.contain,
//               filterQuality: FilterQuality.none, // 픽셀아트 보존
//             ),
//           ),
//           Positioned(
//             top: 0,
//             left: 0,
//             child: const _TodoBubble(text: '일찍 일어나기'),
//           ),
//           Positioned(
//             top: 52.h,
//             right: 0,
//             child: const _TodoBubble(text: '영단어 50개 외우기', isDone: true),
//           ),
//           Positioned(
//             top: 104.h,
//             left: 28.w,
//             child: const _TodoBubble(text: '일기 쓰기'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// todo 풍선 1칸. [isDone] 이면 주황 점 + 취소선.
// class _TodoBubble extends StatelessWidget {
//   const _TodoBubble({required this.text, this.isDone = false});
//
//   final String text;
//   final bool isDone;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
//       decoration: BoxDecoration(
//         color: WelcomePage._bubbleBg,
//         borderRadius: BorderRadius.circular(24.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // todo 의 체크/원 마커. 완료면 채움, 미완료면 외곽선만.
//           Container(
//             width: 10.w,
//             height: 10.w,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: isDone ? WelcomePage._bubbleAccent : Colors.transparent,
//               border: Border.all(color: WelcomePage._bubbleAccent, width: 1.5),
//             ),
//           ),
//           SizedBox(width: 8.w),
//           Text(
//             text,
//             style: AppTextStyles.bodySmall.copyWith(
//               color: const Color(0xFF5B5247),
//               fontSize: 12.sp,
//               decoration: isDone ? TextDecoration.lineThrough : null,
//               decorationColor: const Color(0xFF8C8174),
//               decorationThickness: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _SocialButtons extends StatelessWidget {
//   const _SocialButtons({required this.ref});
//   final WidgetRef ref;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // ── Apple Sign In (iOS 전용) ──
//         // App Store 심사 규정 4.8: Google/Kakao 같은 3rd-party 소셜 로그인을
//         // 제공하는 앱은 Apple Sign In 도 반드시 제공해야 한다. 카카오 공식 버튼
//         // 이미지(라운드 12) 와 통일감을 주기 위해 패키지 기본 외형을 그대로 사용.
//         if (!kIsWeb && Platform.isIOS) ...[
//           SignInWithAppleButton(
//             onPressed: () =>
//                 ref.read(welcomeViewModelProvider.notifier).signInWithApple(),
//             style: SignInWithAppleButtonStyle.black,
//             text: 'Apple로 로그인',
//             height: 48,
//             borderRadius: BorderRadius.circular(12.r),
//           ),
//           SizedBox(height: 10.h),
//         ],
//         // 카카오 — 공식 와이드 버튼 이미지(에셋) 사용.
//         // Ink.image 로 이미지를 Material 의 ink surface 로 등록해야 InkWell 의 탭
//         // 리플이 이미지 위에 그려져서 "버튼 눌리는 느낌" 이 난다.
//         SizedBox(
//           height: 48.h,
//           child: Material(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.circular(12.r),
//             clipBehavior: Clip.antiAlias,
//             child: Ink.image(
//               image: const AssetImage(
//                 'assets/images/kakao_login_medium_wide.png',
//               ),
//               fit: BoxFit.fill,
//               child: InkWell(
//                 onTap: () => ref
//                     .read(welcomeViewModelProvider.notifier)
//                     .signInWithKakao(),
//                 splashColor: Colors.black.withOpacity(0.12),
//                 highlightColor: Colors.black.withOpacity(0.06),
//                 child: const SizedBox.expand(),
//               ),
//             ),
//           ),
//         ),
//         SizedBox(height: 10.h),
//         // Google — 정식 G 로고 + Roboto 폰트(브랜드 가이드라인).
//         _SocialButton(
//           icon: Image.asset(
//             'assets/images/google.png',
//             width: 20.w,
//             height: 20.w,
//             fit: BoxFit.contain,
//             filterQuality: FilterQuality.high,
//           ),
//           label: 'Google 로그인',
//           labelStyle: TextStyle(
//             fontFamily: 'Roboto',
//             fontSize: 15.sp,
//             fontWeight: FontWeight.w700,
//             color: const Color(0xDD000000),
//             letterSpacing: 0.25,
//           ),
//           backgroundColor: Colors.white,
//           borderColor: const Color(0xFFE0DAD0),
//           onPressed: () =>
//               ref.read(welcomeViewModelProvider.notifier).signInWithGoogle(),
//         ),
//         SizedBox(height: 10.h),
//         // 이메일 — 따뜻한 베이지.
//         _SocialButton(
//           icon: const Icon(
//             Icons.mail_outline,
//             size: 20,
//             color: Color(0xFF3A352D),
//           ),
//           label: '이메일로 계속하기',
//           labelStyle: AppTextStyles.bodyMedium.copyWith(
//             color: const Color(0xFF3A352D),
//             fontSize: 15.sp,
//             fontWeight: FontWeight.w600,
//           ),
//           backgroundColor: const Color(0xFFE5E0D6),
//           onPressed: () => context.push(AppRoutes.login),
//         ),
//       ],
//     );
//   }
// }
//
// /// 좌측 아이콘 + 가운데 라벨 형태의 통일된 소셜 버튼 (radius 12).
// ///
// /// 카카오 공식 와이드 이미지와 같은 라운딩·높이로 맞춰 4개 버튼이 한 그룹처럼 보이게 한다.
// class _SocialButton extends StatelessWidget {
//   const _SocialButton({
//     required this.icon,
//     required this.label,
//     required this.onPressed,
//     required this.backgroundColor,
//     this.labelStyle,
//     this.borderColor,
//   });
//
//   final Widget icon;
//   final String label;
//   final VoidCallback onPressed;
//   final Color backgroundColor;
//   final TextStyle? labelStyle;
//   final Color? borderColor;
//
//   @override
//   Widget build(BuildContext context) {
//     final effectiveLabelStyle = labelStyle ??
//         AppTextStyles.bodyMedium.copyWith(
//           color: const Color(0xDD000000),
//           fontSize: 15.sp,
//           fontWeight: FontWeight.w600,
//         );
//
//     return SizedBox(
//       height: 48.h,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: backgroundColor,
//           foregroundColor: const Color(0xDD000000),
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12.r),
//             side: borderColor != null
//                 ? BorderSide(color: borderColor!, width: 1)
//                 : BorderSide.none,
//           ),
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//         ),
//         child: Row(
//           children: [
//             SizedBox(width: 24.w, child: Center(child: icon)),
//             SizedBox(width: 8.w),
//             Expanded(
//               child: Text(
//                 label,
//                 textAlign: TextAlign.center,
//                 style: effectiveLabelStyle,
//               ),
//             ),
//             SizedBox(width: 24.w),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Apple 로그인 흐름은 Google/Kakao 와 마찬가지로 [WelcomeViewModel.signInWithApple]
// // → [AuthRepositoryImpl.signInWithApple] 에서 통합 관리한다 (SDK 호출 + 서버 교환 + 토큰 저장).
// // 성공/실패 부수효과는 본 파일 상단의 ref.listen 블록이 일괄 처리.


import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    show SignInWithAppleButton, SignInWithAppleButtonStyle;

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/welcome_view_model.dart';

/// 앱 진입 후 최초로 보이는 로그인 선택 화면.
///
/// 크림 배경 + DOITDO 워드마크 + 캐릭터(생각 풍선 3개) + 소셜 로그인 4종.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  static const _bgColor = Color(0xFFF8F5EC);
  static const _bubbleBg = Color(0xFFEFE8DC);
  static const _bubbleAccent = Color(0xFFE2782B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncNotifier 상태 변화 감지 — 성공 시 페이지 이동, 에러 시 스낵바.
    // AuthCanceledException 은 "사용자가 직접 취소" 이므로 메시지 노출 생략.
    ref.listen<AsyncValue<WelcomeSuccess?>>(welcomeViewModelProvider,
            (prev, next) {
          next.whenOrNull(
            data: (success) {
              if (success == null) return;
              if (!context.mounted) return;
              // 캐릭터 수령/프리로드는 홈(tamagochi_page) initState 의 ensureCharacter()
              // 한 곳에서만 돌린다. 여기서 unawaited 로 또 띄우면 home 의 load 와 레이스가
              // 나서 "GET 실패 → POST" 판정이 덮어써질 수 있음.
              context.go(AppRoutes.tamagochi);
            },
            error: (error, _) {
              if (error is AuthCanceledException) return;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(mapErrorMessage(error))),
              );
            },
          );
        });

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28.w, 36.h, 24.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      SizedBox(height: 48.h),
                      const _CharacterWithBubbles(),
                      SizedBox(height: 16.h),
                      _SocialButtons(ref: ref),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Image.asset(
          'assets/images/doitdo__login_3.png',
          height: 36.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 8.h),
        Text(
          '캐릭터와 함께하는 투두 리스트',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}

/// 캐릭터(중앙 하단) + 머리 위로 떠 있는 todo 풍선 3개.
///
/// 풍선들은 캐릭터를 덮지 않도록 상단 영역에 배치하고, 캐릭터는 Stack 의 bottom 에 고정.
class _CharacterWithBubbles extends StatelessWidget {
  const _CharacterWithBubbles();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/doitdo__login_1.png',
              height: 160.h,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none, // 픽셀아트 보존
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: const _TodoBubble(text: '일찍 일어나기'),
          ),
          Positioned(
            top: 52.h,
            right: 0,
            child: const _TodoBubble(text: '영단어 50개 외우기', isDone: true),
          ),
          Positioned(
            top: 104.h,
            left: 28.w,
            child: const _TodoBubble(text: '일기 쓰기'),
          ),
        ],
      ),
    );
  }
}

/// todo 풍선 1칸. [isDone] 이면 주황 점 + 취소선.
class _TodoBubble extends StatelessWidget {
  const _TodoBubble({required this.text, this.isDone = false});

  final String text;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: WelcomePage._bubbleBg,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // todo 의 체크/원 마커. 완료면 채움, 미완료면 외곽선만.
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? WelcomePage._bubbleAccent : Colors.transparent,
              border: Border.all(color: WelcomePage._bubbleAccent, width: 1.5),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF5B5247),
              fontSize: 12.sp,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor: const Color(0xFF8C8174),
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Apple Sign In (iOS 전용) ──
        // App Store 심사 규정 4.8: Google/Kakao 같은 3rd-party 소셜 로그인을
        // 제공하는 앱은 Apple Sign In 도 반드시 제공해야 한다. 카카오 공식 버튼
        // 이미지(라운드 12) 와 통일감을 주기 위해 패키지 기본 외형을 그대로 사용.
        if (!kIsWeb && Platform.isIOS) ...[
          SignInWithAppleButton(
            onPressed: () =>
                ref.read(welcomeViewModelProvider.notifier).signInWithApple(),
            style: SignInWithAppleButtonStyle.black,
            text: 'Apple로 로그인',
            height: 48,
            borderRadius: BorderRadius.circular(12.r),
          ),
          SizedBox(height: 10.h),
        ],
        // 카카오 — 공식 와이드 버튼 이미지(에셋) 사용.
        // Ink.image 로 이미지를 Material 의 ink surface 로 등록해야 InkWell 의 탭
        // 리플이 이미지 위에 그려져서 "버튼 눌리는 느낌" 이 난다.
        SizedBox(
          height: 48.h,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            clipBehavior: Clip.antiAlias,
            child: Ink.image(
              image: const AssetImage(
                'assets/images/kakao_login_medium_wide.png',
              ),
              fit: BoxFit.fill,
              child: InkWell(
                onTap: () => ref
                    .read(welcomeViewModelProvider.notifier)
                    .signInWithKakao(),
                splashColor: Colors.black.withOpacity(0.12),
                highlightColor: Colors.black.withOpacity(0.06),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // Google — 이미지 에셋 사용 (카카오와 동일한 방식).
        SizedBox(
          height: 48.h,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            clipBehavior: Clip.antiAlias,
            child: Ink.image(
              image: const AssetImage('assets/images/google_login.png'),
              fit: BoxFit.fill,
              child: InkWell(
                onTap: () => ref
                    .read(welcomeViewModelProvider.notifier)
                    .signInWithGoogle(),
                splashColor: Colors.black.withOpacity(0.12),
                highlightColor: Colors.black.withOpacity(0.06),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // 이메일 — 이미지 에셋 사용 (카카오와 동일한 방식).
        SizedBox(
          height: 48.h,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            clipBehavior: Clip.antiAlias,
            child: Ink.image(
              image: const AssetImage('assets/images/email_login.png'),
              fit: BoxFit.fill,
              child: InkWell(
                onTap: () => context.push(AppRoutes.login),
                splashColor: Colors.black.withOpacity(0.12),
                highlightColor: Colors.black.withOpacity(0.06),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 좌측 아이콘 + 가운데 라벨 형태의 통일된 소셜 버튼 (radius 12).
///
/// 카카오 공식 와이드 이미지와 같은 라운딩·높이로 맞춰 4개 버튼이 한 그룹처럼 보이게 한다.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    this.labelStyle,
    this.borderColor,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final TextStyle? labelStyle;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveLabelStyle = labelStyle ??
        AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xDD000000),
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        );

    return SizedBox(
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: const Color(0xDD000000),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1)
                : BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Row(
          children: [
            SizedBox(width: 24.w, child: Center(child: icon)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: effectiveLabelStyle,
              ),
            ),
            SizedBox(width: 24.w),
          ],
        ),
      ),
    );
  }
}

// Apple 로그인 흐름은 Google/Kakao 와 마찬가지로 [WelcomeViewModel.signInWithApple]
// → [AuthRepositoryImpl.signInWithApple] 에서 통합 관리한다 (SDK 호출 + 서버 교환 + 토큰 저장).
// 성공/실패 부수효과는 본 파일 상단의 ref.listen 블록이 일괄 처리.