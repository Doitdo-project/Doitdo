package com.doitdo.domain.tamagotchi.application;

import java.util.Random;
import org.springframework.stereotype.Component;

/**
 * TODO 완료 시 지급 exp 양을 결정하는 컴포넌트.
 * 단순하지만 별도 클래스로 분리해 테스트에서 Random 주입 가능하게 한다.
 */
@Component
public class ExpCalculator {

	private final Random random = new Random();

	/**
	 * TODO 1건 완료당 지급 exp (3~7 inclusive).
	 * 현재는 단계별 차등 없음 — 단계별 차등은 Character.requiredExp 값으로만 조정.
	 */
	public int rollTodoDoneExp() {
		return 3 + random.nextInt(5); // 3, 4, 5, 6, 7
	}
}
