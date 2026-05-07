package com.doitdo.domain.user.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.doitdo.domain.user.api.dto.req.RegisterAgreementsReq;
import com.doitdo.domain.user.api.dto.req.RegisterBirthDateReq;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.api.dto.resp.WalletBalanceResp;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * 온보딩 API (생년월일 등록, 약관 동의 등록) 통합 테스트.
 *
 * <p>실제 DB 상태를 검증하므로 @Transactional 을 걸지 않는다.
 */
@ActiveProfiles("test")
@SpringBootTest
class UserServiceImplOnboardingTest {

    @Autowired
    private UserServiceImpl userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserWalletRepository userWalletRepository;

    // ── 생년월일 등록 ──────────────────────────────────────────────────

    /**
     * 만 14세 이상 생년월일 등록 → birth_date 저장 확인.
     */
    @Test
    void registerBirthDate_age14OrOlder_saved() {
        User saved = userRepository.save(
                User.create(
                        "birthdate-adult-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "bd_adult_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        LocalDate birthDate = LocalDate.now().minusYears(14);
        UserInfoResp resp = userService.registerBirthDate(userId, new RegisterBirthDateReq(birthDate));

        assertThat(resp.birthDateRegistered()).isTrue();

        User reloaded = userRepository.findById(userId)
                .orElseThrow(() -> new AssertionError("user not found"));
        assertThat(reloaded.getBirthDate()).isEqualTo(birthDate);

        // 정리
        userRepository.deleteById(userId);
    }

    /**
     * 만 14세 미만 → U00_006, User hard delete 확인.
     */
    @Test
    void registerBirthDate_underAge14_throws_U00_006_and_userDeleted() {
        User saved = userRepository.save(
                User.create(
                        "birthdate-young-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "bd_young_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        LocalDate underageBirthDate = LocalDate.now().minusYears(14).plusDays(1);

        assertThatThrownBy(() ->
                userService.registerBirthDate(userId, new RegisterBirthDateReq(underageBirthDate))
        )
                .isInstanceOf(CustomException.class)
                .satisfies(ex -> {
                    CustomException ce = (CustomException) ex;
                    assertThat(ce.getErrorCode()).isEqualTo(UserErrorCode.U00_006);
                });

        // hard delete 확인 — user row 가 DB 에서 사라져야 한다
        assertThat(userRepository.findById(userId)).isEmpty();
    }

    // ── 약관 동의 등록 ──────────────────────────────────────────────────

    /**
     * 필수 동의 true, 마케팅 true → 4개 컬럼 저장, agreementsAccepted=true.
     */
    @Test
    void registerAgreements_allAgreed_success() {
        User saved = userRepository.save(
                User.create(
                        "agreements-all-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "ag_all_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        UserInfoResp resp = userService.registerAgreements(userId,
                new RegisterAgreementsReq(true, true, true));

        assertThat(resp.agreementsAccepted()).isTrue();

        User reloaded = userRepository.findById(userId)
                .orElseThrow(() -> new AssertionError("user not found"));
        assertThat(reloaded.getTermsAgreedAt()).isNotNull();
        assertThat(reloaded.getPrivacyAgreedAt()).isNotNull();
        assertThat(reloaded.getMarketingAgreedAt()).isNotNull();
        assertThat(reloaded.getTermsVersion()).isNotBlank();

        // 정리
        userRepository.deleteById(userId);
    }

    /**
     * 필수 동의 true, 마케팅 false → marketingAgreedAt = null.
     */
    @Test
    void registerAgreements_marketingFalse_marketingAgreedAtNull() {
        User saved = userRepository.save(
                User.create(
                        "agreements-nomarketing-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "ag_nm_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        userService.registerAgreements(userId, new RegisterAgreementsReq(true, true, false));

        User reloaded = userRepository.findById(userId)
                .orElseThrow(() -> new AssertionError("user not found"));
        assertThat(reloaded.getTermsAgreedAt()).isNotNull();
        assertThat(reloaded.getPrivacyAgreedAt()).isNotNull();
        assertThat(reloaded.getMarketingAgreedAt()).isNull();

        // 정리
        userRepository.deleteById(userId);
    }

    /**
     * termsAgreed=false → U00_007 예외.
     */
    @Test
    void registerAgreements_termsAgreedFalse_throws_U00_007() {
        User saved = userRepository.save(
                User.create(
                        "agreements-noterms-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "ag_nt_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        assertThatThrownBy(() ->
                userService.registerAgreements(userId, new RegisterAgreementsReq(false, true, false))
        )
                .isInstanceOf(CustomException.class)
                .satisfies(ex -> {
                    CustomException ce = (CustomException) ex;
                    assertThat(ce.getErrorCode()).isEqualTo(UserErrorCode.U00_007);
                });

        // 정리
        userRepository.deleteById(userId);
    }

    /**
     * privacyAgreed=false → U00_008 예외.
     */
    @Test
    void registerAgreements_privacyAgreedFalse_throws_U00_008() {
        User saved = userRepository.save(
                User.create(
                        "agreements-noprivacy-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "ag_np_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        assertThatThrownBy(() ->
                userService.registerAgreements(userId, new RegisterAgreementsReq(true, false, false))
        )
                .isInstanceOf(CustomException.class)
                .satisfies(ex -> {
                    CustomException ce = (CustomException) ex;
                    assertThat(ce.getErrorCode()).isEqualTo(UserErrorCode.U00_008);
                });

        // 정리
        userRepository.deleteById(userId);
    }

    @Test
    void getMyBalance_returnsWalletBalance() {
        User saved = userRepository.save(
                User.create(
                        "balance-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "balance_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();
        userWalletRepository.save(UserWallet.create(userId));

        WalletBalanceResp resp = userService.getMyBalance(userId);

        assertThat(resp.balance()).isEqualTo(100);

        userWalletRepository.findByUserId(userId).ifPresent(userWalletRepository::delete);
        userRepository.deleteById(userId);
    }

    @Test
    void getMyBalance_walletMissing_throws_U05_002() {
        User saved = userRepository.save(
                User.create(
                        "balance-missing-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "balance_missing_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        assertThatThrownBy(() -> userService.getMyBalance(userId))
                .isInstanceOf(CustomException.class)
                .satisfies(ex -> {
                    CustomException ce = (CustomException) ex;
                    assertThat(ce.getErrorCode()).isEqualTo(UserErrorCode.U05_002);
                });

        userRepository.deleteById(userId);
    }
}
