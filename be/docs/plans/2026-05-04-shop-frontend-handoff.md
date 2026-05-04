# Shop Frontend Handoff

## 화면 개념

상점 화면은 "상점 + 인벤토리 + 내 방 미리보기" 통합 화면이다.

화면은 크게 두 영역으로 본다.

- 아이템 목록: 전체 가구를 보여주고 구매/배치/배치중 상태를 표시한다.
- 방 도화지: 현재 내 방에 실제 배치된 가구를 렌더링한다.

## 상점 진입 시 호출

상점 화면에 처음 들어오면 아래 2개 API를 호출한다.

### 1. 아이템 목록

`GET /api/shop/furnitures`

Query:

| 이름 | 필수 | 설명 |
|---|---|---|
| `category` | N | 특정 카테고리만 볼 때 사용 |

응답의 `items[]` 로 아이템 리스트를 그린다.

주요 필드:

| 필드 | 설명 |
|---|---|
| `furnitureId` | 가구 ID |
| `name` | 화면에 표시할 이름 |
| `category` | 카테고리. 같은 카테고리는 방에 1개만 배치 가능 |
| `price` | 미보유 상태에서 표시할 가격 |
| `thumbnailUrl` | 목록 썸네일 |
| `imageUrl` | 미리보기/방 렌더링 이미지 |
| `owned` | 보유 여부 |
| `placed` | 현재 방에 배치 중인지 |
| `status` | 화면 버튼 상태 |

`status` 값:

| status | 의미 | 목록 표시 | 버튼 |
|---|---|---|---|
| `PURCHASABLE` | 미보유 | 가격 표시 | 구매 |
| `PLACEABLE` | 보유 중 + 미배치 | 보유중 표시 | 배치 |
| `PLACED` | 보유 중 + 배치중 | 보유중 표시 | 배치중 |

FE 표시 규칙:

```text
if status == PURCHASABLE:
  subText = price
  action = "구매"

if status == PLACEABLE:
  subText = "보유중"
  action = "배치"

if status == PLACED:
  subText = "보유중"
  action = "배치중"
```

### 2. 실제 내 방

`GET /api/users/me/room`

상점 화면의 방 도화지에 실제 배치된 가구를 렌더링한다.

응답의 `items[]` 주요 필드:

| 필드 | 설명 |
|---|---|
| `placementId` | 실제 배치 ID |
| `userFurnitureId` | 내가 보유한 가구 ID |
| `furnitureId` | 가구 마스터 ID |
| `name` | 가구 이름 |
| `category` | 가구 카테고리 |
| `imageUrl` | 렌더링 이미지 |
| `x` | 배치 x 좌표 |
| `y` | 배치 y 좌표 |
| `width` | 렌더링 너비 |
| `height` | 렌더링 높이 |
| `zIndex` | 레이어 순서 |
| `rotation` | 회전값 |
| `preview` | 실제 방 조회에서는 항상 `false` |

정렬은 서버에서 `zIndex ASC`, `placementId ASC` 로 내려준다.

## 미리보기 흐름

아이템을 눌러 방에서 미리보기할 때 호출한다.

`GET /api/shop/furnitures/{furnitureId}/preview-room`

동작:

- 내 실제 방 배치를 기반으로 응답한다.
- 미리보기 대상과 같은 `category` 의 기존 배치 가구는 응답에서 제외한다.
- 미리보기 대상 가구를 기본 좌표로 응답에 추가한다.
- DB에는 저장하지 않는다.
- 미리보기 대상 항목은 `preview=true` 다.

예시:

```text
현재 방:
- 침대 BED
- 기존 시계 CLOCK

새 시계 CLOCK 미리보기:
- 침대 BED 유지
- 기존 시계 CLOCK 제외
- 새 시계 CLOCK preview=true 로 추가
```

FE 처리:

- 미리보기 상태에서는 도화지 데이터를 `GET /api/users/me/room` 응답 대신 `preview-room` 응답으로 교체해서 렌더링한다.
- 사용자가 미리보기를 취소하면 다시 실제 방 데이터를 보여준다.
- 실제 저장은 `POST /placements` 호출 전까지 발생하지 않는다.

