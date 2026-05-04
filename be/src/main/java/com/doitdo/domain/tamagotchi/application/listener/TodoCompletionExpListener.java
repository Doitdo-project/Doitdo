package com.doitdo.domain.tamagotchi.application.listener;

import com.doitdo.domain.tamagotchi.application.ExpCalculator;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.global.cache.CacheEvictHelper;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * TODO DONE 전이 이벤트를 구독해 UserCharacter 에 exp 를 가산하는 리스너.
 *
 * <p>설계 포인트:
 * <ul>
 *   <li>{@code AFTER_COMMIT}: Todo 저장이 커밋된 뒤에만 발동 → Todo 가 롤백되면 exp 도 지급 안 됨</li>
 *   <li>{@code REQUIRES_NEW}: exp 가산·마킹을 별도 TX 로 격리 → exp 로직이 실패해도 Todo 상태에 영향 없음</li>
 *   <li>멱등성: {@link Todo#getExpGranted()} 체크로 같은 Todo 중복 지급 차단</li>
 *   <li>활성 UC 없음: 회원가입 직후 등 공백 구간에선 조용히 skip (경험치 누락).
 *       BE 가 signup 에서 자동 EGG 생성하므로 실제로는 거의 발생 안 함.</li>
 *   <li>과거 Todo 스킵: 기준일(NORMAL/RECURRING → startDate, PERIOD → endDate 우선)이
 *       오늘(KST) 이전이면 경험치 지급 없이 skip. SOMEDAY 는 날짜 무관 지급.</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TodoCompletionExpListener {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	private final TodoRepository todoRepository;
	private final UserCharacterRepository userCharacterRepository;
	private final CharacterRepository characterRepository;
	private final ExpCalculator expCalculator;
	private final CacheEvictHelper cacheEvictHelper;

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void onTodoCompleted(TodoCompletedEvent event) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(event.todoId())
				.orElse(null);
		if (todo == null) {
			log.debug("[exp] todo not found; skipped todoId={}", event.todoId());
			return;
		}
		if (Boolean.TRUE.equals(todo.getExpGranted())) {
			log.debug("[exp] already granted; skipped todoId={}", event.todoId());
			return;
		}

		// 과거 Todo 경험치 제외 정책 (S14P31D107-475)
		// SOMEDAY: criteriaDate=null → 가드 통과 (날짜 무관 지급)
		// PERIOD: endDate 있으면 endDate, 없으면 startDate 기준
		// NORMAL 등 그 외: startDate 기준
		LocalDate criteriaDate = switch (todo.getType()) {
			case SOMEDAY -> null;
			case PERIOD -> todo.getEndDate() != null ? todo.getEndDate() : todo.getStartDate();
			default -> todo.getStartDate();
		};
		LocalDate today = LocalDate.now(SEOUL);
		if (criteriaDate != null && criteriaDate.isBefore(today)) {
			log.debug("[exp] past todo; skipped todoId={} criteriaDate={} today={}",
					event.todoId(), criteriaDate, today);
			return;
		}

		UserCharacter uc = userCharacterRepository
				.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(event.userId())
				.orElse(null);
		if (uc == null) {
			log.debug("[exp] no active UC; skipped user={}", event.userId());
			return;
		}

		Character character = characterRepository.findById(uc.getCharacterId())
				.orElse(null);
		if (character == null) {
			log.warn("[exp] character row missing for UC {}", uc.getUserCharacterId());
			return;
		}
		Integer requiredExp = character.getRequiredExp();
		if (requiredExp == null || requiredExp <= 0) {
			// EGG (requiredExp=0) 또는 마이그레이션 미완료 row → exp 누적 불가. 마킹만.
			todo.markExpGranted();
			return;
		}

		int delta = expCalculator.rollTodoDoneExp();
		int before = uc.getCurrentExp();
		uc.gainExp(delta, requiredExp);
		int after = uc.getCurrentExp();
		if (character.getStage() == Character.Stage.ADULT
				&& before < requiredExp
				&& after >= requiredExp
				&& uc.getFarewellAvailableAt() == null) {
			uc.scheduleFarewell(LocalDateTime.now());
		}
		todo.markExpGranted();
		cacheEvictHelper.evictTamagotchiCurrentAfterCommit(event.userId());
		log.debug("[exp] granted delta={} user={} todo={} currentExp={}",
				delta, event.userId(), event.todoId(), uc.getCurrentExp());
	}
}
