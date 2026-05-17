import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/presentation/providers/font_family_provider.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/navigation/post_auth_destination.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/pages/onboarding/onboarding_view_model.dart';

/// 첫 로그인 시 노출되는 온보딩 2단계 — 약관 동의.
///
/// 디자인 원칙(토스 / 카카오뱅크 / 당근 등 한국 최신 앱 표준):
///   - 큰 타이틀 + 친근한 한 줄 카피
///   - "약관에 모두 동의" 마스터 카드 — 큰 라운드 체크
///   - 가로선 구분 + 항목별 컴팩트 row
///     · [필수] / [선택] 라벨을 prefix 로 살짝 강조 컬러
///     · 우측에 "보기" 텍스트로 본문 시트 진입 (chevron 만 두면 시각적으로 약함)
///   - 필수 항목이 모두 체크되어야 CTA 활성
class OnboardingAgreementsPage extends ConsumerWidget {
  const OnboardingAgreementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppTheme.light(fontFamily: ref.watch(fontFamilyProvider).family),
      child: Consumer(builder: (context, ref, _) => _buildBody(context, ref)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    final form = ref.watch(agreementsFormControllerProvider);
    final formCtrl = ref.read(agreementsFormControllerProvider.notifier);
    final submitState = ref.watch(onboardingAgreementsViewModelProvider);

    ref.listen<AsyncValue<User?>>(onboardingAgreementsViewModelProvider,
        (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          HapticFeedback.lightImpact();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final dest = resolvePostAuthDestination(ref, user);
            context.go(
              '${AppRoutes.tutorial}?next=${Uri.encodeComponent(dest)}',
            );
          });
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapErrorMessage(error))),
          );
        },
      );
    });

    final isLoading = submitState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 0),
              child: const _OnboardingProgress(step: 2, total: 2),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32.h),
                    Text(
                      '거의 다 왔어요!\n약관에 동의해주세요',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 26.sp,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '서비스 이용을 위해 아래 약관에 동의가 필요해요.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // ── 마스터: 약관에 모두 동의 ──
                    _MasterAgreeCard(
                      checked: form.allChecked,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        formCtrl.setAll(!form.allChecked);
                      },
                    ),

                    SizedBox(height: 14.h),

                    // ── 개별 약관 ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFEFE7D6)),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Column(
                        children: [
                          _AgreementRow(
                            checked: form.termsAgreed,
                            label: '두잇뚜 서비스 이용약관',
                            required: true,
                            onTap: () =>
                                formCtrl.setTerms(!form.termsAgreed),
                            onView: () => _showLegalSheet(
                              context,
                              title: '두잇뚜 서비스 이용약관',
                              body: _kTermsBody,
                            ),
                          ),
                          _AgreementRow(
                            checked: form.privacyAgreed,
                            label: '개인정보 수집 및 이용 동의',
                            required: true,
                            onTap: () =>
                                formCtrl.setPrivacy(!form.privacyAgreed),
                            onView: () => _showLegalSheet(
                              context,
                              title: '개인정보 수집 및 이용 동의',
                              body: _kPrivacyBody,
                            ),
                          ),
                          _AgreementRow(
                            checked: form.marketingAgreed,
                            label: '광고성 정보 수신 동의 (이메일·앱 푸시)',
                            required: false,
                            onTap: () =>
                                formCtrl.setMarketing(!form.marketingAgreed),
                            onView: () => _showLegalSheet(
                              context,
                              title: '광고성 정보 수신 동의',
                              body: _kMarketingBody,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // 한국 앱 표준 — 마케팅 동의 안내 문구.
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        '광고성 정보 수신 동의는 선택 사항이며, 동의하지 않아도\n서비스를 이용할 수 있어요. 동의 후에도 [설정] 에서\n언제든 변경할 수 있어요.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textHint,
                          fontSize: 12.sp,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── CTA ──
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
              child: DoitdoPrimaryButton(
                label: isLoading ? '저장 중…' : '동의하고 시작하기',
                onPressed: (form.canSubmit && !isLoading)
                    ? () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(onboardingAgreementsViewModelProvider
                                .notifier)
                            .submit(
                              termsAgreed: form.termsAgreed,
                              privacyAgreed: form.privacyAgreed,
                              marketingAgreed: form.marketingAgreed,
                            );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLegalSheet(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // 시트가 시스템 인셋(홈 인디케이터/내비게이션 바)을 덮고 화면 끝까지 채우게 한다.
      // 기본값(false) 이지만 명시 — 다른 곳에서 default 가 바뀌어도 안전.
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // 시스템 하단 인셋(홈 인디케이터/내비게이션 바) 높이.
        // 스크롤 콘텐츠 padding 에 이만큼만 더해서 마지막 줄이 인디케이터에 가리지 않게.
        // 시트 컨테이너 자체는 화면 끝까지 흰색으로 채워 "회색 빈 영역" 이 안 보이게 한다.
        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // grabber
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0D8C5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 12.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      // 하단 padding 은 시스템 인셋 + 작은 breathing room 만.
                      // 기존 32.h 고정값 → 디바이스마다 과한 여백이 보이던 문제 해결.
                      padding: EdgeInsets.fromLTRB(
                        20.w,
                        16.h,
                        20.w,
                        bottomInset + 12.h,
                      ),
                      child: Text(
                        body,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13.sp,
                          height: 1.65,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Internal widgets

/// "약관에 모두 동의" 마스터 카드 — 한국 약관 동의 화면의 시그니처.
class _MasterAgreeCard extends StatelessWidget {
  const _MasterAgreeCard({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Ink(
          decoration: BoxDecoration(
            color: checked
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: checked
                  ? colors.primary
                  : const Color(0xFFEFE7D6),
              width: checked ? 1.4 : 1,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 22.w),
          child: Row(
            children: [
              _RoundCheck(checked: checked, size: 26.w, emphasized: true),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '약관에 모두 동의',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontSize: 16.sp,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '필수 및 선택 항목에 모두 동의해요',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12.sp,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.checked,
    required this.label,
    required this.required,
    required this.onTap,
    required this.onView,
  });

  final bool checked;
  final String label;
  final bool required;
  final VoidCallback onTap;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        child: Row(
          children: [
            _RoundCheck(checked: checked, size: 22.w),
            SizedBox(width: 12.w),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    color: colors.textPrimary,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: required ? '(필수) ' : '(선택) ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        color: required
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                    ),
                    TextSpan(text: label),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // "보기" 텍스트 + chevron — 한국 앱 약관 라인의 표준 패턴.
            // 텍스트만 두면 너무 약하고, chevron 만 두면 정보가 부족함. 두 개 다 둔다.
            InkWell(
              onTap: onView,
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '보기',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 12.sp,
                        color: colors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18.sp,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 원형 체크 — 활성 시 brand orange 채움 + 흰 체크.
class _RoundCheck extends StatelessWidget {
  const _RoundCheck({
    required this.checked,
    required this.size,
    this.emphasized = false,
  });

  final bool checked;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? colors.primary : Colors.transparent,
        border: Border.all(
          color: checked
              ? colors.primary
              : (emphasized
                  ? const Color(0xFFCBC2A8)
                  : const Color(0xFFD9D2C0)),
          width: 1.6,
        ),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: size * 0.7, color: Colors.white)
          : null,
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: List.generate(total, (i) {
        final isActive = i < step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4.h,
              decoration: BoxDecoration(
                color: isActive ? colors.primary : const Color(0xFFE7DFCC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 약관 본문 (한국 IT 서비스 표준 형식 — 임시본).
//
// 출시 직전 법무 검토본으로 교체. 카피 톤은 "~합니다" 체로 통일 (한국 약관 관행).

const String _kTermsBody = '''제1조 (목적)
본 약관은 두잇뚜(이하 "회사"라 합니다)가 제공하는 서비스의 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임 사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
1. "서비스"란 회사가 모바일 애플리케이션, 웹사이트 등을 통해 제공하는 할 일(TODO) 관리, 캐릭터 성장 등 일체의 기능을 의미합니다.
2. "회원"이란 본 약관에 동의하고 회사가 제공하는 서비스를 이용하는 자를 의미합니다.
3. "콘텐츠"란 회원이 서비스 내에서 작성·등록한 정보(할 일, 메모, 캐릭터 이름 등)를 의미합니다.

제3조 (약관의 게시와 개정)
1. 회사는 본 약관의 내용을 회원이 쉽게 알 수 있도록 서비스 화면에 게시합니다.
2. 회사는 관련 법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있으며, 개정 시에는 적용일자 7일 전부터 공지합니다. 회원에게 불리한 개정의 경우 30일 전부터 공지합니다.

제4조 (회원가입)
1. 회원가입은 이용자가 본 약관과 개인정보 수집·이용에 동의한 후 회사가 정한 절차에 따라 가입을 완료함으로써 이루어집니다.
2. 만 14세 미만의 아동은 회원가입을 할 수 없습니다.

제5조 (서비스의 제공 및 변경)
회사는 다음과 같은 서비스를 제공합니다.
1. 할 일 관리 및 알림 기능
2. 캐릭터 성장 및 도감 기능
3. 기타 회사가 정하는 서비스

(이하 생략 — 정식 출시 전 법무 검토본으로 교체 예정)''';

const String _kPrivacyBody = '''두잇뚜(이하 "회사")는 회원의 개인정보를 소중히 다루며, 「개인정보 보호법」 등 관련 법령을 준수하기 위해 노력합니다.

1. 수집하는 개인정보의 항목
- 필수 항목: 이메일, 닉네임, 비밀번호(암호화 저장), 생년월일
- 선택 항목: 마케팅 정보 수신 동의 여부, 디바이스 토큰(푸시 알림용)
- 자동 수집: 접속 IP, 쿠키, 서비스 이용 기록, 기기 정보(OS, 모델명)

2. 개인정보의 수집 및 이용 목적
- 회원 식별 및 본인 확인
- 서비스 제공 및 회원 관리
- 캐릭터 성장·할 일 관리 등 핵심 기능 제공
- 서비스 개선 및 신규 기능 개발
- 부정 이용 방지 및 분쟁 조정

3. 개인정보의 보유 및 이용 기간
회원 탈퇴 시 즉시 파기합니다. 단, 관련 법령에 따라 일정 기간 보관해야 하는 정보는 해당 기간 동안 보관 후 파기합니다.
- 계약 또는 청약철회 등에 관한 기록: 5년 (전자상거래법)
- 부정 이용 등 부당한 서비스 이용 기록: 1년

4. 개인정보의 제3자 제공
회사는 회원의 동의 없이 개인정보를 외부에 제공하지 않습니다. 다만 법령에 의거하거나 수사기관의 요청이 있는 경우는 예외로 합니다.

(이하 생략 — 정식 출시 전 법무 검토본으로 교체 예정)''';

const String _kMarketingBody = '''두잇뚜는 회원에게 더 나은 경험을 제공하기 위해 다음과 같은 광고성 정보를 발송할 수 있습니다.

▶ 발송 채널
- 앱 푸시 알림
- 이메일

▶ 발송 내용
- 새로운 캐릭터·아이템·테마 안내
- 이벤트 및 프로모션 소식
- 신규 기능 업데이트 안내
- 회원 맞춤형 콘텐츠 추천

▶ 안내사항
- 본 동의는 선택 사항이며, 동의하지 않아도 서비스 이용에 제한이 없습니다.
- 동의 후에도 언제든 [설정] > [알림] 에서 수신을 중단할 수 있습니다.
- 야간(오후 9시 ~ 오전 8시) 광고성 정보 수신 동의는 별도로 받지 않으며, 해당 시간에는 푸시를 발송하지 않습니다.''';
