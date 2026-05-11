# Shop Frontend Handoff

## 화면 개념

상점 화면은 "상점 + 인벤토리 + 내 방 미리보기" 통합 화면이다.

화면은 크게 두 영역으로 본다.

- 아이템 목록: 전체 가구를 보여주고 구매/배치/배치중 상태를 표시한다.
- 방 도화지: 현재 내 방에 실제 배치된 가구를 렌더링한다.

## 상점 진입 시 호출

상점 화면에 처음 들어오면 아래 1개 API를 호출한다.

### 통합 진입 데이터

`GET /api/shop/entry`

Query:

| 이름 | 필수 | 설명 |
|---|---|---|
| `category` | N | 아이템 목록을 특정 카테고리로 제한할 때 사용 |

응답:

| 필드 | 설명 |
|---|---|
| `furnitures` | 상점/인벤토리 아이템 목록. `GET /api/shop/furnitures` 와 같은 구조 |
| `room` | 실제 내 방 배치 목록. `GET /api/users/me/room` 과 같은 구조 |

FE는 상점 진입 시 이 API 하나로 아이템 목록과 방 도화지를 동시에 렌더링한다.

아래 2개 API는 개별 재조회가 필요할 때 사용할 수 있다.

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
- 미리보기 대상 가구를 `preview=true` 로 응답에 추가한다.
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
GET /api/shop/entry
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

## API별 상세 흐름

현재 shop/room 관련 API는 총 9개다.

### 1. 상점 진입 데이터 조회

`GET /api/shop/entry`

흐름:

1. `category` query 를 받는다.
2. `GET /api/shop/furnitures` 와 같은 가구 목록 데이터를 만든다.
3. `GET /api/users/me/room` 과 같은 실제 방 배치 데이터를 만든다.
4. `furnitures`, `room` 을 한 응답으로 묶어 반환한다.

### 2. 상점/인벤토리 목록

`GET /api/shop/furnitures`

흐름:

1. `category` query 가 없으면 전체 가구를 조회한다.
2. `category` query 가 있으면 해당 카테고리 가구만 조회한다.
3. 내 보유 가구 ID 목록을 조회한다.
4. 내 방 배치 목록을 조회한다.
5. 배치된 `userFurnitureId` 를 실제 `furnitureId` 로 변환한다.
6. 각 가구별 상태를 계산한다.
   - 미보유: `owned=false`, `placed=false`, `status=PURCHASABLE`
   - 보유+미배치: `owned=true`, `placed=false`, `status=PLACEABLE`
   - 보유+배치중: `owned=true`, `placed=true`, `status=PLACED`
7. 응답한다.

### 3. 가구 구매

`POST /api/shop/furnitures/{furnitureId}/purchase`

흐름:

1. 가구를 조회한다.
2. 없으면 `S00-001`.
3. 판매 중이 아니면 `S00-004`.
4. 이미 보유했으면 `S00-002`.
5. 월렛을 비관적 락으로 조회한다.
6. 월렛이 없으면 `S00-005`.
7. 잔액 부족이면 `S00-003`.
8. 잔액을 차감한다.
9. `UserFurniture` 를 생성한다.
10. `FurniturePurchaseLog` 를 저장한다.
11. 구매 결과를 응답한다.

### 4. 내 보유 가구 목록

`GET /api/users/me/furnitures`

흐름:

1. `user_furnitures` 에서 내 보유 가구를 조회한다.
2. 각 보유 가구의 `Furniture` 를 조회한다.
3. 가구 마스터 정보를 붙여서 응답한다.

### 5. 가구 방 미리보기

`GET /api/shop/furnitures/{furnitureId}/preview-room`

흐름:

1. 미리보기 대상 가구를 조회한다.
2. 없으면 `S00-001`.
3. 내 방 배치 목록을 조회한다.
4. 각 배치의 `UserFurniture` 를 조회한다.
5. 각 배치의 `Furniture` 를 조회한다.
6. 미리보기 대상과 같은 `category` 의 기존 배치는 제외한다.
7. 다른 카테고리 배치는 그대로 유지한다.
8. 미리보기 대상 가구를 `preview=true` 로 응답에 추가한다.
   - `placementId=null`
   - `userFurnitureId=null`
   - `preview=true`
   - 저장은 하지 않는다.
9. 응답한다.

### 6. 내 방 조회

`GET /api/users/me/room`

흐름:

1. 내 `room_furniture_placements` 를 조회한다.
2. `zIndex ASC`, `placementId ASC` 로 정렬한다.
3. 각 placement 의 `UserFurniture` 를 조회한다.
4. 각 `UserFurniture` 의 `Furniture` 를 조회한다.
5. 배치 정보와 가구 정보를 합쳐서 응답한다.
6. `preview=false` 로 응답한다.

### 7. 보유 가구 방 배치

`POST /api/users/me/room/furnitures/{userFurnitureId}/placements`

흐름:

1. `userId + userFurnitureId` 로 내 보유 가구를 조회한다.
2. 없거나 내 것이 아니면 `S01-001`.
3. 보유 가구의 `Furniture` 를 조회한다.
4. 없으면 `S00-001`.
5. 내 현재 방 배치 목록을 조회한다.
6. 같은 카테고리 배치가 있는지 확인한다.
7. 같은 가구가 이미 배치 중이면 기존 placement 를 그대로 응답한다.
8. 같은 카테고리 다른 가구가 배치 중이면 기존 placement 를 삭제한다.
9. 새 placement 를 생성한다.
   - `defaultX`
   - `defaultY`
   - `zIndex`
   - `rotation=0`
10. 저장 후 응답한다.

### 8. 배치 위치 수정

`PATCH /api/users/me/room/placements/{placementId}`

흐름:

1. `placementId + userId` 로 내 배치를 조회한다.
2. 없거나 내 것이 아니면 `S02-001`.
3. 요청 body 의 `x`, `y`, `zIndex`, `rotation` 으로 업데이트한다.
4. 연결된 `UserFurniture` 를 조회한다.
5. 연결된 `Furniture` 를 조회한다.
6. 수정된 배치 정보를 응답한다.

### 9. 방 가구 배치 제거

`DELETE /api/users/me/room/placements/{placementId}`

흐름:

1. `placementId + userId` 로 내 배치를 조회한다.
2. 없거나 내 것이 아니면 `S02-001`.
3. `RoomFurniturePlacement` 만 삭제한다.
4. `UserFurniture` 는 유지한다.
5. 204로 응답한다.

핵심 정책:

- 구매는 `UserFurniture` 를 만든다.
- 배치는 `RoomFurniturePlacement` 를 만든다.
- 방에서 제거해도 보유 가구는 남는다.
- 방에는 카테고리별 1개만 배치된다.
- 미리보기는 저장하지 않는다.

## 주의사항

- FE에서 같은 카테고리 교체 로직을 직접 계산하지 않아도 된다. 서버가 처리한다.
- 미리보기는 저장이 아니다.
- 실제 방 상태는 항상 `GET /api/users/me/room` 이 기준이다.
- 목록 상태는 항상 `GET /api/shop/furnitures` 의 `status` 를 기준으로 표시한다.
