package com.doitdo.global.bench;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.context.annotation.Profile;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * 트랜잭션 경계 안에서 실제로 머무르는 시간(트랜잭션 홀딩 시간)을 측정하는 dev/local 전용 AOP.
 *
 * <p>Spring 의 {@code @Transactional} aspect 보다 바깥에서 감싸도록 {@link Order} 를
 * {@link Ordered#HIGHEST_PRECEDENCE} 로 지정한다. 따라서 측정 구간이 다음을 모두 포함한다:
 * <pre>
 *   [Aspect] start
 *     [tx]    begin
 *               method body
 *     [tx]    commit / rollback
 *   [Aspect] end
 * </pre>
 *
 * <p>측정 범위는 인증 / TODO / 다마고치 도메인의 application 레이어로 제한 — 다른 트랜잭션이 노이즈로 끼지 않게.
 *
 * <p>운영 환경에 의도치 않게 적재되더라도 {@link Profile} 조건이 클래스 자체를 비활성화한다.
 */
@Slf4j
@Aspect
@Component
@Profile({"dev", "local"})
@Order(Ordered.HIGHEST_PRECEDENCE)
public class TransactionTimingAspect {

    @Around("@annotation(org.springframework.transaction.annotation.Transactional) && ("
            + "execution(* com.doitdo.domain.auth.application..*(..))"
            + " || execution(* com.doitdo.domain.todo.application..*(..))"
            + " || execution(* com.doitdo.domain.tamagotchi.application..*(..))"
            + ")")
    public Object measure(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.nanoTime();
        boolean threw = false;
        try {
            return pjp.proceed();
        } catch (Throwable t) {
            threw = true;
            throw t;
        } finally {
            long durationMs = (System.nanoTime() - start) / 1_000_000;
            log.info("[tx-bench] method={} duration={}ms outcome={}",
                    pjp.getSignature().toShortString(),
                    durationMs,
                    threw ? "THROWN" : "OK");
        }
    }
}
