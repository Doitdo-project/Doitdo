package com.doitdo.global.security;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.global.util.JwtUtil;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

/**
 * OnboardingRequiredFilter 통합 테스트.
 *
 * <p>실제 Spring Security 필터 체인을 통해 동작하므로 @AutoConfigureMockMvc 를 사용한다.
 */
@ActiveProfiles("test")
@SpringBootTest
@AutoConfigureMockMvc
class OnboardingRequiredFilterTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * 온보딩 미완료 사용자(birthDate=null)가 보호 API 호출 → 403 + U00-009.
     */
    @Test
    void onboardingIncomplete_birthDateNull_blocked() throws Exception {
        User user = userRepository.save(
                User.create(
                        "filter-test-incomplete-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "fi_" + System.currentTimeMillis()
                )
        );
        String token = jwtUtil.generateAccessToken(user.getUserId());

        try {
            mockMvc.perform(get("/api/users/me/password")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("U00-009"));
        } finally {
            userRepository.deleteById(user.getUserId());
        }
    }

    /**
     * 온보딩 미완료 사용자가 화이트리스트 경로(GET /api/users/me) 호출 → 통과.
     */
    @Test
    void onboardingIncomplete_whitelistedPath_passes() throws Exception {
        User user = userRepository.save(
                User.create(
                        "filter-test-wl-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "fw_" + System.currentTimeMillis()
                )
        );
        String token = jwtUtil.generateAccessToken(user.getUserId());

        try {
            mockMvc.perform(get("/api/users/me")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.dailyAttendanceClaimed").value(false));
        } finally {
            userRepository.deleteById(user.getUserId());
        }
    }

    /**
     * 온보딩 완료 사용자가 보호 API 호출 → 통과 (비밀번호 변경 API 는 body 없으면 400 이지만 403 아님).
     */
    @Test
    void onboardingComplete_protectedPath_notBlocked() throws Exception {
        User user = userRepository.save(
                User.builder()
                        .email("filter-test-complete-" + System.currentTimeMillis() + "@test.local")
                        .password("encoded")
                        .username("fc_" + System.currentTimeMillis())
                        .birthDate(LocalDate.of(1990, 1, 1))
                        .termsAgreedAt(LocalDateTime.now())
                        .privacyAgreedAt(LocalDateTime.now())
                        .termsVersion("1.0")
                        .isDeleted(false)
                        .build()
        );
        String token = jwtUtil.generateAccessToken(user.getUserId());

        try {
            // 비밀번호 변경 API 에 body 없이 호출 → 400(검증 오류)이지 403(온보딩 차단)이 아님
            mockMvc.perform(post("/api/users/me/password")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().is4xxClientError())
                    .andExpect(result -> {
                        int status = result.getResponse().getStatus();
                        if (status == 403) {
                            throw new AssertionError("온보딩 완료 사용자가 403 을 받으면 안 됩니다. status=" + status);
                        }
                    });
        } finally {
            userRepository.deleteById(user.getUserId());
        }
    }

    /**
     * 미인증 요청이 보호 API 호출 → 401 (온보딩 필터 아님, Security 처리).
     */
    @Test
    void unauthenticated_protectedPath_returns401() throws Exception {
        mockMvc.perform(get("/api/users/me/password"))
                .andExpect(status().isUnauthorized());
    }

    /**
     * 온보딩 미완료 사용자가 /api/users/me/birth-date POST → 통과 (화이트리스트).
     */
    @Test
    void onboardingIncomplete_birthDatePath_passes() throws Exception {
        User user = userRepository.save(
                User.create(
                        "filter-test-bd-" + System.currentTimeMillis() + "@test.local",
                        "encoded",
                        "fbd_" + System.currentTimeMillis()
                )
        );
        String token = jwtUtil.generateAccessToken(user.getUserId());

        try {
            // 유효하지 않은 body 지만 필터는 통과해야 하므로 4xx(검증 오류 422) 응답이어야 함 — 403(온보딩 차단)이 아님
            mockMvc.perform(post("/api/users/me/birth-date")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().is4xxClientError())
                    .andExpect(result -> {
                        int s = result.getResponse().getStatus();
                        if (s == 403) {
                            throw new AssertionError("온보딩 화이트리스트 경로가 403 으로 차단됨 — 통과 해야 함");
                        }
                    });
        } finally {
            // user 가 hard delete 됐을 수 있으니 Optional 처리
            userRepository.findById(user.getUserId()).ifPresent(u -> userRepository.deleteById(u.getUserId()));
        }
    }
}
