package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.api.dto.resp.PaletteResp;
import java.util.List;

public interface PaletteService {

	List<PaletteResp> list();
}
