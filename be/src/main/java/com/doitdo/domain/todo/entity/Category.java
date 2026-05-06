package com.doitdo.domain.todo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
		name = "categories",
		indexes = {
				@Index(name = "idx_categories_user_name", columnList = "user_id, category_name")
		}
)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Category {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "category_id")
	private Long categoryId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "color_id", nullable = false)
	private Integer colorId;

	@Column(name = "category_name", length = 10)
	private String categoryName;

	// ── 정적 팩토리 ────────────────────────────────────────────────────

	/**
	 * 새 카테고리를 생성한다.
	 * 노션 API 문서의 body 필드명은 "color" 이지만 엔티티 컬럼명(colorId)에 맞춰 Integer 로 받는다.
	 */
	public static Category create(Long userId, String categoryName, Integer colorId) {
		return Category.builder()
				.userId(userId)
				.categoryName(categoryName)
				.colorId(colorId)
				.build();
	}

	// ── 부분 수정 ───────────────────────────────────────────────────────

	public void update(String categoryName, Integer colorId) {
		if (categoryName != null) {
			this.categoryName = categoryName;
		}
		if (colorId != null) {
			this.colorId = colorId;
		}
	}
}
