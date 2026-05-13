package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Palette;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaletteRepository extends JpaRepository<Palette, Long> {

	Optional<Palette> findFirstByOrderByDisplayOrderAsc();

	Optional<Palette> findByPaletteName(String paletteName);
}
