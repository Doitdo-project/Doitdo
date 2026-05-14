# Shop Theme Preview Design

## 배경

상점의 기존 미리보기는 단일 가구 기준이다.

`GET /api/shop/furnitures/{furnitureId}/preview-room` 은 내 실제 방 배치를 가져온 뒤, 미리보기 대상 가구와 같은 카테고리의 기존 배치만 제외하고 대상 가구 1개를 `preview=true` 로 합성해 반환한다.

새 요구사항은 "테마 전체 미리보기"다. 사용자가 테마 카드 하나를 누르면 배경, 침대, 책상, 창문 등 같은 테마에 속한 여러 카테고리 가구가 한 번에 방에 임시 적용되어야 한다. 실제 저장은 일어나면 안 되며, 기존 단일 가구 미리보기처럼 응답 데이터만 미리보기 상태여야 한다.

## 목표

- 테마 카드 선택 시 테마 세트 전체를 저장 없이 미리보기한다.
- 테마에 포함된 카테고리만 실제 방 배치에서 임시 교체한다.
- 테마에 포함되지 않은 기존 방 가구는 그대로 유지한다.
- 응답 구조는 기존 `RoomResp.items[]` 와 `RoomFurniturePlacementResp.preview=true` 정책을 재사용한다.
- 프론트는 응답 `items[]` 를 그대로 그리면 테마 전체 미리보기를 표시할 수 있어야 한다.

## 비목표

- 테마 전체 구매/일괄 배치는 이번 설계 범위가 아니다.
- 테마별 할인, 가격 합산, 판매 기간 관리는 이번 설계 범위가 아니다.
- 실제 방 저장 API는 기존 카테고리별 단일 배치 정책을 유지한다.
- 테마가 앱 색상 라이트/다크 모드를 변경하지 않는다. 여기서의 테마는 방 가구 세트다.

## 핵심 정책

### 테마 식별

정식 구현에서는 `furniture_themes` 테이블과 `furnitures.theme_code` 컬럼을 추가한다.

예:

| furniture code | category | themeCode |
|---|---|---|
| `BACKGROUND_AUTUMN` | `BACKGROUND` | `AUTUMN` |
| `BED_AUTUMN` | `BED` | `AUTUMN` |
| `DESK_AUTUMN` | `DESK` | `AUTUMN` |
| `WINDOW_AUTUMN` | `WINDOW` | `AUTUMN` |

`furniture_themes.theme_code` 가 테마의 기준값이다.
`furnitures.theme_code` 는 해당 가구가 어느 테마에 속하는지 가리킨다.
`DEFAULT_BACKGROUND` 는 기본 배경이므로 `theme_code` 를 `NULL` 로 두고 테마 목록/테마 미리보기에서 제외한다.

### 카테고리 중복

한 테마 안에서는 같은 카테고리 가구가 2개 이상이면 안 된다.

권장 제약:

- `furnitures.theme_code` 는 nullable 허용.
- `theme_code` 가 있는 가구는 `(theme_code, category)` 조합이 유일해야 한다.

MariaDB에서 nullable unique 정책이 부담되면 DB 제약은 후속으로 미루고, 1차 구현에서는 서비스 검증으로 중복을 감지한다.

### 미리보기 합성

테마 미리보기는 아래 순서로 만든다.

1. `themeCode` 로 테마 가구 목록을 조회한다.
2. 테마 가구가 없으면 404 또는 빈 응답 중 하나를 선택한다.
   - 추천: 404 + `THEME_NOT_FOUND`
3. 내 실제 방 배치 목록을 조회한다.
4. 테마 가구의 카테고리 집합을 만든다.
5. 실제 방 배치 중 그 카테고리에 해당하는 항목은 응답에서 제외한다.
6. 나머지 실제 방 배치는 그대로 응답한다.
7. 테마 가구들을 저장 없이 `preview=true` 항목으로 추가한다.
8. `zIndex`, `placementId` 정렬 기준이 필요하면 최종 응답에서 `zIndex ASC`, `preview 후순위` 기준으로 정렬한다.

예:

- 실제 방: `DEFAULT_BACKGROUND`, `OLD_BED`, `CLOCK_A`, `PLANT_A`
- `SPRING` 테마: `SPRING_BACKGROUND`, `SPRING_BED`, `SPRING_DESK`
- 응답: `CLOCK_A`, `PLANT_A`, `SPRING_BACKGROUND(preview)`, `SPRING_BED(preview)`, `SPRING_DESK(preview)`

## API 설계

### 테마 목록 조회

`GET /api/shop/themes`

상점 화면에서 테마 카드 목록을 그릴 때 사용한다.

