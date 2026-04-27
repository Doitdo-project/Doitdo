package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.api.dto.req.CategoryCreateReq;
import com.doitdo.domain.todo.api.dto.req.CategoryUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.CategoryListResp;
import com.doitdo.domain.todo.api.dto.resp.CategoryResp;

public interface CategoryService {

	CategoryResp create(Long userId, CategoryCreateReq req);

	void delete(Long userId, Long categoryId);

	CategoryResp update(Long userId, Long categoryId, CategoryUpdateReq req);

	CategoryListResp list(Long userId);
}
