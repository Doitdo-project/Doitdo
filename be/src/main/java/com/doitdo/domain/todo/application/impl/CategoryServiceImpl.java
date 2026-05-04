package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.CategoryCreateReq;
import com.doitdo.domain.todo.api.dto.req.CategoryUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.CategoryListResp;
import com.doitdo.domain.todo.api.dto.resp.CategoryResp;
import com.doitdo.domain.todo.application.CategoryService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.PaletteColor;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.global.cache.CacheEvictHelper;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoryServiceImpl implements CategoryService {

	private static final int MAX_CATEGORY_COUNT = 6;

	private final CategoryRepository categoryRepository;
	private final PaletteColorRepository paletteColorRepository;
	private final CacheEvictHelper cacheEvictHelper;

	/**
	 * T10 — 카테고리 생성.
	 * 사용자당 최대 6개 제한 → 중복 이름 체크 순으로 검증한다.
	 */
	@Override
	@Transactional
	public CategoryResp create(Long userId, CategoryCreateReq req) {
		if (categoryRepository.countByUserId(userId) >= MAX_CATEGORY_COUNT) {
			throw new CustomException(TodoErrorCode.T10_003);
		}

		if (categoryRepository.existsByCategoryNameAndUserId(req.name(), userId)) {
			throw new CustomException(TodoErrorCode.T10_004);
		}

		Category category = categoryRepository.save(Category.create(userId, req.name(), req.colorId()));
		String colorHex = resolveColorHex(category.getColorId());
		log.info("event=CATEGORY_CREATED userId={} categoryId={}", userId, category.getCategoryId());
		cacheEvictHelper.evictCategoriesAfterCommit(userId);
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
		return CategoryResp.from(category, colorHex);
	}

	/**
	 * T11 — 카테고리 하드 삭제.
	 * Category 엔티티에 isDeleted 없으므로 DB 에서 직접 삭제한다.
	 */
	@Override
	@Transactional
	public void delete(Long userId, Long categoryId) {
		Category category = categoryRepository.findById(categoryId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T11_001));

		if (!category.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T11_003);
		}

		categoryRepository.delete(category);
		log.info("event=CATEGORY_DELETED userId={} categoryId={}", userId, categoryId);
		cacheEvictHelper.evictCategoriesAfterCommit(userId);
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
	}

	/**
	 * T12 — 카테고리 부분 수정.
	 * 소유자 확인 실패 시 T12_002 를 재사용한다.
	 * (노션 스펙에 FORBIDDEN 에러코드 미정의 — 추가되면 전용 코드로 교체 예정)
	 */
	@Override
	@Transactional
	public CategoryResp update(Long userId, Long categoryId, CategoryUpdateReq req) {
		Category category = categoryRepository.findById(categoryId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T12_001));

		// T12_002 원 의미는 인증 실패이나 소유자 체크(FORBIDDEN)에 임시 재사용 — 노션 FORBIDDEN 코드 추가 후 교체
		if (!category.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T12_002);
		}

		// 빈 문자열 이름 차단 — null 은 "변경 없음" 을 의미하므로 허용
		if (req.name() != null && req.name().isBlank()) {
			throw new CustomException(TodoErrorCode.T12_003);
		}

		// 이름 변경 시에만 중복 체크 (현재 이름과 동일한 경우 체크 생략)
		if (req.name() != null && !req.name().equals(category.getCategoryName())) {
			if (categoryRepository.existsByCategoryNameAndUserId(req.name(), userId)) {
				throw new CustomException(TodoErrorCode.T12_004);
			}
		}

		category.update(req.name(), req.colorId());
		String colorHex = resolveColorHex(category.getColorId());
		log.info("event=CATEGORY_UPDATED userId={} categoryId={}", userId, categoryId);
		cacheEvictHelper.evictCategoriesAfterCommit(userId);
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
		return CategoryResp.from(category, colorHex);
	}

	/**
	 * T13 — 카테고리 전체 목록 조회.
	 * 본인 소유 카테고리를 categoryId ASC 순으로 반환한다.
	 * N+1 회피: PaletteColor 전체를 한 번 조회 후 Map 으로 변환해 사용.
	 */
	@Override
	@Transactional(readOnly = true)
	@Cacheable(value = "categories", key = "#userId", unless = "#result == null")
	public CategoryListResp list(Long userId) {
		Map<Integer, String> colorIdToHex = buildColorIdToHexMap();
		return CategoryListResp.from(
				categoryRepository.findAllByUserIdOrderByCategoryIdAsc(userId),
				colorIdToHex
		);
	}

	/** colorId → hex 변환 맵 (PaletteColor 전체 조회, 1회) */
	private Map<Integer, String> buildColorIdToHexMap() {
		return paletteColorRepository.findAll().stream()
				.collect(Collectors.toMap(PaletteColor::getColorId, PaletteColor::getColor));
	}

	/** 단건 colorHex 조회 (create/update 시 사용) */
	private String resolveColorHex(Integer colorId) {
		if (colorId == null) {
			return null;
		}
		return paletteColorRepository.findById(colorId)
				.map(PaletteColor::getColor)
				.orElse(null);
	}
}