응답:

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "items": [
      {
        "themeCode": "SPRING",
        "themeName": "봄날의 방",
        "thumbnailUrl": "https://...",
        "furnitureCount": 4
      }
    ]
  }
}
```

테마 목록은 `furniture_themes` 기준으로 만든다.

정책:

- `is_active = true` 인 테마만 노출한다.
- 정렬은 `display_order ASC`, `theme_code ASC`.
- `thumbnailUrl` 은 `furniture_themes.thumbnail_url` 을 우선 사용한다.
- `thumbnail_url` 이 비어 있으면 같은 테마의 `BACKGROUND` 가구 `thumbnailUrl` 을 fallback 으로 사용할 수 있다.
- `furnitureCount` 는 `furnitures.theme_code = themeCode` 인 활성 가구 개수다. 현재 DB 기준 8개다.

테마명 매핑:

| themeCode | themeName |
|---|---|
| `AUTUMN` | 가을 |
| `CHERRY` | 벚꽃 |
| `CLASSIC` | 클래식 |
| `CYBER` | 사이버 |
| `DAISY` | 데이지 |
| `DESERT` | 사막 |
| `FOREST` | 숲 |
| `GOTHIC` | 고딕 |
| `HEART` | 하트 |
| `HONEY` | 허니 |
| `LAVENDER` | 라벤더 |
| `LEAF` | 잎 |
| `MAPLE` | 단풍 |
| `MARINE` | 마린 |
| `MOON` | 달빛 |
| `OCEAN` | 바다 |
| `PINE` | 소나무 |
| `RAINBOW` | 무지개 |
| `SAGE` | 세이지 |
| `SNOW` | 눈 |
| `SOLAR` | 태양 |
| `STRAWBERRY` | 딸기 |
| `VINTAGE` | 빈티지 |

### 테마 미리보기

`GET /api/shop/themes/{themeCode}/preview-room`

기존 단일 미리보기 API의 세트 버전이다. DB 저장은 하지 않는다.

응답은 기존 `RoomResp` 를 재사용한다.

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "items": [
      {
        "placementId": 12,
        "userFurnitureId": 30,
        "furnitureId": 5,
        "name": "기존 화분",
        "category": "PLANT",
        "imageUrl": "https://...",
        "width": 80,
        "height": 100,
        "zIndex": 20,
        "rotation": 0,
        "preview": false
      },
      {
        "placementId": null,
        "userFurnitureId": null,
        "furnitureId": 101,
        "name": "봄 배경",
        "category": "BACKGROUND",
        "imageUrl": "https://...",
        "width": 390,
        "height": 640,
        "zIndex": 0,
        "rotation": 0,
        "preview": true
      }
    ]
  }
}
```

### 단일 가구 미리보기와의 관계

기존 API는 유지한다.

| API | 용도 |
|---|---|
| `GET /api/shop/furnitures/{furnitureId}/preview-room` | 가구 1개 미리보기 |
| `GET /api/shop/themes/{themeCode}/preview-room` | 테마 세트 전체 미리보기 |

두 API 모두 실제 저장 없이 `RoomResp` 를 반환한다.

## 데이터 모델

### `furniture_themes`

테마 카드와 테마 미리보기의 기준 테이블이다.

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `theme_code` | `VARCHAR(30)` | PK. 예: `AUTUMN` |
| `theme_name` | `VARCHAR(50)` | 사용자 표시명. 예: `가을` |
| `thumbnail_url` | `VARCHAR(500)` | 테마 대표 이미지 |
| `display_order` | `INT` | 노출 순서 |
| `is_active` | `TINYINT(1)` | 노출 여부 |
| `created_at` | `DATETIME` | 생성 시각 |
| `updated_at` | `DATETIME` | 수정 시각 |

### `furnitures.theme_code`

`furnitures` 에 nullable `theme_code` 컬럼을 추가한다.

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `theme_code` | `VARCHAR(30)` | nullable. 소속 테마 코드 |

`DEFAULT_BACKGROUND` 같은 시스템 기본 가구는 `theme_code = NULL` 로 둔다.

권장 인덱스:

- `idx_furniture_themes_active_order (is_active, display_order)`
- `idx_furnitures_theme_code (theme_code)`
- 가능하면 `uk_furnitures_theme_category (theme_code, category)`

## 구현 영향 범위

### Backend

- `FurnitureTheme`
  - `furniture_themes` 테이블 매핑
- `Furniture`
  - `themeCode` 필드 추가
- `FurnitureThemeRepository`
  - 활성 테마 목록 조회
