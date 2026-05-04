# Shop Inventory Room Preview Design

## 배경

상점 화면이 단순 구매 목록이 아니라 "상점 + 인벤토리" 통합 화면으로 확장된다.

사용자는 상점 진입 시 모든 가구를 보고, 각 가구가 구매 가능한지, 보유 중인지, 방에 배치 중인지 바로 알아야 한다. 또한 상점에서 특정 가구를 미리보기할 때는 내 실제 방 상태를 기반으로 하되, 같은 카테고리의 기존 배치 가구는 제외하고 미리보기 대상 가구를 보여줘야 한다.

## 확정된 요구사항

- 상점은 인벤토리 역할을 겸한다.
- 상점 가구 목록에서 각 가구의 상태를 내려준다.
- 같은 유저는 같은 가구를 1개만 보유할 수 있다.
- 방에는 카테고리별 1개 가구만 배치할 수 있다.
- 같은 카테고리의 새 가구를 배치하면 기존 배치는 자동 제거한다.
- 자동 제거 시 `UserFurniture` 는 삭제하지 않는다.
- 삭제/교체되는 것은 `RoomFurniturePlacement` row 뿐이다.
- 미리보기는 내 실제 방 배치를 기반으로 한다.
- 미리보기 대상 가구와 같은 카테고리의 기존 배치 가구는 응답에서 제외한다.
- 미리보기 대상 가구는 저장하지 않고 응답에만 포함한다.

## 상점/인벤토리 상태

상점 목록의 각 가구는 아래 상태 중 하나를 가진다.

| 상태 | 조건 | 화면 의미 |
|---|---|---|
| `PURCHASABLE` | 미보유 | 가격 노출 + 구매 가능 |
| `PLACEABLE` | 보유 중 + 방에 미배치 | 보유중 노출 + 배치 가능 |
| `PLACED` | 보유 중 + 방에 배치 중 | 보유중 노출 + 배치중 |

기존 `owned`, `soldOut` 은 상점 구매 관점의 상태다. 통합 상점/인벤토리 화면에서는 `owned`, `placed`, `status` 를 함께 내려주는 방식이 명확하다.

응답 예시:

```json
{
  "furnitureId": 1,
  "code": "WALL_CLOCK_001",
  "name": "벽시계",
  "category": "CLOCK",
  "price": 100,
  "imageUrl": "https://...",
  "thumbnailUrl": "https://...",
  "defaultX": 120,
  "defaultY": 300,
  "width": 80,
  "height": 80,
  "zIndex": 10,
  "owned": true,
  "placed": false,
  "status": "PLACEABLE"
}
```

## 배치 정책

`POST /api/users/me/room/furnitures/{userFurnitureId}/placements`

처리 순서:

1. `userId + userFurnitureId` 로 보유 가구를 조회한다.
   - 없으면 `S01-001 USER_FURNITURE_NOT_FOUND`.
2. 보유 가구의 `furnitureId` 로 가구 마스터를 조회한다.
   - 없으면 `S00-001 FURNITURE_NOT_FOUND`.
3. 같은 유저의 현재 방 배치 중 같은 `category` 가구를 찾는다.
4. 같은 카테고리 배치가 있으면 기존 `RoomFurniturePlacement` 를 삭제한다.
5. 새 `RoomFurniturePlacement` 를 생성한다.
   - `x = furniture.defaultX`
   - `y = furniture.defaultY`
   - `zIndex = furniture.zIndex`
   - `rotation = 0`
6. 새 배치를 저장한다.

중요 정책:

- 같은 카테고리 교체는 서버에서 자동 처리한다.
- 기존 배치 제거와 새 배치 저장은 한 트랜잭션으로 처리한다.
- 기존 보유 가구는 삭제하지 않는다.

## 미리보기 API

추천 API:

| Method | Path | 설명 |
|---|---|---|
| GET | `/api/shop/furnitures/{furnitureId}/preview-room` | 특정 가구를 내 방에 놓았을 때의 미리보기 조회 |

처리 순서:

1. 미리보기 대상 가구를 조회한다.
   - 없으면 `S00-001 FURNITURE_NOT_FOUND`.
2. 내 방 배치 목록을 조회한다.
3. 미리보기 대상 가구와 같은 `category` 의 기존 배치를 응답에서 제외한다.
4. 나머지 기존 배치 가구는 그대로 응답한다.
5. 미리보기 대상 가구를 저장 없이 응답에 추가한다.

응답은 기존 `RoomResp` 와 같은 구조를 재사용할 수 있다. 단, FE가 미리보기 가구를 구분해야 하면 `preview=true` 필드를 추가한 별도 응답 DTO가 필요하다.

예시:

- 내 방에 `CLOCK` 카테고리 벽시계 A가 배치되어 있다.
- 상점에서 벽시계 B를 미리보기한다.
- 응답에서는 벽시계 A를 제외한다.
- 벽시계 B를 기본 좌표로 포함한다.
- 다른 카테고리 가구는 그대로 포함한다.

## 구현 영향 범위

- `FurnitureShopItemResp`
  - `placed`
  - `status`
- `RoomFurniturePlacementRepository`
  - 유저 방 배치 조회
  - 같은 카테고리 배치 조회 또는 서비스 레벨 필터링
- `ShopServiceImpl`
  - 상점 목록에서 보유/배치 상태 계산
  - 미리보기 방 조회 기능 추가 시 대상 가구 + 기존 방 배치 합성
- `RoomFurniturePlacementServiceImpl`
  - 배치 시 같은 카테고리 기존 placement 자동 삭제
- `ShopController`
  - 미리보기 API 추가
- 테스트
  - 미보유 가구는 `PURCHASABLE`
  - 보유+미배치 가구는 `PLACEABLE`
  - 보유+배치중 가구는 `PLACED`
  - 같은 카테고리 새 배치 시 기존 placement 삭제 후 새 placement 저장
  - 미리보기 시 같은 카테고리 기존 배치 제외

## 구현 현황

### 2026-05-04 구현

구현 완료:

- `GET /api/shop/furnitures` 에 `placed`, `status` 추가
- `FurnitureShopStatus` 추가 (`PURCHASABLE`, `PLACEABLE`, `PLACED`)
- `POST /api/users/me/room/furnitures/{userFurnitureId}/placements` 에 카테고리별 1개 배치 정책 적용
- 같은 카테고리 가구 배치 시 기존 placement 삭제 후 새 placement 저장
- 이미 배치 중인 같은 가구를 다시 배치하면 기존 placement 반환
- `GET /api/shop/furnitures/{furnitureId}/preview-room` 추가
- 미리보기 응답에 `preview=true` 추가
- 미리보기 대상과 같은 카테고리의 기존 배치는 응답에서 제외

검증:

- `ShopServiceImplTest`: 상점 상태, 미리보기 검증
- `RoomFurniturePlacementServiceImplTest`: 같은 카테고리 교체 배치 검증
- `ShopControllerTest`: 미리보기 API 매핑 검증

## 미정 사항

- 가구 seed 데이터와 실제 카테고리 목록.
- 실제 dev DB 마이그레이션 적용 여부.
- Swagger UI에서 미리보기 응답 예시 확인.
