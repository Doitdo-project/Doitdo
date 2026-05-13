package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 회원가입 시 신규 사용자에게 사용법 안내용 예시 TODO 두 개를 자동 생성한다.
 * 오늘의 할 일(NORMAL) / 언젠가 할 일(SOMEDAY) 에 각각 하나씩.
 *
 * <p>{@link DefaultCategoryRegistrar} 로 생성된 "기타" 카테고리에 묶어 카테고리 필터에서도
 * 자연스럽게 노출되도록 한다. 호출 순서상 카테고리 등록 이후에 와야 한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DefaultTodoRegistrar {

	private static final ZoneId KST = ZoneId.of("Asia/Seoul");
	private static final String FALLBACK_CATEGORY_NAME = "기타";
	private static final int DEFAULT_PRIORITY = 1;

	private static final String TODAY_TITLE = "투두 완료하고 크레딧 받아보기";
	private static final String TODAY_CONTENT = "예시 투두예요. 완료하면 크레딧이 쌓여요. 필요 없으면 삭제해도 괜찮아요.";
	private static final String SOMEDAY_TITLE = "키우고 싶은 다마고치 떠올려보기";
	private static final String SOMEDAY_CONTENT = "예시 투두예요. 언젠가 하고 싶은 일을 자유롭게 적어보세요.";

	private final CategoryRepository categoryRepository;
	private final TodoRepository todoRepository;

	public void registerFor(Long userId) {
		Long categoryId = categoryRepository
				.findByCategoryNameAndUserId(FALLBACK_CATEGORY_NAME, userId)
				.map(Category::getCategoryId)
				.orElse(null);

		LocalDate today = LocalDate.now(KST);

		todoRepository.save(Todo.create(
				userId, categoryId,
				TODAY_TITLE, TODAY_CONTENT,
				TodoType.NORMAL, DEFAULT_PRIORITY,
				null, today, null, Set.of()
		));

		todoRepository.save(Todo.create(
				userId, categoryId,
				SOMEDAY_TITLE, SOMEDAY_CONTENT,
				TodoType.SOMEDAY, DEFAULT_PRIORITY,
				null, null, null, Set.of()
		));
	}
}
