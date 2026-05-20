package com.doitdo.global.config;

import java.util.concurrent.Executor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

@Configuration
@EnableAsync
public class AsyncConfig {

	/**
	 * 메일 발송 전용 Executor.
	 *
	 * <p>SMTP 응답이 1~3초 걸려 API 응답이 느려지는 것을 막기 위해 {@code @Async("mailExecutor")} 로 비동기 처리.
	 * 큐가 가득 차면 {@code CallerRunsPolicy} 로 호출 스레드(= 컨트롤러 워커)가 직접 발송 — drop 보다 안전한 backpressure.
	 */
	@Bean(name = "mailExecutor")
	public Executor mailExecutor() {
		ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
		executor.setCorePoolSize(2);
		executor.setMaxPoolSize(5);
		executor.setQueueCapacity(50);
		executor.setThreadNamePrefix("mail-");
		executor.initialize();
		return executor;
	}
}
