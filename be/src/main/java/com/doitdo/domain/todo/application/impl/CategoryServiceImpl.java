package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.CategoryCreateReq;
import com.doitdo.domain.todo.api.dto.req.CategoryUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.CategoryListResp;
import com.doitdo.domain.todo.api.dto.resp.CategoryResp;
import com.doitdo.domain.todo.application.CategoryService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CategoryServiceImpl implements CategoryService {

	private static final int MAX_CATEGORY_COUNT = 6;

	private final CategoryRepository categoryRepository;

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

		// TODO: 고정 카테고리(공부/업무/운동/집안일) 시드 로직 — Category 엔티티에 isFixed 플래그 추가 후 회원가입 시 생성 예정
		Category category = categoryRepository.save(Category.create(userId, req.name(), req.colorId()));
		return CategoryResp.from(category);
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

		// TODO: 고정 카테고리(공부/업무/운동/집안일) 삭제 방지 —
		//       Category 엔티티에 isFixed 플래그 추가 후 여기서 체크하여 T11_003 던질 예정
		categoryRepository.delete(category);
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

		// 이름 변경 시에만 중복 체크 (현재 이름과 동일한 경우 체크 생략)
		if (req.name() != null && !req.name().equals(category.getCategoryName())) {
			if (categoryRepository.existsByCategoryNameAndUserId(req.name(), userId)) {
				throw new CustomException(TodoErrorCode.T12_004);
			}
		}

		category.update(req.name(), req.colorId());
		return CategoryResp.from(category);
	}

	/**
	 * T13 — 카테고리 전체 목록 조회.
	 * 본인 소유 카테고리를 categoryId ASC 순으로 반환한다.
	 */
	@Override
	@Transactional(readOnly = true)
	public CategoryListResp list(Long userId) {
		return CategoryListResp.from(
				categoryRepository.findAllByUserIdOrderByCategoryIdAsc(userId)
		);
	}
}
