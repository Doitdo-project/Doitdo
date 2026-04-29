package com.doitdo.domain.tamagotchi.application.listener;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.tamagotchi.application.ExpCalculator;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TodoCompletionExpListenerTest {

	@Mock
	private TodoRepository todoRepository;

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Mock
	private CharacterRepository characterRepository;

	@Mock
	private ExpCalculator expCalculator;

	private TodoCompletionExpListener listener;

	@BeforeEach
	void setUp() {
		listener = new TodoCompletionExpListener(
				todoRepository, userCharacterRepository, characterRepository, expCalculator);
	}

	private Todo buildTodo(Long todoId, boolean expGranted) {
		return Todo.builder()
				.userId(1L)
				.categoryId(null)
				.title("test")
				.content(null)
				.type(Todo.TodoType.NORMAL)
				.status(Todo.TodoStatus.DONE)
				.priority(1)
				.startDate(LocalDate.now())
				.endDate(null)
				.isDeleted(false)
				.expGranted(expGranted)
				.build();
	}

	private UserCharacter buildUc(int currentExp) {
		return UserCharacter.builder()
				.userCharacterId(10L)
				.userId(1L)
				.characterId(2L)
				.name("뚜잇이")
				.currentExp(currentExp)
				.isActive(true)
				.isDeleted(false)
				.build();
	}

	private Character buildCharacter(Integer requiredExp) {
		return buildCharacter(requiredExp, Character.Stage.BABY);
	}

	private Character buildCharacter(Integer requiredExp, Character.Stage stage) {
		return Character.builder()
				.characterId(2L)
				.species("SLIME")
				.stage(stage)
				.requiredExp(requiredExp)
				.thumbnailUrl("https://cdn.example.com/slime.png")
				.build();
	}

	@Test
	void grantsExpOnFirstDoneTransition() {
		// 최초 DONE 전이 → exp 지급 + expGranted=true
		Todo todo = buildTodo(1L, false);
		UserCharacter uc = buildUc(0);
		Character character = buildCharacter(100);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L))
				.willReturn(Optional.of(uc));
		given(characterRepository.findById(2L)).willReturn(Optional.of(character));
		given(expCalculator.rollTodoDoneExp()).willReturn(5);

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		assertThat(uc.getCurrentExp()).isEqualTo(5);
		assertThat(todo.getExpGranted()).isTrue();
	}

	@Test
	void skipsWhenAlreadyGranted() {
		// expGranted=true → skip, currentExp 변화 없음
		Todo todo = buildTodo(1L, true);
		UserCharacter uc = buildUc(50);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		assertThat(uc.getCurrentExp()).isEqualTo(50);
		verify(userCharacterRepository, never()).findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L);
	}

	@Test
	void skipsWhenNoActiveUserCharacter() {
		// UserCharacter 없음 → 예외 없이 skip
		Todo todo = buildTodo(1L, false);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L))
				.willReturn(Optional.empty());

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		assertThat(todo.getExpGranted()).isFalse();
	}

	@Test
	void marksGrantedButSkipsExpWhenRequiredExpIsNull() {
		// Character.requiredExp == null → expGranted 만 마킹, exp 변화 없음
		Todo todo = buildTodo(1L, false);
		UserCharacter uc = buildUc(0);
		Character character = buildCharacter(null);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L))
				.willReturn(Optional.of(uc));
		given(characterRepository.findById(2L)).willReturn(Optional.of(character));

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		assertThat(uc.getCurrentExp()).isEqualTo(0);
		assertThat(todo.getExpGranted()).isTrue();
	}

	@Test
	void capsCurrentExpAtRequiredExp() {
		// Cap 동작: currentExp=95, delta=7, cap=100 → currentExp=100 (5만 가산)
		Todo todo = buildTodo(1L, false);
		UserCharacter uc = buildUc(95);
		Character character = buildCharacter(100);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L))
				.willReturn(Optional.of(uc));
		given(characterRepository.findById(2L)).willReturn(Optional.of(character));
		given(expCalculator.rollTodoDoneExp()).willReturn(7);

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		assertThat(uc.getCurrentExp()).isEqualTo(100);
		assertThat(todo.getExpGranted()).isTrue();
	}

	@Test
	void schedulesFarewellWhenAdultReachesCapTransition() {
		Todo todo = buildTodo(1L, false);
		UserCharacter uc = buildUc(95);
		Character character = buildCharacter(100, Character.Stage.ADULT);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L))
				.willReturn(Optional.of(uc));
		given(characterRepository.findById(2L)).willReturn(Optional.of(character));
		given(expCalculator.rollTodoDoneExp()).willReturn(7);

		LocalDateTime before = LocalDateTime.now();
		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));
		LocalDateTime after = LocalDateTime.now();

		assertThat(uc.getCurrentExp()).isEqualTo(100);
		assertThat(uc.getFarewellAvailableAt())
				.isBetween(before, after);
		assertThat(todo.getExpGranted()).isTrue();
	}

	@Test
	void doesNotRescheduleWhenAdultWasAlreadyAtCap() {
		Todo todo = buildTodo(1L, false);
		LocalDateTime scheduledAt = LocalDateTime.now().plusHours(72);
		UserCharacter uc = UserCharacter.builder()
				.userCharacterId(10L)
				.userId(1L)
				.characterId(2L)
				.name("뚜잇이")
				.currentExp(100)
				.isActive(true)
				.isDeleted(false)
				.farewellAvailableAt(scheduledAt)
				.build();
		Character character = buildCharacter(100, Character.Stage.ADULT);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L))
				.willReturn(Optional.of(uc));
		given(characterRepository.findById(2L)).willReturn(Optional.of(character));
		given(expCalculator.rollTodoDoneExp()).willReturn(7);

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		assertThat(uc.getCurrentExp()).isEqualTo(100);
		assertThat(uc.getFarewellAvailableAt()).isEqualTo(scheduledAt);
		assertThat(todo.getExpGranted()).isTrue();
	}

	@ParameterizedTest
	@EnumSource(value = Character.Stage.class, names = {"BABY", "TEEN"})
	void doesNotScheduleFarewellWhenNonAdultReachesCap(Character.Stage stage) {
		Todo todo = buildTodo(1L, false);
		UserCharacter uc = buildUc(95);
		Character character = buildCharacter(100, stage);

		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(1L))
				.willReturn(Optional.of(uc));
		given(characterRepository.findById(2L)).willReturn(Optional.of(character));
		given(expCalculator.rollTodoDoneExp()).willReturn(7);

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		assertThat(uc.getCurrentExp()).isEqualTo(100);
		assertThat(uc.getFarewellAvailableAt()).isNull();
		assertThat(todo.getExpGranted()).isTrue();
	}
}
