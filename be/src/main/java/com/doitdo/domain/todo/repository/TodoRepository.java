package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TodoRepository extends JpaRepository<Todo, Long>, JpaSpecificationExecutor<Todo> {

	Optional<Todo> findByTodoIdAndIsDeletedFalse(Long todoId);

	Optional<Todo> findByUserIdAndTitleAndStartDateAndIsDeletedFalse(Long userId, String title, LocalDate startDate);

	Optional<Todo> findByUserIdAndTitleAndStartDateAndTypeAndIsDeletedFalse(
			Long userId,
			String title,
			LocalDate startDate,
			TodoType type);

	List<Todo> findAllByUserIdAndTitleAndTypeAndIsDeletedFalse(Long userId, String title, TodoType type);

	Optional<Todo> findByUserIdAndMasterTodoIdAndStartDateAndIsDeletedFalse(
			Long userId,
			Long masterTodoId,
			LocalDate startDate);

	List<Todo> findAllByUserIdAndMasterTodoIdAndIsDeletedFalse(Long userId, Long masterTodoId);

	List<Todo> findAllByUserIdAndMasterTodoIdAndStartDateGreaterThanEqual(
			Long userId,
			Long masterTodoId,
			LocalDate startDate);

	@Query("""
			SELECT t FROM Todo t
			WHERE t.userId = :userId
			  AND t.masterTodoId IN :masterTodoIds
			  AND t.startDate BETWEEN :from AND :to
			""")
	List<Todo> findRecurringInstanceMarkers(
			@Param("userId") Long userId,
			@Param("masterTodoIds") List<Long> masterTodoIds,
			@Param("from") LocalDate from,
			@Param("to") LocalDate to);

	List<Todo> findAllByTypeAndIsDeletedFalse(TodoType type);

	long countByUserIdAndFirstCompletedDate(Long userId, LocalDate firstCompletedDate);

	@Query("""
			select count(t) from Todo t
			where t.userId = :userId
			  and t.firstCompletedDate = :today
			  and t.isDeleted = false
			  and (
			      t.type = com.doitdo.domain.todo.entity.Todo.TodoType.SOMEDAY
			      or (
			          t.type = com.doitdo.domain.todo.entity.Todo.TodoType.PERIOD
			          and (
			              (t.endDate is not null and t.endDate >= :today)
			              or (t.endDate is null and t.startDate >= :today)
			          )
			      )
			      or (
			          t.type <> com.doitdo.domain.todo.entity.Todo.TodoType.SOMEDAY
			          and t.type <> com.doitdo.domain.todo.entity.Todo.TodoType.PERIOD
			          and t.startDate >= :today
			      )
			  )
			""")
	long countRewardEligibleByUserIdAndFirstCompletedDate(
			@Param("userId") Long userId,
			@Param("today") LocalDate today);

	@Query("""
			SELECT t FROM Todo t
			WHERE t.userId = :userId
			  AND t.isDeleted = false
			  AND t.type <> com.doitdo.domain.todo.entity.Todo.TodoType.SOMEDAY
			ORDER BY t.priority ASC, t.todoId ASC
			""")
	List<Todo> findReorderTargetsForNonSomeday(@Param("userId") Long userId);

	@Query("""
			SELECT COALESCE(MAX(t.priority), 0) FROM Todo t
			WHERE t.userId = :userId
			  AND t.isDeleted = false
			  AND t.type <> com.doitdo.domain.todo.entity.Todo.TodoType.SOMEDAY
			""")
	int findMaxPriorityForNonSomeday(@Param("userId") Long userId);

	@Query("""
			SELECT t FROM Todo t
			WHERE t.userId = :userId
			  AND t.isDeleted = false
			  AND t.type = com.doitdo.domain.todo.entity.Todo.TodoType.SOMEDAY
			ORDER BY t.priority ASC, t.todoId ASC
			""")
	List<Todo> findReorderTargetsForSomeday(@Param("userId") Long userId);

	@Query("""
			SELECT COALESCE(MAX(t.priority), 0) FROM Todo t
			WHERE t.userId = :userId
			  AND t.isDeleted = false
			  AND t.type = com.doitdo.domain.todo.entity.Todo.TodoType.SOMEDAY
			""")
	int findMaxPriorityForSomeday(@Param("userId") Long userId);

	@Query("""
			select count(t) from Todo t
			where t.userId = :userId
			  and t.status <> com.doitdo.domain.todo.entity.Todo.TodoStatus.DONE
			  and t.isDeleted = false
			""")
	long countPendingByUserId(@Param("userId") Long userId);

	@Query("""
			select count(t) from Todo t
			where t.userId = :userId
			  and t.status <> com.doitdo.domain.todo.entity.Todo.TodoStatus.DONE
			  and t.isDeleted = false
			  and t.type <> com.doitdo.domain.todo.entity.Todo.TodoType.RECURRING
			  and (
			      (t.type = com.doitdo.domain.todo.entity.Todo.TodoType.NORMAL and t.startDate = :today)
			      or (t.type = com.doitdo.domain.todo.entity.Todo.TodoType.PERIOD
			          and t.startDate <= :today
			          and (t.endDate is null or t.endDate >= :today))
			  )
			""")
	long countPendingByUserIdAndToday(@Param("userId") Long userId, @Param("today") LocalDate today);

	/**
	 * 카테고리 rename / 색상 변경 시 해당 카테고리를 쓰는 활성 todo 의
	 * 이름·색 스냅샷을 일괄 갱신한다 (전파).
	 */
	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("UPDATE Todo t SET t.categoryName = :name, t.categoryColorId = :colorId " +
			"WHERE t.userId = :userId AND t.categoryId = :categoryId AND t.isDeleted = false")
	int bulkUpdateCategorySnapshot(@Param("userId") Long userId,
			@Param("categoryId") Long categoryId,
			@Param("name") String name,
			@Param("colorId") Integer colorId);

	/**
	 * 카테고리 삭제 시 해당 카테고리를 쓰는 활성 todo 의 category_id 만 NULL 로 detach.
	 * 이름·색 스냅샷(category_name / category_color_id)은 그대로 잔여시킨다.
	 */
	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("UPDATE Todo t SET t.categoryId = NULL " +
			"WHERE t.userId = :userId AND t.categoryId = :categoryId AND t.isDeleted = false")
	int detachCategoryId(@Param("userId") Long userId, @Param("categoryId") Long categoryId);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("UPDATE Todo t SET t.isDeleted = true WHERE t.userId = :userId AND t.isDeleted = false")
	int softDeleteAllByUserId(@Param("userId") Long userId);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("DELETE FROM Todo t WHERE t.userId = :userId")
	int hardDeleteAllByUserId(@Param("userId") Long userId);

	/**
	 * 특정 분(HH:mm)에 알림을 발송해야 하는 TODO 목록 조회.
	 * - alertTime 이 일치하고, 완료되지 않았으며, 삭제되지 않은 row
	 * - RECURRING 마스터(type = RECURRING) 는 제외 — 인스턴스(type = NORMAL)만 포함
	 * - NORMAL: startDate = today
	 * - PERIOD: startDate <= today AND (endDate IS NULL OR endDate >= today)
	 * - RECURRING 인스턴스(NORMAL): startDate = today (createRecurringInstance 에서 NORMAL로 생성됨)
	 */
	@Query("""
			SELECT t FROM Todo t
			WHERE t.alertTime = :hhmm
			  AND t.status <> com.doitdo.domain.todo.entity.Todo.TodoStatus.DONE
			  AND t.isDeleted = false
			  AND t.type <> com.doitdo.domain.todo.entity.Todo.TodoType.RECURRING
			  AND (
			      (t.type = com.doitdo.domain.todo.entity.Todo.TodoType.NORMAL AND t.startDate = :today)
			      OR (t.type = com.doitdo.domain.todo.entity.Todo.TodoType.PERIOD
			          AND t.startDate <= :today
			          AND (t.endDate IS NULL OR t.endDate >= :today))
			  )
			""")
	List<Todo> findAlertTargets(@Param("hhmm") String hhmm, @Param("today") LocalDate today);
}
