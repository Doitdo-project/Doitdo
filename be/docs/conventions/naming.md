# 네이밍 / 엔티티 규칙

노션 BE Convention: <https://www.notion.so/3458ab5fe9a980b7a026f4652db8b2c8>

## 1. 컴포넌트 네이밍

| 컴포넌트 | 규칙 | 예 |
|---|---|---|
| Controller | `{Domain}Controller` | `AuthController` |
| Service (interface) | `{Domain}Service` | `AuthService` |
| Service (impl) | `{Domain}ServiceImpl` (위치: `application/impl/`) | `AuthServiceImpl` |
| Repository | `{Domain}Repository` | `AuthRepository` |
| Entity | `{Domain}` (테이블명 단수형) | `Todo` |
| Request DTO | `{Action}{Domain}Req` | `LoginReq`, `CreateTodoReq` |
| Response DTO | `{Domain}Resp` | `TodoResp` |

5종 디렉토리 패턴은 [`../architecture/package-layout.md`](../architecture/package-layout.md).

## 2. 엔티티 규칙

```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Entity
@Table(name = "todos")
public class Todo extends BaseTimeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;   // FK는 Long ID 필드 (도메인 격리)
    // ...
}
```

핵심:

- Lombok: `@Getter`, `@NoArgsConstructor(access = PROTECTED)`, `@Builder`, `@AllArgsConstructor(access = PRIVATE)`.
- 생성/수정 시각이 둘 다 있는 엔티티는 `BaseTimeEntity` 상속 (`global/entity/BaseTimeEntity.java`).
- `@EnableJpaAuditing` 은 `global/config/JpaAuditingConfig` 에서 활성화 (개별 엔티티에서 추가 어노테이션 불필요).
- **FK는 `@ManyToOne` 미사용 원칙.** 도메인 격리 위해 Long ID 필드로만 보관.

## 3. 코드 포맷

- IntelliJ Code Style: 프로젝트 제공 `code-style.xml` import.
- 단축키: `Ctrl+Alt+L` (포맷), `Ctrl+Alt+O` (import 정리).
- `Settings → Tools → Actions on Save` 에서 저장 시 자동 포맷 권장.

## 4. 응답 / 에러 코드 명명

- 응답 객체 사양: [`../api/response-format.md`](../api/response-format.md).
- 에러 코드 enum 명명/접두 letter: [`../api/error-codes.md`](../api/error-codes.md).
