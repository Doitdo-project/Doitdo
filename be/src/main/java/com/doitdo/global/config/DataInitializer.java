package com.doitdo.global.config;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
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
	 * 회원가입 직후부터 모든 사용자가 사용할 수 있는 기본 팔레트.
	 *
	 * <p>Palette / PaletteColor 는 전역 공유 엔티티이며 이 코드 리스트를 SSOT 로
	 * 둔다. 부팅 시:
	 * <ul>
	 *   <li>이름이 DB 에 없으면 색상까지 함께 INSERT (displayOrder = 리스트 위치 + 1).
	 *   <li>이름이 이미 존재하면 색상은 손대지 않고 displayOrder 만 코드 위치에 맞춰 sync
	 *       — 색상 row 의 color_id 는 기존 Category 가 참조 중이라 보존 필수.
	 * </ul>
	 * 첫 번째 팔레트("기본") 의 1~5번 색상이
	 * {@link com.doitdo.domain.todo.application.DefaultCategoryRegistrar} 에서
	 * 기본 카테고리(공부/운동/업무/집안일/기타) 색상으로 사용되며,
	 * 회원가입 시점에 displayOrder 최소값 팔레트를 "기본" 으로 본다.
	 */
	private record PaletteSeed(String name, List<String> colors) {}

	private record FurnitureSeed(
			String code,
			String name,
			String description,
			String category,
			String imageUrl,
			Integer defaultX,
			Integer defaultY,
			Integer width,
			Integer height,
			Integer zIndex
	) {}

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
			new PaletteSeed("풀잎", List.of(
					"#004B23", // 다크 포레스트
					"#006400", // 딥 그린
					"#007200", // 케리 그린
					"#008000", // 그린
					"#38B000", // 라임 그린
					"#70E000", // 옐로우 그린
					"#9EF01A", // 샤르트뢰즈
					"#CCFF33"  // 일렉트릭 라임
			)),
			new PaletteSeed("파도", List.of(
					"#03045E", // 미드나잇 블루
					"#023E8A", // 네이비 블루
					"#0077B6", // 오션 블루
					"#0096C7", // 시안 블루
					"#00B4D8", // 시안
					"#48CAE4", // 스카이 시안
					"#90E0EF", // 아이스 블루
					"#ADE8F4"  // 페일 시안
			)),
			new PaletteSeed("낙엽", List.of(
					"#523218", // 다크 브라운
					"#733308", // 마호가니
					"#96440C", // 시에나
					"#A4603A", // 카키 브라운
					"#D78347", // 테라코타
					"#E68E4F", // 펌킨 오렌지
					"#F18B1E", // 탠저린
					"#ED7A08"  // 번트 오렌지
			)),
			new PaletteSeed("바위", List.of(
					"#A48971", // 토프
					"#8D6B48", // 카멜
					"#9A774F", // 헤이즐넛
					"#A9845A", // 라이트 카멜
					"#BE986D", // 베이지 브라운
					"#D2A87D", // 탠
					"#E8C9AB", // 페일 탠
					"#F5D7BD"  // 크림 베이지
			)),
			new PaletteSeed("벚꽃", List.of(
					"#FF5C8A", // 핫 핑크
					"#FF7096", // 로즈 핑크
					"#FF85A1", // 코랄 핑크
					"#FF99AC", // 살구 핑크
					"#FBB1BD", // 라이트 핑크
					"#F9BEC7", // 베이비 핑크
					"#F7CAD0", // 페일 핑크
					"#FAE0E4"  // 미스티 로즈
			)),
			new PaletteSeed("솜사탕", List.of(
					"#FFD4D9", // 블러시 핑크
					"#FFD5B8", // 피치 크림
					"#FFF0B8", // 버터 옐로우
					"#C4E8BE", // 민트 크림
					"#B8DCF2", // 스카이 미스트
					"#D0C4F0", // 라벤더
					"#F0C5D9", // 로즈 쿼츠
					"#E0D5C5"  // 오트밀
			)),
			new PaletteSeed("꿈", List.of(
					"#FF9AA2", // 드림 코랄
					"#FEB7B1", // 살구 핑크
					"#FFDAC0", // 피치
					"#FFECC4", // 버터 옐로우
					"#E2F0CC", // 라이트 민트
					"#B5EAD6", // 민트 그린
					"#B7DBEB", // 라이트 블루
					"#C7CEEA"  // 라벤더 블루
			))
	);

	private static final List<FurnitureSeed> FURNITURE_SEEDS = List.of(
			new FurnitureSeed(
					"DEFAULT_BACKGROUND",
					"기본 배경",
					"신규 사용자 기본 배경",
					"BACKGROUND",
					"https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/background/default_background.webp",
					0,
					0,
					390,
					640,
					0
			)
	);

	private final PaletteRepository paletteRepository;
	private final PaletteColorRepository paletteColorRepository;
	private final FurnitureRepository furnitureRepository;

	@Override
	@Transactional
	public void run(String... args) {
		initializePalettes();
		initializeDefaultFurnitures();
	}

	private void initializePalettes() {
		int inserted = 0;
		int reordered = 0;

		for (int idx = 0; idx < PALETTE_SEEDS.size(); idx++) {
			PaletteSeed seed = PALETTE_SEEDS.get(idx);
			int displayOrder = idx + 1;

			var existing = paletteRepository.findByPaletteName(seed.name());
			if (existing.isPresent()) {
				Palette palette = existing.get();
				if (!Integer.valueOf(displayOrder).equals(palette.getDisplayOrder())) {
					palette.updateDisplayOrder(displayOrder);
					reordered++;
				}
				continue;
			}

			Palette palette = paletteRepository.save(Palette.create(seed.name(), displayOrder));
			Long paletteId = palette.getPaletteId();
			for (int i = 0; i < seed.colors().size(); i++) {
				paletteColorRepository.save(PaletteColor.create(
						paletteId,
						seed.colors().get(i),
						i + 1
				));
			}
			log.info("Palette '{}' (displayOrder={}) with {} colors initialized",
					seed.name(), displayOrder, seed.colors().size());
			inserted++;
		}

		log.info("Palette seed sync done — inserted={}, reordered={}, total seeds={}",
				inserted, reordered, PALETTE_SEEDS.size());
	}

	private void initializeDefaultFurnitures() {
		for (FurnitureSeed seed : FURNITURE_SEEDS) {
			if (furnitureRepository.findByCodeAndIsDeletedFalse(seed.code()).isPresent()) {
				continue;
			}

			furnitureRepository.save(Furniture.builder()
					.code(seed.code())
					.name(seed.name())
					.description(seed.description())
					.category(seed.category())
					.price(0)
					.imageUrl(seed.imageUrl())
					.thumbnailUrl(seed.imageUrl())
					.defaultX(seed.defaultX())
					.defaultY(seed.defaultY())
					.width(seed.width())
					.height(seed.height())
					.zIndex(seed.zIndex())
					.isOnSale(false)
					.isDeleted(false)
					.build());
			log.info("Default furniture '{}' initialized", seed.code());
		}
	}
}
