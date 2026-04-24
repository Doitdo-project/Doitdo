package com.doitdo.domain.tamagotchi.application;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ExpCalculatorTest {

	private final ExpCalculator calculator = new ExpCalculator();

	@Test
	void rollTodoDoneExpAlwaysReturnsValueBetween3And7() {
		for (int i = 0; i < 1000; i++) {
			int result = calculator.rollTodoDoneExp();
			assertThat(result)
					.isGreaterThanOrEqualTo(3)
					.isLessThanOrEqualTo(7);
		}
	}
}
