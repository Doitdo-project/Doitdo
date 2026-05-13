package com.doitdo.global.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.todo.entity.Palette;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.PaletteRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DataInitializerTest {

	@Mock
	private PaletteRepository paletteRepository;

	@Mock
	private PaletteColorRepository paletteColorRepository;

	@Mock
	private FurnitureRepository furnitureRepository;

	@Test
	void runSeedsDefaultBackgroundEvenWhenPalettesAlreadyExist() {
		DataInitializer initializer = new DataInitializer(
				paletteRepository,
				paletteColorRepository,
				furnitureRepository
		);
		given(paletteRepository.findByPaletteName(any())).willReturn(Optional.of(Palette.create("이미존재")));
		given(furnitureRepository.findByCodeAndIsDeletedFalse("DEFAULT_BACKGROUND")).willReturn(Optional.empty());

		initializer.run();

		ArgumentCaptor<Furniture> captor = ArgumentCaptor.forClass(Furniture.class);
		verify(furnitureRepository, times(1)).save(captor.capture());

		assertThat(captor.getAllValues())
				.extracting(Furniture::getCode)
				.containsExactly("DEFAULT_BACKGROUND");
		assertThat(captor.getAllValues())
				.extracting(Furniture::getCategory)
				.containsExactly("BACKGROUND");
		assertThat(captor.getAllValues())
				.extracting(Furniture::getPrice)
				.containsExactly(0);
		assertThat(captor.getAllValues())
				.extracting(Furniture::getImageUrl)
				.containsExactly(
						"https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/background/default_background.webp"
				);
		assertThat(captor.getAllValues())
				.extracting(Furniture::getThumbnailUrl)
				.containsExactly(
						"https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/background/default_background.webp"
				);
	}
}
