package com.doitdo.domain.todo.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.todo.api.dto.req.CategoryCreateReq;
import com.doitdo.domain.todo.api.dto.req.CategoryUpdateReq;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.resp.CategoryResp;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.entity.Palette;
import com.doitdo.domain.todo.entity.PaletteColor;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.PaletteRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

/**
 * 카테고리 삭제 정책 (이름·색 스냅샷) 통합 테스트.
 *
 * 정책:
 *  1. 카테고리 삭제 시 todo 의 category_name / category_color_id 스냅샷은 그대로 잔여,
 *     category_id 만 NULL 로 detach 된다.
 *  2. 카테고리 rename / 색상 변경 시 해당 카테고리를 쓰던 활성 todo 의 스냅샷이 일괄 update.
 *  3. 필터는 이름 기반 매칭 — 동일 이름 카테고리를 다시 만들면 옛 todo 도 함께 잡힌다.
 *  4. 응답 colorHex 는 동일 이름의 활성 카테고리가 있으면 그 색이, 없으면 todo 의 스냅샷 색이 노출된다.
 */
@SpringBootTest
@ActiveProfiles("test")
class CategorySnapshotIntegrationTest {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	@Autowired private TodoService todoService;
	@Autowired private CategoryService categoryService;
	@Autowired private TodoRepository todoRepository;
	@Autowired private UserRepository userRepository;
	@Autowired private PaletteRepository paletteRepository;
	@Autowired private PaletteColorRepository paletteColorRepository;
	@Autowired private JdbcTemplate jdbcTemplate;

	private Long userId;
	private Integer redColorId;
	private Integer blueColorId;
	private Integer greenColorId;

	@BeforeEach
	void setUp() {
		jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
		for (String table : List.of("todos", "categories", "palette_colors", "palettes", "users")) {
			jdbcTemplate.update("DELETE FROM " + table);
		}
		jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");

		User user = userRepository.saveAndFlush(User.create(
				"snapshot@test.com", "encoded-pw", "snapshot-user"));
		userId = user.getUserId();

		Palette palette = paletteRepository.saveAndFlush(Palette.create("default", 1));
		redColorId = paletteColorRepository.saveAndFlush(
				PaletteColor.create(palette.getPaletteId(), "#FF0000", 1)).getColorId();
		blueColorId = paletteColorRepository.saveAndFlush(
				PaletteColor.create(palette.getPaletteId(), "#0000FF", 2)).getColorId();
		greenColorId = paletteColorRepository.saveAndFlush(
				PaletteColor.create(palette.getPaletteId(), "#00FF00", 3)).getColorId();
	}

	@Test
	@DisplayName("todo 생성 시 카테고리의 이름·색 스냅샷이 todo 에 저장된다")
	void create_storesCategorySnapshotOnTodo() {
		CategoryResp work = categoryService.create(userId, new CategoryCreateReq("공부", redColorId));
		createTodo("문제풀이", "공부");

		Todo saved = singleTodo();
		assertThat(saved.getCategoryId()).isEqualTo(work.categoryId());
		assertThat(saved.getCategoryName()).isEqualTo("공부");
		assertThat(saved.getCategoryColorId()).isEqualTo(redColorId);

		TodoDetailResp resp = singleListItem();
		assertThat(resp.category()).isEqualTo("공부");
		assertThat(resp.colorHex()).isEqualTo("#FF0000");
	}

	@Test
	@DisplayName("카테고리 rename 시 해당 todo 들의 이름 스냅샷이 일괄 전파된다")
	void rename_propagatesSnapshotName() {
		CategoryResp work = categoryService.create(userId, new CategoryCreateReq("공부", redColorId));
		createTodo("문제풀이", "공부");

		categoryService.update(userId, work.categoryId(), new CategoryUpdateReq("학업", null));

		Todo saved = singleTodo();
		assertThat(saved.getCategoryName()).isEqualTo("학업");
		assertThat(saved.getCategoryColorId()).isEqualTo(redColorId);

		TodoDetailResp resp = singleListItem();
		assertThat(resp.category()).isEqualTo("학업");
		assertThat(resp.colorHex()).isEqualTo("#FF0000");
	}

	@Test
	@DisplayName("카테고리 색 변경 시 해당 todo 들의 색 스냅샷이 일괄 전파된다")
	void colorChange_propagatesSnapshotColor() {
		CategoryResp work = categoryService.create(userId, new CategoryCreateReq("공부", redColorId));
		createTodo("문제풀이", "공부");

		categoryService.update(userId, work.categoryId(), new CategoryUpdateReq(null, blueColorId));

		Todo saved = singleTodo();
		assertThat(saved.getCategoryColorId()).isEqualTo(blueColorId);

		TodoDetailResp resp = singleListItem();
		assertThat(resp.colorHex()).isEqualTo("#0000FF");
	}

