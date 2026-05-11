# AnimationAction enum 전환 설계

## 배경

현재 다마고치 캐릭터 액션 타입은 문자열로 관리된다.

- `src/main/java/com/doitdo/domain/tamagotchi/entity/CharacterAction.java:33` — `action_type VARCHAR(50)` 컬럼에 `String actionType` 매핑.
- `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java:471` — `"EYE".equalsIgnoreCase(actionType)` 분기로 적립 평가 제외.
- `docs/ops/migrations/2026-04-mvp-character-seed.sql:37` — `character_actions` 시드는 현재 `EYE`, `IDLE` row 만 투입.
- 갱신 전 뚜레딧 적립 설계는 `actionType != EYE` 블랙리스트 방식이었다.

문자열 기반 정책은 오타, 대소문자 차이, FE/BE 액션 목록 불일치를 런타임까지 늦게 발견한다. 액션 타입을 Java enum 으로 고정하면 API 입력, JPA 필드, 서비스 분기, 테스트 데이터가 같은 값 집합을 공유하므로 정합성과 타입 안전성이 올라간다.

## 목표

- `AnimationAction` enum 을 도입해 액션 타입을 6개 값으로 고정한다.
- 적립 정책을 블랙리스트에서 화이트리스트로 바꾼다. 즉, 유효한 enum 액션 호출은 모두 같은 적립 흐름에 진입한다.
- DB 스키마는 유지한다. `character_actions.action_type` 은 계속 `VARCHAR(50)` 이며 Java/JPA 매핑만 enum 으로 바꾼다.
- 이번 PR 은 docs 전용이다. 코드, DB 마이그레이션, 시드, 테스트 변경은 후속 PR 에서 처리한다.

## enum 정의

Java enum 이름: `AnimationAction`

| 값 | 의미 | 트리거 시나리오 추정 |
|---|---|---|
| `EYE` | 눈 깜빡임/시선 변화 | 자동 idle 보조 애니메이션 또는 FE 명시 호출 |
| `IDLE` | 기본 대기 | 캐릭터 탭, 기본 상호작용 |
| `WALK` | 걷기/이동 | 산책, 화면 내 이동, 활동성 표현 |
| `SLEEP` | 수면 | 야간 상태, 휴식 상태, 사용자가 재우기 선택 |
| `HAPPY` | 기쁨 | TODO 완료, 보상 수령, 긍정 피드백 |
| `SAD` | 슬픔 | 실패/거절 피드백, 케어 부족 상태 |

위 6개 값은 모두 단수형 대문자다. `EAT`, `HAPPYS`, `WALKS` 같은 임의 문자열은 enum 에 포함하지 않는다. 트리거 시나리오는 FE/기획 합의 전까지 추정이며, API 계약에는 값 목록만 확정으로 둔다.

## 적립 정책 변경

기존 정책은 `EYE` 만 제외하고 나머지를 적립 대상으로 보는 블랙리스트였다. 새 정책은 `AnimationAction` enum 에 포함된 액션 호출을 모두 적립 대상으로 보는 화이트리스트다.

변경 후 흐름:

1. `GET /api/characters/me/actions/{actionType}` 에서 `actionType` 을 `AnimationAction` 으로 바인딩한다.
2. enum 에 없는 값은 컨트롤러 바인딩 단계에서 400 으로 거절한다.
3. enum 에 있는 값이면 활성 캐릭터의 `character_actions` row 를 조회한다.
4. 해당 캐릭터에 그 액션 row 가 없으면 404 `M09-002` 를 반환한다.
5. row 가 있으면 `actionUrl` 을 반환하고, 모든 enum 액션이 동일하게 `PET_TOUCH` 적립 평가에 진입한다.
6. 쿨다운, 일일 횟수, 일일 합산 cap 에 걸리면 응답은 성공이며 `earnedAmount=0` 으로 적립만 skip 한다.

영향:

- `EYE` 를 BE 로 호출하면 더 이상 적립 제외가 아니다. FE 가 `EYE` 를 로컬 전용으로 유지하면 실제 사용자 흐름 변화는 없다.
- 향후 `WALK`, `SLEEP`, `HAPPY`, `SAD` 를 추가해도 별도 서비스 분기 없이 같은 적립 정책을 탄다.
- enum 에 값을 추가하는 것만으로는 API 가 완성되지 않는다. 각 캐릭터/성장 단계별 `character_actions` row 와 S3 GIF 가 함께 준비되어야 한다.

## Spring 바인딩 정책

컨트롤러 시그니처는 후속 PR 에서 `@PathVariable AnimationAction actionType` 으로 바꾼다.

권고: canonical API 값은 대문자로 문서화하되, BE 에 `Converter<String, AnimationAction>` 를 추가해 `toUpperCase(Locale.ROOT)` 로 관대 수용한다.

| 선택지 | 장점 | 단점 |
|---|---|---|
| Spring 기본 enum 바인딩 | 코드가 가장 적고 대문자 계약을 강제한다 | `idle` 같은 대소문자 차이도 400 이며, 모바일 배포 순서 이슈에 취약하다 |
| `Converter<String, AnimationAction>` | `idle`, `Idle` 을 `IDLE` 로 수용해 FE 배포/레거시 클라이언트 리스크를 줄인다 | 변환 코드와 바인딩 실패 테스트가 필요하고, 문서에는 canonical 값이 대문자임을 계속 명시해야 한다 |

