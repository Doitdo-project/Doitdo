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

	private static final String DEFAULT_PALETTE_NAME = "기본";

	private static final List<String> DEFAULT_PALETTE_COLORS = List.of(
			"#4A90E2",
			"#CB3A45",
			"#577B9C",
			"#B8D8DB",
			"#F5A623"
	);

	private final PaletteRepository paletteRepository;
	private final PaletteColorRepository paletteColorRepository;

	@Override
	@Transactional
	public void run(String... args) {
		if (paletteRepository.count() > 0) {
			return;
		}

		log.info("Initializing default palette and palette colors");

		Palette defaultPalette = paletteRepository.save(Palette.create(DEFAULT_PALETTE_NAME));
		Long paletteId = defaultPalette.getPaletteId();

		for (int i = 0; i < DEFAULT_PALETTE_COLORS.size(); i++) {
			paletteColorRepository.save(PaletteColor.create(
					paletteId,
					DEFAULT_PALETTE_COLORS.get(i),
					i + 1
			));
		}

		log.info("Default palette '{}' with {} colors initialized", DEFAULT_PALETTE_NAME, DEFAULT_PALETTE_COLORS.size());
	}
}
