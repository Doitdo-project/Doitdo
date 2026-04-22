package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.Palette;
import com.doitdo.domain.todo.entity.PaletteColor;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.PaletteRepository;
import com.doitdo.global.exception.CommonErrorCode;
import com.doitdo.global.exception.CustomException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 회원가입 시 신규 사용자에게 기본 TODO 카테고리 5개를 자동 생성한다.
 * 공부 / 운동 / 업무 / 집안일 / 기타 — 기본 팔레트의 색상 1~5에 순서대로 매핑.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DefaultCategoryRegistrar {

	private static final List<String> DEFAULT_CATEGORY_NAMES = List.of(
			"공부", "운동", "업무", "집안일", "기타"
	);

	private final PaletteRepository paletteRepository;
	private final PaletteColorRepository paletteColorRepository;
	private final CategoryRepository categoryRepository;

	public void registerFor(Long userId) {
		Palette defaultPalette = paletteRepository.findFirstByOrderByPaletteIdAsc()
				.orElseThrow(() -> new CustomException(CommonErrorCode.INTERNAL_SERVER_ERROR,
						"기본 팔레트가 초기화되지 않았습니다."));

		List<PaletteColor> colors = paletteColorRepository
				.findAllByPaletteIdOrderByColorOrderAsc(defaultPalette.getPaletteId());

		if (colors.size() < DEFAULT_CATEGORY_NAMES.size()) {
			log.warn("Default palette has {} colors, required {}", colors.size(), DEFAULT_CATEGORY_NAMES.size());
			throw new CustomException(CommonErrorCode.INTERNAL_SERVER_ERROR,
					"기본 팔레트 색상이 부족합니다.");
		}

		for (int i = 0; i < DEFAULT_CATEGORY_NAMES.size(); i++) {
			categoryRepository.save(Category.create(
					userId,
					DEFAULT_CATEGORY_NAMES.get(i),
					colors.get(i).getColorId()
			));
		}
	}
}
