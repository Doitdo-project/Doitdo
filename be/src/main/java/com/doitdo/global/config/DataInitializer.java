package com.doitdo.global.config;

import com.doitdo.domain.todo.entity.Palette;
import com.doitdo.domain.todo.entity.PaletteColor;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.PaletteRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

	/**
	 * 회원가입 직후부터 모든 사용자가 사용할 수 있는 기본 팔레트 4종.
	 *
	 * <p>Palette / PaletteColor 는 전역 공유 엔티티이므로 여기서 한 번 seed 하면
	 * 모든 사용자가 동일하게 접근할 수 있다. 첫 번째 팔레트("기본") 의 1~5번 색상이
	 * {@link com.doitdo.domain.todo.application.DefaultCategoryRegistrar} 에서
	 * 기본 카테고리(공부/운동/업무/집안일/기타) 색상으로 사용된다.
	 */
	private record PaletteSeed(String name, List<String> colors) {}

	private static final List<PaletteSeed> PALETTE_SEEDS = List.of(
			new PaletteSeed("기본", List.of(
					"#1B2A41", // 딥 네이비
					"#577B9C", // 스틸 블루
					"#4A90E2", // 스카이 블루
					"#B8D8DB", // 파우더 블루
					"#6B8E5A", // 세이지 그린
					"#F4E4C1", // 웜 크림
					"#F5A623", // 앰버 오렌지
					"#CB3A45"  // 크림슨 레드
			)),
			new PaletteSeed("얼씨", List.of(
					"#1F1410", // 에스프레소
					"#6B3410", // 체스트넛
					"#C1392A", // 브릭 레드
					"#DC6B3A", // 테라코타
					"#E89A3C", // 골든 앰버
					"#F2E1B6", // 크림 베이지
					"#7C8457", // 올리브 모스
					"#3E5641"  // 딥 포레스트
			)),
			new PaletteSeed("네온", List.of(
					"#0D0221", // 딥 스페이스
					"#1E1B4B", // 미드나잇 바이올렛
					"#7209B7", // 일렉트릭 퍼플
					"#F72585", // 핫 마젠타
					"#FB5607", // 네온 오렌지
					"#FFD60A", // 네온 옐로우
					"#06FFA5", // 에시드 민트
					"#4361EE"  // 사이버 블루
			)),
			new PaletteSeed("파스텔", List.of(
					"#FFD4D9", // 블러시 핑크
					"#FFD5B8", // 피치 크림
					"#FFF0B8", // 버터 옐로우
					"#C4E8BE", // 민트 크림
					"#B8DCF2", // 스카이 미스트
					"#D0C4F0", // 라벤더
					"#F0C5D9", // 로즈 쿼츠
					"#E0D5C5"  // 오트밀
			))
	);

	private final PaletteRepository paletteRepository;
	private final PaletteColorRepository paletteColorRepository;

	@Override
	@Transactional
	public void run(String... args) {
		if (paletteRepository.count() > 0) {
			return;
		}

		log.info("Initializing {} default palettes", PALETTE_SEEDS.size());

		for (PaletteSeed seed : PALETTE_SEEDS) {
			Palette palette = paletteRepository.save(Palette.create(seed.name()));
			Long paletteId = palette.getPaletteId();
			for (int i = 0; i < seed.colors().size(); i++) {
				paletteColorRepository.save(PaletteColor.create(
						paletteId,
						seed.colors().get(i),
						i + 1
				));
			}
			log.info("Palette '{}' with {} colors initialized", seed.name(), seed.colors().size());
		}
	}
}