	@Test
	@DisplayName("카테고리 삭제 시 todo 의 category_id 는 NULL, 이름·색 스냅샷은 잔여")
	void delete_keepsSnapshotButDetachesCategoryId() {
		CategoryResp work = categoryService.create(userId, new CategoryCreateReq("공부", redColorId));
		createTodo("문제풀이", "공부");

		categoryService.delete(userId, work.categoryId());

		Todo saved = singleTodo();
		assertThat(saved.getCategoryId()).isNull();
		assertThat(saved.getCategoryName()).isEqualTo("공부");
		assertThat(saved.getCategoryColorId()).isEqualTo(redColorId);

		TodoDetailResp resp = singleListItem();
		assertThat(resp.category()).isEqualTo("공부");
		// 활성 카테고리에 같은 이름이 없으므로 스냅샷 색을 그대로 사용한다.
		assertThat(resp.colorHex()).isEqualTo("#FF0000");
	}

	@Test
	@DisplayName("삭제 후 동일 이름 카테고리를 다른 색으로 재생성하면 옛 todo 의 colorHex 가 새 색으로 override")
	void recreateSameName_overridesColorHex() {
		CategoryResp work = categoryService.create(userId, new CategoryCreateReq("공부", redColorId));
		createTodo("문제풀이", "공부");
		categoryService.delete(userId, work.categoryId());

		// 같은 이름 "공부" 로 다시 만들되 색을 green 으로 변경.
		categoryService.create(userId, new CategoryCreateReq("공부", greenColorId));

		Todo saved = singleTodo();
		// DB 의 todo 스냅샷은 변하지 않는다 (deleted 시 스냅샷은 잔여, 재생성은 동일 이름 매칭에만 의존).
		assertThat(saved.getCategoryName()).isEqualTo("공부");
		assertThat(saved.getCategoryColorId()).isEqualTo(redColorId);

		TodoDetailResp resp = singleListItem();
		assertThat(resp.category()).isEqualTo("공부");
		// 응답 빌드 시 동일 이름의 활성 카테고리 색(green) 으로 override.
		assertThat(resp.colorHex()).isEqualTo("#00FF00");
	}

	@Test
	@DisplayName("이름 기반 필터: 카테고리 삭제 후 동일 이름 재생성 시 옛 todo 도 필터에 함께 잡힌다")
	void nameBasedFilter_matchesAcrossDeleteAndRecreate() {
		CategoryResp work = categoryService.create(userId, new CategoryCreateReq("공부", redColorId));
		createTodo("옛문제", "공부");
		categoryService.delete(userId, work.categoryId());
		// 다시 동일 이름 "공부" 카테고리를 만들고 신규 todo 도 붙임.
		categoryService.create(userId, new CategoryCreateReq("공부", greenColorId));
		createTodo("새문제", "공부");

		List<TodoDetailResp> items = todoService.list(userId, filterByCategoryToday("공부")).items();

		assertThat(items)
				.extracting(TodoDetailResp::title)
				.containsExactlyInAnyOrder("옛문제", "새문제");
		assertThat(items)
				.extracting(TodoDetailResp::category)
				.containsOnly("공부");
		// 양쪽 todo 모두 현재 활성 "공부" 카테고리의 색(green) 으로 노출된다.
		assertThat(items)
				.extracting(TodoDetailResp::colorHex)
				.containsOnly("#00FF00");
	}

	// ── 헬퍼 ────────────────────────────────────────────────────────────────

	private void createTodo(String title, String categoryName) {
		LocalDate today = LocalDate.now(SEOUL);
		todoService.create(userId, new TodoCreateReq(
				title, null, categoryName, null, TodoType.NORMAL, today, null, null, null, null));
	}

	private TodoListReq todayReq() {
		return new TodoListReq("today", null, null, null, null, null, null);
	}

	private TodoListReq filterByCategoryToday(String categoryName) {
		return new TodoListReq("today", null, categoryName, null, null, null, null);
	}

	private TodoDetailResp singleListItem() {
		List<TodoDetailResp> items = todoService.list(userId, todayReq()).items();
		assertThat(items).hasSize(1);
		return items.get(0);
	}

	private Todo singleTodo() {
		List<Todo> all = todoRepository.findAll();
		assertThat(all).hasSize(1);
		return all.get(0);
	}
}