- `FurnitureRepository`
  - `findAllByThemeCodeAndIsDeletedFalseOrderByZIndexAscFurnitureIdAsc(String themeCode)`
  - 테마별 가구 개수 조회용 query 추가
- DTO
  - `FurnitureThemeResp`
  - `FurnitureThemeListResp`
- `ShopService`
  - `listThemes()`
  - `previewThemeRoom(Long userId, String themeCode)`
- `ShopServiceImpl`
  - 테마 가구 조회
  - 실제 방 배치와 테마 가구 합성
  - 같은 테마 내 카테고리 중복 검증
- `ShopController`
  - `GET /api/shop/themes`
  - `GET /api/shop/themes/{themeCode}/preview-room`
- Migration SQL
  - `furniture_themes` 테이블 생성
  - `furnitures.theme_code` 컬럼 추가
  - 기존 `CATEGORY_THEME` code 패턴 기반으로 `theme_code` backfill
  - 23개 테마 seed 입력

### Frontend

- 테마 카드 목록은 `GET /api/shop/themes` 로 표시한다.
- 테마 카드 미리보기 클릭 시 `GET /api/shop/themes/{themeCode}/preview-room` 호출.
- 응답 `items[]` 를 기존 `ShopRoomPreview` 렌더링 경로에 그대로 넣는다.
- 여러 미리보기 상태를 프론트에서 직접 합성하지 않아도 된다.
- 단일 가구 미리보기와 테마 미리보기는 같은 미리보기 영역을 공유한다.

## 에러 정책

새 ErrorCode가 필요하다면 `ShopErrorCode` 에 추가한다.

| 이름 | 추천 코드 | HTTP | 메시지 |
|---|---:|---:|---|
| `THEME_NOT_FOUND` | `S02-001` | 404 | 테마를 찾을 수 없음 |
| `THEME_CATEGORY_DUPLICATED` | `S02-002` | 409 | 테마에 같은 카테고리 가구가 중복됨 |

새 코드를 추가하면 `docs/api/error-codes.md` 갱신과 Swagger `@ApiErrorCodes` 반영이 필요하다.

## Swagger 문서화

`ShopController` 의 신규 API는 `shop` 그룹에 포함된다.

예상 어노테이션:

```java
@Operation(summary = "가구 테마 목록 조회", description = "상점에서 선택 가능한 가구 테마 목록을 조회한다.")
@GetMapping("/shop/themes")
public GlobalApiResponse<FurnitureThemeListResp> listThemes(...)
```

```java
@Operation(
  summary = "가구 테마 방 미리보기",
  description = "테마에 포함된 여러 가구를 내 실제 방에 저장 없이 합성해 미리보기한다. 테마에 포함된 카테고리의 기존 배치는 응답에서 제외하고, 테마 가구는 preview=true 로 포함한다."
)
@ApiErrorCodes({"S02-001", "S02-002"})
@GetMapping("/shop/themes/{themeCode}/preview-room")
public GlobalApiResponse<RoomResp> previewThemeRoom(...)
```

## 테스트 시나리오

- 테마 가구가 여러 카테고리를 포함하면 모두 `preview=true` 로 응답한다.
- 테마와 같은 카테고리의 기존 실제 배치는 응답에서 제외된다.
- 테마에 없는 카테고리의 기존 실제 배치는 유지된다.
- 테마가 존재하지 않으면 `THEME_NOT_FOUND` 를 반환한다.
- 같은 테마에 같은 카테고리 가구가 중복되면 `THEME_CATEGORY_DUPLICATED` 를 반환한다.
- 단일 가구 미리보기 API 동작은 바뀌지 않는다.
- 테마 미리보기 호출 후 DB `room_furniture_placements` row 수가 변하지 않는다.

## 프론트 전달 계약

프론트가 알아야 하는 최소 계약:

- 테마 식별자는 `themeCode`.
- 테마 카드 클릭 시 `GET /api/shop/themes/{themeCode}/preview-room` 를 호출한다.
- 응답은 기존 방 미리보기와 같은 `RoomResp.items[]`.
- `preview=true` 인 항목은 임시 배치다.
- 실제 저장은 별도 배치/구매 API로만 발생한다.
- 테마 미리보기는 기존 단일 미리보기와 동시에 유지하지 않고, 마지막으로 선택한 미리보기 결과가 방 미리보기 영역을 대체한다.

## 미정 사항

- 미보유/미판매 가구도 테마 미리보기에 포함할지.
  - 추천: 미리보기는 판매/보유 여부와 무관하게 포함.
  - 구매/배치 가능 여부는 별도 UI에서 판단.
- 테마 전체 구매/일괄 배치 기능을 후속으로 만들지 여부.
