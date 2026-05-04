package com.doitdo.global.cache;

import java.util.ArrayList;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.Cursor;
import org.springframework.data.redis.core.ScanOptions;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Slf4j
@Component
public class CacheEvictHelper {

	private final StringRedisTemplate redisTemplate;
	private final boolean enabled;

	public CacheEvictHelper(
			StringRedisTemplate redisTemplate,
			@Value("${spring.cache.type:redis}") String cacheType) {
		this.redisTemplate = redisTemplate;
		this.enabled = "redis".equalsIgnoreCase(cacheType);
	}

	public void evictUserTodos(Long userId) {
		evictByPattern("todos:list::" + userId + ":*");
	}

	public void evictTodoItem(Long userId, Long todoId) {
		delete("todos:item::" + userId + ":" + todoId);
	}

	public void evictTamagotchiCurrent(Long userId) {
		delete("tamagotchi:current::" + userId);
	}

	public void evictCategories(Long userId) {
		delete("categories::" + userId);
	}

	public void evictUserTodosAfterCommit(Long userId) {
		afterCommit(() -> evictUserTodos(userId));
	}

	public void evictTodoItemAfterCommit(Long userId, Long todoId) {
		afterCommit(() -> evictTodoItem(userId, todoId));
	}

	public void evictTamagotchiCurrentAfterCommit(Long userId) {
		afterCommit(() -> evictTamagotchiCurrent(userId));
	}

	public void evictCategoriesAfterCommit(Long userId) {
		afterCommit(() -> evictCategories(userId));
	}

	private void evictByPattern(String pattern) {
		if (!enabled) {
			return;
		}
		List<String> keys = new ArrayList<>();
		try (Cursor<String> cursor = redisTemplate.scan(
				ScanOptions.scanOptions().match(pattern).count(100).build())) {
			cursor.forEachRemaining(keys::add);
		}

		if (!keys.isEmpty()) {
			redisTemplate.delete(keys);
			log.debug("evicted redis cache pattern={} count={}", pattern, keys.size());
		}
	}

	private void delete(String key) {
		if (!enabled) {
			return;
		}
		redisTemplate.delete(key);
		log.debug("evicted redis cache key={}", key);
	}

	private void afterCommit(Runnable action) {
		if (!enabled) {
			return;
		}
		if (!TransactionSynchronizationManager.isSynchronizationActive()
				|| !TransactionSynchronizationManager.isActualTransactionActive()) {
			action.run();
			return;
		}

		TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
			@Override
			public void afterCommit() {
				action.run();
			}
		});
	}
}
