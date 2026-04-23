import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/welcome_view_model.dart';

/// 앱 진입 후 최초로 보이는 로그인 선택 화면.
///
/// background.jpg (캐릭터 이미지)를 전체 배경으로 사용한다.
/// 캐릭터가 위쪽에 배치돼 있으므로 텍스트와 버튼은 하단 영역에 위치한다.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    // AsyncNotifier 상태 변화 감지 — 성공 시 페이지 이동, 에러 시 스낵바.
    // AuthCanceledException 은 "사용자가 직접 취소" 이므로 메시지 노출 생략.
    ref.listen<AsyncValue<WelcomeSuccess?>>(welcomeViewModelProvider,
        (prev, next) {
      next.whenOrNull(
        data: (success) {
          if (success == null) return;
          if (!context.mounted) return;
          // TODO: success.isNewUser == true 면 추후 온보딩 라우트로 분기 가능.
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.45),
                          Text(
                            '두잇두에 오신걸 환영해요 :)',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: colors.textPrimary,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TODO로 나만의 캐릭터를 성장시켜보세요',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // ── Apple Sign In (iOS 전용) ──
                          // App Store 심사 규정 4.8: Google/Kakao 같은 3rd-party 소셜 로그인을
                          // 제공하는 앱은 Apple Sign In 도 반드시 제공해야 하며,
                          // Apple 의 디자인 가이드상 다른 소셜 로그인 버튼과 동등하거나
                          // 더 눈에 띄는 위치(보통 가장 위)에 배치해야 한다.
                          //
                          // Android 에서는 Platform.isIOS 가 false 라 렌더링되지 않는다.
                          if (!kIsWeb && Platform.isIOS) ...[
                            SignInWithAppleButton(
                              onPressed: () => _handleAppleSignIn(context),
                              style: SignInWithAppleButtonStyle.black,
                              text: 'Apple로 로그인',
                              height: 48,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(height: 10),
                          ],
                          // Google Sign-In 브랜딩 가이드:
                          // - 문구 "Google로 로그인" 고정
                          // - Roboto Medium / 시스템 sans-serif 사용 (GmarketSans 금지)
                          // - 제공된 G 로고 에셋 사용, 변형 금지
                          _SocialButton(
                            icon: Image.asset(
                              'assets/images/google.png',
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            label: 'Google 로그인',
                            labelStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xDD000000),
                              letterSpacing: 0.25,
                            ),
                            onPressed: () => ref
                                .read(welcomeViewModelProvider.notifier)
                                .signInWithGoogle(),
                          ),
                          const SizedBox(height: 10),
                          // Kakao 로그인 — 공식 버튼 이미지(kakao_login_medium_wide.png) 사용.
                          // Ink.image 로 이미지를 Material 의 ink surface 로 등록해야
                          // InkWell 의 탭 리플이 이미지 위에 그려져서 "버튼 눌리는 느낌" 이 난다.
                          SizedBox(
                            height: 48,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 10),
                          _SocialButton(
                            icon: Icon(
                              Icons.email_outlined,
                              color: colors.textSecondary,
                              size: 20,
                            ),
                            label: '이메일로 계속하기',
                            // Google 로그인 버튼과 동일한 스타일 (Roboto / 16 / w700) 로 통일.
                            labelStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xDD000000),
                              letterSpacing: 0.25,
                            ),
                            onPressed: () => context.push(AppRoutes.login),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple Sign In OAuth 플로우를 시작한다.
///
/// iOS 네이티브 로그인 시트를 띄우고, 성공 시 `AuthorizationCredentialAppleID` 를 받는다.
/// 실제 유저 세션 발급은 [credential.identityToken] 을 **서버로 전달 → Apple 공개키로 검증**
/// 하는 방식으로 처리한다 (백엔드 구현 후 연결).
///
/// 최초 로그인 시에만 `fullName`, `email` 이 반환되므로 이 값들은 받자마자 DB 에 저장해야 한다.
/// 두 번째 이후 로그인에서는 Apple 이 이름/이메일을 주지 않는다.
Future<void> _handleAppleSignIn(BuildContext context) async {
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // TODO: credential.identityToken, credential.authorizationCode 를 서버에 전송하여
    //       Apple 로그인 검증 → 유저 세션 발급 → 로컬 저장까지 처리.
    //       현재는 임시로 바로 메인 탭으로 이동.
    debugPrint('[AppleSignIn] user=${credential.userIdentifier}');
    debugPrint('[AppleSignIn] email=${credential.email}');
    debugPrint('[AppleSignIn] name=${credential.givenName} ${credential.familyName}');

    if (!context.mounted) return;
    context.go(AppRoutes.tamagochi);
  } on SignInWithAppleAuthorizationException catch (e) {
    // 사용자가 시트를 취소했거나 로그인 실패.
    // canceled 외의 에러는 스낵바로 알려줄 수 있음.
    if (e.code == AuthorizationErrorCode.canceled) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Apple 로그인 실패: ${e.message}')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Apple 로그인 중 오류: $e')),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.labelStyle,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  /// null 이면 앱 기본 스타일(GmarketSansMedium)을 사용.
  /// Google/Kakao 처럼 브랜드 가이드에 따라 폰트를 지정해야 하는 경우 외부에서 주입.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveLabelStyle = labelStyle ??
        AppTextStyles.bodyMedium.copyWith(color: Colors.black87);

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: icon)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: effectiveLabelStyle,
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

