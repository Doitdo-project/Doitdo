package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.PaletteColor;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaletteColorRepository extends JpaRepository<PaletteColor, Integer> {

	List<PaletteColor> findAllByPaletteIdOrderByColorOrderAsc(Long paletteId);
}
