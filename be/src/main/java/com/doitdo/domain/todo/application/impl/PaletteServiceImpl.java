package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.resp.PaletteResp;
import com.doitdo.domain.todo.application.PaletteService;
import com.doitdo.domain.todo.entity.Palette;
import com.doitdo.domain.todo.entity.PaletteColor;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.PaletteRepository;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PaletteServiceImpl implements PaletteService {

	private final PaletteRepository paletteRepository;
	private final PaletteColorRepository paletteColorRepository;

	/**
	 * 전체 팔레트 목록 조회.
	 * N+1 회피: PaletteColor 전체를 한 번 조회 후 paletteId 로 그룹핑.
	 * 팔레트는 displayOrder 오름차순으로 반환하며, colors 는 colorOrder 오름차순 hex 배열.
	 */
	@Override
	@Transactional(readOnly = true)
	public List<PaletteResp> list() {
		List<Palette> palettes = paletteRepository.findAll();

		Map<Long, List<PaletteColor>> colorsByPaletteId = paletteColorRepository.findAll()
				.stream()
				.collect(Collectors.groupingBy(PaletteColor::getPaletteId));

		return palettes.stream()
				.sorted(Comparator.comparing(Palette::getDisplayOrder))
				.map(palette -> {
					List<String> colors = colorsByPaletteId
							.getOrDefault(palette.getPaletteId(), List.of())
							.stream()
							.sorted(Comparator.comparing(PaletteColor::getColorOrder))
							.map(PaletteColor::getColor)
							.toList();
					return new PaletteResp(palette.getPaletteId(), palette.getPaletteName(), colors);
				})
				.toList();
	}
}
