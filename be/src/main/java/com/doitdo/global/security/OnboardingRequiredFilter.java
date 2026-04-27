package com.doitdo.global.security;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.exception.UserErrorCode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * 온보딩 미완료 사용자가 화이트리스트 외 API 를 호출할 때 403 을 반환하는 필터.
 *
 * <p>JwtAuthenticationFilter 이후에 실행되어 인증 여부를 확인하고,
 * 인증된 사용자 중 온보딩 미완료(birthDate == null || termsAgreedAt == null) 인 경우 차단한다.
 * 인증되지 않은 요청은 통과시켜 다운스트림(JwtAuthenticationEntryPoint)에서 401 처리.
 */
public class OnboardingRequiredFilter extends OncePerRequestFilter {

    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final AntPathMatcher pathMatcher = new AntPathMatcher();

    private static final List<String> WHITELIST = List.of(
            "/api/auth/**",
            "/api/users/me",
            "/api/users/me/birth-date",
            "/api/users/me/agreements",
            "/api/users/check-email",
            "/api/users/check-username",
            "/v3/api-docs/**",
            "/swagger-ui/**",
            "/swagger-ui.html",
            "/swagger-resources/**",
            "/actuator/**",
            "/health",
            "/error",
            "/hello",
            "/db-check"
    );

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        String path = request.getRequestURI();

        // 화이트리스트 경로면 통과
        if (isWhitelisted(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        // 인증되지 않은 요청은 통과 (401 은 JwtAuthenticationEntryPoint 담당)
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || !(auth.getPrincipal() instanceof CustomUserDetails)) {
            filterChain.doFilter(request, response);
            return;
        }

        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        User user = userDetails.getUser();

        // 온보딩 미완료: birthDate 또는 termsAgreedAt 이 null
        if (user.getBirthDate() == null || user.getTermsAgreedAt() == null) {
            writeOnboardingRequiredResponse(response);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private boolean isWhitelisted(String path) {
        return WHITELIST.stream().anyMatch(pattern -> pathMatcher.match(pattern, path));
    }

    private void writeOnboardingRequiredResponse(HttpServletResponse response) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        GlobalApiResponse<Void> body = GlobalApiResponse.fail(UserErrorCode.U00_009);
        objectMapper.writeValue(response.getOutputStream(), body);
    }
}
