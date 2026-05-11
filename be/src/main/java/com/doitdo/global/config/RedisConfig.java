package com.doitdo.global.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.time.Duration;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext.SerializationPair;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
@EnableCaching
@ConditionalOnProperty(name = "spring.cache.type", havingValue = "redis", matchIfMissing = true)
public class RedisConfig {

	private static final String TODOS_LIST = "todos:list";
	private static final String TODOS_ITEM = "todos:item";
	private static final String TAMAGOTCHI_CURRENT = "tamagotchi:current";
	private static final String CATEGORIES = "categories";

	@Bean
	public RedisCacheManager redisCacheManager(
			RedisConnectionFactory connectionFactory,
			GenericJackson2JsonRedisSerializer redisCacheValueSerializer) {
		RedisCacheConfiguration defaultConfig = redisCacheConfiguration(
				Duration.ofHours(1),
				redisCacheValueSerializer);

		Map<String, RedisCacheConfiguration> cacheConfigurations = Map.of(
				TODOS_LIST, redisCacheConfiguration(Duration.ofHours(1), redisCacheValueSerializer),
				TODOS_ITEM, redisCacheConfiguration(Duration.ofMinutes(5), redisCacheValueSerializer),
				TAMAGOTCHI_CURRENT, redisCacheConfiguration(Duration.ofMinutes(30), redisCacheValueSerializer),
				CATEGORIES, redisCacheConfiguration(Duration.ofHours(1), redisCacheValueSerializer)
		);

		return RedisCacheManager.builder(connectionFactory)
				.cacheDefaults(defaultConfig)
				.withInitialCacheConfigurations(cacheConfigurations)
				.build();
	}

	@Bean
	public GenericJackson2JsonRedisSerializer redisCacheValueSerializer() {
		ObjectMapper objectMapper = JsonMapper.builder()
				.addModule(new JavaTimeModule())
				.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
				.build();
		objectMapper.activateDefaultTypingAsProperty(
				LaissezFaireSubTypeValidator.instance,
				ObjectMapper.DefaultTyping.EVERYTHING,
				"@class");
		return new GenericJackson2JsonRedisSerializer(objectMapper);
	}

	private RedisCacheConfiguration redisCacheConfiguration(
			Duration ttl,
			GenericJackson2JsonRedisSerializer valueSerializer) {
		return RedisCacheConfiguration.defaultCacheConfig()
				.entryTtl(ttl)
				.computePrefixWith(name -> name + "::")
				.serializeKeysWith(SerializationPair.fromSerializer(new StringRedisSerializer()))
				.serializeValuesWith(SerializationPair.fromSerializer(valueSerializer))
				.disableCachingNullValues();
	}
}