converter 를 쓰더라도 enum 에 없는 값은 수용하지 않는다. 실패 응답은 전역 예외 처리 정책에 맞춰 400 으로 정리하고, `@WebMvcTest` 또는 컨트롤러 테스트에서 `idle` 수용과 `unknown` 거절을 함께 검증한다.

## JPA 매핑

`CharacterAction.actionType` 은 후속 PR 에서 아래 형태로 바꾼다.

```java
@Enumerated(EnumType.STRING)
@Column(name = "action_type", nullable = false, length = 50)
private AnimationAction actionType;
```

`EnumType.ORDINAL` 은 금지한다. enum 선언 순서가 바뀌면 DB 의미가 깨지기 때문이다. `EnumType.STRING` 은 기존 `VARCHAR(50)` 스키마와 호환되므로 DB 컬럼 변경은 필요 없다.

Repository 도 `findAllByCharacterIdAndActionType(Long characterId, AnimationAction actionType)` 처럼 enum 타입을 받도록 바꾼다.

## 미등록 액션 404 정책

에러 코드는 기존 `TamagotchiErrorCode.M09_002` (`M09-002`, 404, "해당 캐릭터의 요청 액션을 찾을 수 없음") 를 재사용한다.

이유:

- 현재 `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java:463` 에서 `character_actions` 조회 결과가 비어 있으면 이미 `M09_002` 를 던진다.
- 새 정책의 "enum 에는 있지만 DB row 가 없는 액션" 은 같은 의미다.
- 신규 `CHARACTER_ACTION_NOT_REGISTERED` 를 만들면 의미가 중복되고 FE 에러 처리 분기가 늘어난다.

구분:

| 상황 | 응답 |
|---|---|
| enum 에 없는 `actionType` | 400 바인딩 실패 |
| enum 에 있지만 활성 캐릭터의 `character_actions` row 없음 | 404 `M09-002` |
| row 는 있으나 쿨다운/cap 으로 적립 불가 | 200, `earnedAmount=0` |

## DB/시드 정책

이번 결정은 DB 스키마를 바꾸지 않는다. `action_type` 컬럼은 계속 `VARCHAR(50)` 이다.

현재 시드는 `EYE`, `IDLE` 만 있으므로 마이그레이션 UPDATE 는 불필요하다. `EYE` 는 이미 단수형이며 enum 값과 일치한다.

`WALK`, `SLEEP`, `HAPPY`, `SAD` row INSERT 와 S3 GIF 업로드는 별도 PR 에서 처리한다. 해당 PR 전에는 enum 값이 있더라도 row 가 없으므로 호출 시 404 `M09-002` 가 정상이다.

## 후속 PR 분리

### 1. enum 도입 + 코드 분기 제거 + 테스트

- `AnimationAction` enum 생성.
- `CharacterAction.actionType` 을 `String` 에서 enum 으로 변경.
- Controller/Service/Repository 시그니처를 enum 기반으로 변경.
- `"EYE".equalsIgnoreCase(actionType)` 적립 제외 분기 삭제.
- 모든 enum 액션이 동일한 적립 흐름에 진입하는 테스트 추가.
- enum 바인딩 대소문자 정책 테스트 추가.
- `M09_002` 재사용 경로 테스트 추가.

### 2. S3 GIF + 시드 추가

- `WALK`, `SLEEP`, `HAPPY`, `SAD` GIF 를 캐릭터/성장 단계별 S3 경로에 업로드.
- `docs/ops/migrations/**` 에 신규 INSERT SQL 추가.
- 기존 `EYE`, `IDLE` 값 UPDATE 는 하지 않는다.
- 운영 투입 전 캐릭터/성장 단계별 누락 row 점검 쿼리 포함.

### 3. FE 합의 + 배포 순서

- FE 는 canonical `actionType` 을 대문자로 송신한다.
- BE converter 도입 시 FE 대소문자 실수는 흡수하지만, 문서와 타입 정의는 대문자 enum 을 기준으로 한다.
- BE enum 코드 배포 후 신규 시드/S3 투입, 그 다음 FE 에서 신규 액션 호출을 활성화한다.
- FE 가 신규 액션을 먼저 호출하면 404 `M09-002` 가 발생하므로 feature flag 또는 앱 버전 게이트를 둔다.

## docs 동시 갱신 매트릭스

`CLAUDE.md` 의 docs 동시 갱신 규칙에 따라 본 plan 머지 후 영향 문서를 같이 정리한다.

| 변경 영역 | 영향 문서 | 이번 PR 처리 | 후속 PR 처리 |
|---|---|---|---|
| 다마고치 적립 정책 | `docs/plans/2026-05-07-doredit-earning-system-design.md` | 블랙리스트 문구 제거, 모든 enum 액션 적립으로 갱신 | 구현 완료 후 실제 코드 흐름과 재검증 |
| 응답 포맷 | `docs/api/response-format.md` | `EYE` 적립 제외 문구 제거, 미등록 액션 404 명시 | DTO 필드 확정 시 예시 응답 보강 |
| 에러 코드 | `docs/api/error-codes.md` | `M09_002` 재사용 정책 명시 | 신규 코드가 필요해지는 경우 노션 SSOT 확인 후 추가 |
| API 명세 SSOT | 노션 API 명세서 | 노션 갱신 필요 | FE 합의 후 actionType enum 값, 대소문자 정책, 404 정책 반영 |
| DB/운영 | `docs/ops/migrations/**`, ERD 문서 | 이번 PR 에서 변경 없음 | 신규 시드 INSERT PR 에서 갱신 |
