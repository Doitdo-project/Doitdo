package com.doitdo.domain.user.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.doitdo.domain.user.api.dto.req.WithdrawReq;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

/**
 * UserServiceImpl.withdraw() regression 테스트.
 *
 * <p>@Transactional(clearAutomatically = true) 를 사용하는 bulk op 이후
 * user 엔티티가 detached 되어 withdraw() 변경이 flush 되지 않는 버그를 잡기 위한 테스트.
 *
 * <p>테스트 메서드에 @Transactional 을 걸지 않는다.
 * 이유: 테스트가 서비스 TX 에 참가하면 L1 캐시를 공유하여 SELECT 없이 캐시에서 읽어
 * 버그를 탐지하지 못한다. 커밋 후 신규 조회로 실제 DB 상태를 확인한다.
 */
@ActiveProfiles("test")
@SpringBootTest
class UserServiceImplWithdrawTest {

    @Autowired
    private UserServiceImpl userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * 회원탈퇴 후 DB에 is_deleted=true 와 익명화 필드가 실제로 저장되는지 검증.
     *
     * 버그 시나리오: todoRepository / notificationRepository / userCharacterRepository 의
     * @Modifying(clearAutomatically = true) 가 L1 캐시를 clear 하여 user 가 detached 된 뒤
     * user.withdraw() 를 호출해도 dirty-checking 이 동작하지 않아 UPDATE 가 발행되지 않는다.
     * 수정(saveAndFlush) 없이는 이 테스트가 실패한다.
     */
    @Test
    void withdraw_isDeletedTrue_persistedToDB() {
        // given: 신규 유저 등록 (독립 트랜잭션으로 커밋)
        String rawPassword = "Password1!";
        User saved = userRepository.save(
                User.create(
                        "withdraw-test-" + System.currentTimeMillis() + "@e2e.local",
                        passwordEncoder.encode(rawPassword),
                        "wt_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        // when: 탈퇴 호출 (독립 트랜잭션으로 커밋)
        userService.withdraw(userId, new WithdrawReq(rawPassword));

        // then: L1 캐시를 우회하는 신규 SELECT 로 실제 DB 상태 검증
        User reloaded = userRepository.findById(userId)
                .orElseThrow(() -> new AssertionError("탈퇴 후 user row 가 hard delete 됨 — soft delete 여야 함"));

        assertThat(reloaded.getIsDeleted())
                .as("is_deleted 가 DB에 1(true) 로 저장되어야 한다")
                .isTrue();
        assertThat(reloaded.getEmail())
                .as("이메일이 익명화(deleted_ prefix) 되어야 한다")
                .startsWith("deleted_");
        assertThat(reloaded.getUsername())
                .as("username 이 익명화(deleted_ prefix) 되어야 한다")
                .startsWith("deleted_");
        assertThat(reloaded.getPassword())
                .as("비밀번호가 null 로 초기화되어야 한다")
                .isNull();
    }

    /**
     * 이미 탈퇴한 유저를 다시 탈퇴하면 U04_005 에러가 발생해야 한다.
     */
    @Test
    void withdraw_alreadyWithdrawn_throws_U04_005() {
        // given
        String rawPassword = "Password1!";
        User saved = userRepository.save(
                User.create(
                        "already-withdrawn-" + System.currentTimeMillis() + "@e2e.local",
                        passwordEncoder.encode(rawPassword),
                        "aw_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();
        userService.withdraw(userId, new WithdrawReq(rawPassword));

        // when / then
        assertThatThrownBy(() -> userService.withdraw(userId, new WithdrawReq(rawPassword)))
                .isInstanceOf(CustomException.class)
                .satisfies(ex -> {
                    CustomException ce = (CustomException) ex;
                    assertThat(ce.getErrorCode()).isEqualTo(UserErrorCode.U04_005);
                });
    }

    /**
     * 비밀번호 불일치 시 U04_004 에러가 발생해야 한다.
     */
    @Test
    void withdraw_wrongPassword_throws_U04_004() {
        // given
        String rawPassword = "Password1!";
        User saved = userRepository.save(
                User.create(
                        "wrong-pw-" + System.currentTimeMillis() + "@e2e.local",
                        passwordEncoder.encode(rawPassword),
                        "wp_" + System.currentTimeMillis()
                )
        );
        Long userId = saved.getUserId();

        // when / then
        assertThatThrownBy(() -> userService.withdraw(userId, new WithdrawReq("WrongPass!")))
                .isInstanceOf(CustomException.class)
                .satisfies(ex -> {
                    CustomException ce = (CustomException) ex;
                    assertThat(ce.getErrorCode()).isEqualTo(UserErrorCode.U04_004);
                });
    }
}