## 구매 흐름

미보유 아이템의 구매 버튼을 누를 때 호출한다.

`POST /api/shop/furnitures/{furnitureId}/purchase`

성공 후 권장 처리:

1. `GET /api/shop/furnitures` 재조회
2. 아이템 상태가 `PURCHASABLE` 에서 `PLACEABLE` 로 바뀌었는지 반영

주요 실패:

| code | 의미 |
|---|---|
| `S00-001` | 가구 없음 |
| `S00-002` | 이미 보유 |
| `S00-003` | 잔액 부족 |
| `S00-004` | 판매 중 아님 |
| `S00-005` | 월렛 없음 |

## 배치 흐름

보유 중이지만 미배치인 아이템의 배치 버튼을 누를 때 호출한다.

`POST /api/users/me/room/furnitures/{userFurnitureId}/placements`

동작:

- 보유 가구만 배치 가능하다.
- 방에는 카테고리별 1개만 배치된다.
- 같은 카테고리의 다른 가구가 이미 있으면 서버가 기존 배치를 자동 제거하고 새 가구를 배치한다.
- `UserFurniture` 는 삭제하지 않는다.
- 삭제/교체되는 것은 `RoomFurniturePlacement` 뿐이다.

성공 후 권장 처리:

1. `GET /api/shop/furnitures` 재조회
2. `GET /api/users/me/room` 재조회
3. 목록의 상태와 도화지 렌더링을 실제 DB 상태로 동기화

같은 가구가 이미 `PLACED` 상태에서 다시 배치 요청되면 기존 placement 를 그대로 반환한다.

## 배치 수정 흐름

현재는 위치 수정 API가 있다.

`PATCH /api/users/me/room/placements/{placementId}`

Request:

```json
{
  "x": 120,
  "y": 300,
  "zIndex": 10,
  "rotation": 0
}
```

성공하면 수정된 배치 정보를 반환한다.

## 배치 제거 흐름

방에서 가구를 빼는 버튼이 필요하면 호출한다.

`DELETE /api/users/me/room/placements/{placementId}`

동작:

- `RoomFurniturePlacement` 만 삭제한다.
- 보유 가구인 `UserFurniture` 는 유지한다.

성공 후 권장 처리:

1. `GET /api/shop/furnitures` 재조회
2. `GET /api/users/me/room` 재조회

## 전체 화면 시나리오

### 상점 진입

```text
GET /api/shop/furnitures
GET /api/users/me/room
```

결과:

- 목록은 `status` 로 구매/배치/배치중 버튼을 그린다.
- 도화지는 `room.items[]` 로 실제 방을 그린다.

### 미보유 가구 구매

```text
POST /api/shop/furnitures/{furnitureId}/purchase
GET /api/shop/furnitures
```

결과:

- 해당 가구가 `PURCHASABLE` 에서 `PLACEABLE` 로 바뀐다.

### 보유 가구 미리보기

```text
GET /api/shop/furnitures/{furnitureId}/preview-room
```

결과:

- 같은 카테고리 기존 가구가 빠진 미리보기 방을 보여준다.
- `preview=true` 항목이 미리보기 대상이다.

### 보유 가구 배치 확정

```text
POST /api/users/me/room/furnitures/{userFurnitureId}/placements
GET /api/shop/furnitures
GET /api/users/me/room
```

결과:

- 같은 카테고리 기존 배치가 있으면 자동 교체된다.
- 새 가구 상태는 `PLACED` 가 된다.
- 기존 같은 카테고리 가구는 보유 상태면 `PLACEABLE` 이 된다.

## 주의사항

- FE에서 같은 카테고리 교체 로직을 직접 계산하지 않아도 된다. 서버가 처리한다.
- 미리보기는 저장이 아니다.
- 실제 방 상태는 항상 `GET /api/users/me/room` 이 기준이다.
- 목록 상태는 항상 `GET /api/shop/furnitures` 의 `status` 를 기준으로 표시한다.
