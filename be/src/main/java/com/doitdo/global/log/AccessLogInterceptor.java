package com.doitdo.global.log;

import com.doitdo.domain.auth.application.CustomUserDetails;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Slf4j
@Component
public class AccessLogInterceptor implements HandlerInterceptor {

    private static final String START_ATTR = "_access_log_start_ns";

    @Override
    public boolean preHandle(HttpServletRequest req, HttpServletResponse res, Object handler) {
        req.setAttribute(START_ATTR, System.nanoTime());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest req, HttpServletResponse res,
                                Object handler, Exception ex) {
        Object startObj = req.getAttribute(START_ATTR);
        if (!(startObj instanceof Long start)) {
            return;
        }
        long durationMs = (System.nanoTime() - start) / 1_000_000;
        Long userId = null;
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof CustomUserDetails u) {
            userId = u.getUserId();
        }
        log.info("event=ACCESS method={} uri={} status={} userId={} durMs={}",
                req.getMethod(), req.getRequestURI(), res.getStatus(), userId, durationMs);
    }
}
