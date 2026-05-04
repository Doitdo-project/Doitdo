# Shop Furniture Design

## 배경

상점 기능의 대상이 기존 "다마고치 캐릭터 아이템"에서 "방 꾸미기용 가구"로 변경되었다.

기존 `inventory` 도메인의 `items`, `user_items`, `equip/unequip` 흐름은 특정 다마고치에 아이템을 장착하는 구조다. 가구는 다마고치가 아니라 "유저의 방"에 배치되는 리소스이므로, 구매/보유/배치를 분리해서 설계한다.

## 확정된 요구사항

- 같은 유저는 같은 가구를 1개만 보유할 수 있다.
- 이미 보유한 가구는 상점에서 품절처럼 표시한다.
- 구매 재화는 기존 `user_wallets.balance` 를 사용한다.
- 구매 시 포인트 차감, 보유 가구 생성, 구매 로그 저장은 한 트랜잭션으로 처리한다.
- 1차 MVP는 상점 구매와 보유 처리까지만 구현한다.
- 방 배치, 위치 수정, 방에서 제거, 다마고치 화면의 방 조회는 2차 범위로 분리한다.
- 2차에서는 방에서 삭제하더라도 인벤토리 영구 삭제가 아니라 배치 제거로 처리한다.
- 2차에서는 지금 가구 위치가 고정이어도, 이후 위치 수정 기능을 위해 `x`, `y` 좌표를 DB와 API에 둔다.
- 배치 개수 제한, 위치 겹침 제한, 카테고리별 배치 제한은 2차에서도 MVP 기준으로 두지 않는다.

## 단계 분리

### 1차: 상점 MVP

목표는 "상점에서 가구를 조회하고, 월렛으로 구매하고, 이미 보유한 가구를 품절 표시하는 것"이다.

포함 범위:

- 가구 마스터 조회
- 카테고리별 상점 조회
- 보유 여부 기반 `owned`, `soldOut` 표시
- 가구 구매
- 월렛 잔액 차감
- 중복 구매 방지
- 가구 보유 목록 조회
- 구매 로그 저장

1차 DB 범위:

- `furnitures`
- `user_furnitures`
- `furniture_purchase_logs`

1차 API 범위:

- `GET /api/shop/furnitures`
- `POST /api/shop/furnitures/{furnitureId}/purchase`
- `GET /api/users/me/furnitures`

### 2차: 방 배치

목표는 "보유한 가구를 유저 방에 배치하고, 다마고치 화면에서 방과 가구를 함께 조회하는 것"이다.

포함 범위:

- 내 방 조회
- 보유 가구 배치
- 배치 위치 수정
- 방에서 가구 제거
- 다마고치 화면용 배치 가구 목록 조회

2차 DB 범위:

- `room_furniture_placements`

## 권장 접근

### A. 기존 `Item/UserItem` 확장

기존 테이블에 `type=FURNITURE` 같은 구분값을 추가한다.

- 장점: 테이블 수가 적다.
- 단점: 현재 코드가 다마고치 장착 아이템 중심이라 이름과 의미가 계속 충돌한다.

### B. 가구 전용 모델 분리

`furnitures`, `user_furnitures`, `furniture_purchase_logs` 를 1차로 새로 둔다. `room_furniture_placements` 는 방 배치 2차에서 추가한다.

- 장점: 상점/방 꾸미기 요구사항을 명확하게 표현한다.
- 단점: 신규 테이블과 API가 늘어난다.

### C. 기존 `inventory` 를 `asset` 개념으로 크게 리팩터링

아이템/가구/기타 보유물을 하나의 큰 자산 모델로 재정의한다.

- 장점: 장기적으로 확장성이 좋다.
- 단점: 현재 작업 범위 대비 변경량이 크고 기존 다마고치 장착 API 회귀 위험이 크다.

추천안은 B다. 기존 캐릭터 아이템 API를 건드리는 범위를 줄이고, 가구 도메인의 의미를 명확히 유지할 수 있다. 단, 구현은 1차 상점 MVP와 2차 방 배치로 나눈다.

## 도메인 모델

### 공통 타임스탬프 기준

- 마스터/보유 테이블은 기존 컨벤션처럼 `BaseTimeEntity` 를 상속해 `created_at`, `updated_at` 을 둔다.
- 로그 테이블은 변경 이력보다 발생 시각이 중요하므로 `purchased_at` 을 `CreatedDate` 로 관리한다.
- 따라서 1차 MVP 기준 `Furniture`, `UserFurniture` 는 `BaseTimeEntity` 대상이고, `FurniturePurchaseLog` 는 `purchasedAt` 중심으로 둔다.

### Furniture

가구 마스터 데이터.

| 필드 | 설명 |
|---|---|
| `furnitureId` | 가구 ID |
| `code` | 가구 코드. 시드/FE 매핑용 |
| `name` | 이름 |
| `description` | 설명 |
| `category` | 가구 카테고리 |
| `price` | 가격 |
| `imageUrl` | 원본 이미지 URL |
| `thumbnailUrl` | 썸네일 URL |
| `defaultX` | 기본 x 좌표 |
| `defaultY` | 기본 y 좌표 |
| `width` | 렌더링 기준 너비 |
| `height` | 렌더링 기준 높이 |
| `zIndex` | 기본 레이어 순서 |
| `isOnSale` | 판매 여부 |
| `isDeleted` | 소프트 삭제 여부 |

1차 테이블 컬럼:

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| `furniture_id` | BIGINT | PK, AUTO_INCREMENT | 가구 ID |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE | 가구 코드 |
| `name` | VARCHAR(100) | NOT NULL | 이름 |
| `description` | VARCHAR(255) | NULL | 설명 |
| `category` | VARCHAR(30) | NOT NULL | 카테고리 |
| `price` | INT | NOT NULL | 가격 |
| `image_url` | VARCHAR(500) | NULL | 원본 이미지 URL |
| `thumbnail_url` | VARCHAR(500) | NULL | 썸네일 URL |
| `default_x` | INT | NOT NULL | 기본 x 좌표 |
| `default_y` | INT | NOT NULL | 기본 y 좌표 |
| `width` | INT | NOT NULL | 렌더링 기준 너비 |
| `height` | INT | NOT NULL | 렌더링 기준 높이 |
| `z_index` | INT | NOT NULL | 기본 레이어 |
| `is_on_sale` | BOOLEAN | NOT NULL | 판매 여부 |
| `is_deleted` | BOOLEAN | NOT NULL | 삭제 여부 |
| `created_at` | DATETIME | NOT NULL | 생성 시각 |
| `updated_at` | DATETIME | NOT NULL | 수정 시각 |

초기 카테고리 후보:

- `WALL`
- `FLOOR`
- `BED`
- `DESK`
- `CHAIR`
- `DECORATION`
- `ETC`

### UserFurniture

유저가 보유한 가구.

| 필드 | 설명 |
|---|---|
| `userFurnitureId` | 유저 보유 가구 ID |
| `userId` | 유저 ID |
| `furnitureId` | 가구 ID |
| `acquiredAt` | 획득 시각 |

제약:

- `unique(user_id, furniture_id)`
- 같은 유저의 같은 가구 중복 구매 방지

1차 테이블 컬럼:

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| `user_furniture_id` | BIGINT | PK, AUTO_INCREMENT | 유저 보유 가구 ID |
| `user_id` | BIGINT | NOT NULL | 유저 ID |
| `furniture_id` | BIGINT | NOT NULL | 가구 ID |
| `created_at` | DATETIME | NOT NULL | 생성 시각 |
| `updated_at` | DATETIME | NOT NULL | 수정 시각 |

인덱스:

- `uk_user_furnitures_user_furniture (user_id, furniture_id)`
- `idx_user_furnitures_user_id (user_id)`

### RoomFurniturePlacement

유저 방에 배치된 가구. 2차 범위에서 추가한다.

| 필드 | 설명 |
|---|---|
| `placementId` | 배치 ID |
| `userId` | 유저 ID |
| `userFurnitureId` | 유저 보유 가구 ID |
| `x` | 배치 x 좌표 |
| `y` | 배치 y 좌표 |
| `zIndex` | 배치 레이어 |
| `rotation` | 회전값. MVP에서는 0 고정 가능 |
| `isPlaced` | 배치 여부 또는 제거 상태 |

MVP에서는 방에서 제거할 때 row 삭제 또는 `isPlaced=false` 중 하나를 선택한다. 추적 이력이 필요 없으면 row 삭제가 단순하다.

### FurniturePurchaseLog

가구 구매 이력.

| 필드 | 설명 |
|---|---|
| `purchaseId` | 구매 로그 ID |
| `userId` | 유저 ID |
| `userFurnitureId` | 생성된 보유 가구 ID |
| `furnitureId` | 구매한 가구 ID |
| `price` | 구매 당시 가격 |
| `balanceAfterPurchase` | 구매 후 잔액 |
| `purchasedAt` | 구매 시각 |

기존 `purchase_logs.userItem_id` 는 가구 구매와 의미가 맞지 않으므로 가구용 로그를 분리하거나 컬럼명을 정리한다.

1차 테이블 컬럼:

| 컬럼 | 타입 | 제약 | 설명 |
|---|---|---|---|
| `purchase_id` | BIGINT | PK, AUTO_INCREMENT | 구매 로그 ID |
| `user_id` | BIGINT | NOT NULL | 유저 ID |
| `user_furniture_id` | BIGINT | NOT NULL | 생성된 보유 가구 ID |
| `furniture_id` | BIGINT | NOT NULL | 구매한 가구 ID |
| `price` | INT | NOT NULL | 구매 당시 가격 |
| `balance_after_purchase` | INT | NOT NULL | 구매 후 잔액 |
| `purchased_at` | DATETIME | NOT NULL | 구매 시각 |

인덱스:

- `idx_furniture_purchase_logs_user_id (user_id)`
- `idx_furniture_purchase_logs_furniture_id (furniture_id)`

## API 초안

### 1차 상점 MVP

### 상점

#### `GET /api/shop/furnitures`

상점 가구 목록 조회.

Query:

- `category` optional

Response item:

```json
{
  "furnitureId": 1,
  "code": "WOODEN_CHAIR",
  "name": "나무 의자",
  "category": "CHAIR",
  "price": 100,
  "imageUrl": "https://...",
  "thumbnailUrl": "https://...",
  "defaultX": 120,
  "defaultY": 300,
  "width": 80,
  "height": 80,
  "zIndex": 10,
  "owned": true,
  "soldOut": true
}
```

`soldOut` 은 `owned == true` 이거나 판매 불가 상태일 때 `true` 로 내려준다.

#### `POST /api/shop/furnitures/{furnitureId}/purchase`

가구 구매.

처리 순서:

1. 가구 존재 및 판매중 확인
2. 이미 보유했는지 확인
3. 월렛 조회 및 잔액 확인
4. `wallet.spend(price)` 차감
5. `UserFurniture` 생성
6. 구매 로그 저장

Response:

```json
{
  "furnitureId": 1,
  "userFurnitureId": 10,
  "owned": true,
  "soldOut": true,
  "balance": 900
}
```

### 내 가구

#### `GET /api/users/me/furnitures`

유저가 보유한 가구 목록 조회.

1차에서는 보유 가구 목록만 내려준다. 2차 방 배치가 들어오면 배치 여부를 함께 내려줄 수 있다.

### 2차 방 배치

### 내 방

#### `GET /api/users/me/room`

내 방과 배치된 가구 목록 조회. 다마고치 화면에서 사용한다.

Response:

```json
{
  "items": [
    {
      "placementId": 3,
      "userFurnitureId": 10,
      "furnitureId": 1,
      "name": "나무 의자",
      "imageUrl": "https://...",
      "x": 120,
      "y": 300,
      "width": 80,
      "height": 80,
      "zIndex": 10,
      "rotation": 0
    }
  ]
}
```

#### `POST /api/users/me/room/furnitures/{userFurnitureId}/placements`

보유 가구 배치.

MVP에서는 요청 body 없이 가구의 기본 좌표로 배치해도 된다. 이후 확장을 위해 body에 `x`, `y`, `zIndex`, `rotation` 을 받을 수 있게 열어둔다.

#### `PATCH /api/users/me/room/placements/{placementId}`

배치 위치 수정.

지금 당장은 FE에서 호출하지 않아도, API와 DB 설계상 지원 가능하게 둔다.

#### `DELETE /api/users/me/room/placements/{placementId}`

방에서 가구 제거. 보유 가구는 삭제하지 않는다.

## 월렛 처리

`UserWallet` 에 구매용 차감 메서드를 추가한다.

```java
public void spend(Integer amount) {
    if (this.balance < amount) {
        throw new CustomException(ShopErrorCode.S00_003);
    }
    this.balance -= amount;
}
```

동시 구매를 고려해 `UserWalletRepository.findByUserIdForUpdate(userId)` 형태의 비관적 락 조회를 권장한다.

## 에러 코드

`ShopErrorCode` 는 현재 비어 있으므로 1차 상점 MVP에서 아래 코드를 확정한다.

### 1차 상점 MVP

| enum | code | HTTP | 의미 | 사용 위치 |
|---|---|---|
| `FURNITURE_NOT_FOUND` | `S00-001` | 404 | 가구를 찾을 수 없음 | 구매 |
| `FURNITURE_ALREADY_OWNED` | `S00-002` | 409 | 이미 보유한 가구 | 구매 |
| `INSUFFICIENT_BALANCE` | `S00-003` | 409 | 잔액 부족 | 구매 |
| `FURNITURE_NOT_ON_SALE` | `S00-004` | 409 | 판매 중이 아닌 가구 | 구매 |
| `WALLET_NOT_FOUND` | `S00-005` | 404 | 월렛을 찾을 수 없음 | 구매 |

Swagger 노출:

- `POST /api/shop/furnitures/{furnitureId}/purchase`: `S00-001`, `S00-002`, `S00-003`, `S00-004`, `S00-005`
- `GET /api/shop/furnitures`: 비즈니스 에러 없음. 글로벌 검증/인증/서버 에러만 자동 노출
- `GET /api/users/me/furnitures`: 비즈니스 에러 없음. 글로벌 검증/인증/서버 에러만 자동 노출

### 2차 방 배치

방 배치 구현 시 아래 코드를 추가한다.

| enum | code | HTTP | 의미 |
|---|---|---|---|
| `USER_FURNITURE_NOT_FOUND` | `S01-001` | 404 | 보유 가구 없음 |
| `USER_FURNITURE_FORBIDDEN` | `S01-002` | 403 | 타 사용자 보유 가구 |
| `PLACEMENT_NOT_FOUND` | `S02-001` | 404 | 배치 정보 없음 |
| `PLACEMENT_FORBIDDEN` | `S02-002` | 403 | 타 사용자 배치 정보 |

## 테스트 기준

### 1차 상점 MVP

- 상점 목록에서 보유 가구가 `owned=true`, `soldOut=true` 로 내려간다.
- 카테고리 필터 조회가 동작한다.
- 구매 성공 시 월렛 잔액이 차감되고 `UserFurniture`, 구매 로그가 생성된다.
- 이미 보유한 가구는 중복 구매할 수 없다.
- 잔액 부족 시 보유 가구와 구매 로그가 생성되지 않는다.
- 보유 가구 목록을 조회할 수 있다.

### 2차 방 배치

- 구매 후 기본 좌표로 방에 배치할 수 있다.
- 방에서 제거해도 `UserFurniture` 는 남아 있다.
- 타 사용자의 보유 가구/배치 정보는 조작할 수 없다.

## 비즈니스 로직 상세 흐름

### 상점 구매

`POST /api/shop/furnitures/{furnitureId}/purchase`

1. 가구 조회
   - 삭제되지 않은 가구만 조회한다.
   - 없으면 `S00-001 FURNITURE_NOT_FOUND`.
2. 판매 여부 확인
   - `isOnSale=false` 면 `S00-004 FURNITURE_NOT_ON_SALE`.
3. 중복 보유 확인
   - 같은 유저가 같은 가구를 이미 갖고 있으면 `S00-002 FURNITURE_ALREADY_OWNED`.
4. 월렛 조회
   - `findByUserIdForUpdate` 로 비관적 락을 잡는다.
   - 없으면 `S00-005 WALLET_NOT_FOUND`.
5. 잔액 차감
   - `UserWallet.spend(price)` 로 차감한다.
   - 잔액 부족이면 `S00-003 INSUFFICIENT_BALANCE`.
6. 보유 가구 생성
   - `UserFurniture.create(userId, furnitureId)` 로 생성한다.
7. 구매 로그 저장
   - 구매 당시 가격, 구매 후 잔액, 생성된 `userFurnitureId` 를 저장한다.
   - 1~7은 한 트랜잭션으로 처리한다.

### 상점 목록 조회

`GET /api/shop/furnitures?category=CHAIR`

- 판매/삭제 여부 기준으로 가구 목록을 조회한다.
- 유저의 보유 가구 ID 목록을 조회한다.
- 각 가구마다 `owned = 보유 여부`, `soldOut = owned || !isOnSale` 로 계산한다.
- `category` query 가 있으면 카테고리 필터를 적용한다.

### 내 보유 가구 목록

`GET /api/users/me/furnitures`

- `user_furnitures` 에서 내 보유 가구를 조회한다.
- 각 보유 가구의 `Furniture` 정보를 붙여 응답한다.

### 방 배치

`POST /api/users/me/room/furnitures/{userFurnitureId}/placements`

1. `userId + userFurnitureId` 로 보유 가구를 조회한다.
   - 내 가구가 아니거나 없으면 `S01-001 USER_FURNITURE_NOT_FOUND`.
2. 가구 마스터를 조회한다.
   - 없으면 `S00-001 FURNITURE_NOT_FOUND`.
3. `RoomFurniturePlacement.create(...)` 로 배치 정보를 만든다.
   - 가구의 `defaultX`, `defaultY`, `zIndex` 를 사용한다.
   - `rotation=0` 으로 시작한다.
4. `room_furniture_placements` 에 저장한다.

### 방 조회

`GET /api/users/me/room`

- 내 `room_furniture_placements` 를 조회한다.
- 정렬은 `zIndex ASC`, `placementId ASC` 기준이다.
- 각 placement 에 연결된 `UserFurniture` 와 `Furniture` 정보를 붙여 응답한다.

### 배치 수정

`PATCH /api/users/me/room/placements/{placementId}`

- `placementId + userId` 로 조회한다.
- 없거나 내 배치가 아니면 `S02-001 PLACEMENT_NOT_FOUND`.
- `x`, `y`, `zIndex`, `rotation` 을 업데이트한다.

### 방에서 제거

`DELETE /api/users/me/room/placements/{placementId}`

- `placementId + userId` 로 조회한다.
- 없으면 `S02-001 PLACEMENT_NOT_FOUND`.
- `RoomFurniturePlacement` 만 삭제하고 `UserFurniture` 는 유지한다.

### 회원 hard delete

- 기존 회원 삭제 흐름에 `roomFurniturePlacementRepository.deleteAllByUserId(userId)` 를 추가한다.
- `user_furnitures` 삭제 전에 `room_furniture_placements` 를 먼저 삭제한다.

## 미정 사항

- 방 제거 시 placement row 삭제와 `isPlaced=false` 중 어떤 방식을 쓸지.
  - 추천: MVP는 row 삭제.
- 카테고리 enum 목록.
  - 예: `CHAIR`, `TABLE`, `BED`, `WALL`, `FLOOR`, `DECORATION`, `ETC`.
- 가구 좌표 기준.
  - FE 디자인 기준 해상도와 좌상단/중앙 기준점을 확정해야 한다.

## 구현 영향 범위

### 1차 상점 MVP

- 신규 또는 변경 엔티티: `Furniture`, `UserFurniture`, `FurniturePurchaseLog`, `UserWallet`
- 신규 또는 변경 Repository: `FurnitureRepository`, `UserFurnitureRepository`, `FurniturePurchaseLogRepository`, `UserWalletRepository`
- 신규 API: shop 가구 조회/구매, 내 가구 조회
- 문서 갱신: `docs/architecture/package-layout.md`, `docs/architecture/erd.md`, `docs/api/error-codes.md`, `docs/api/swagger.md`
- 마이그레이션: 가구 마스터/보유/구매 로그 테이블 DDL

### 2차 방 배치

- 신규 엔티티: `RoomFurniturePlacement`
- 신규 Repository: `RoomFurniturePlacementRepository`
- 신규 API: 내 방 조회/배치/수정/제거
- 문서 갱신: `docs/architecture/package-layout.md`, `docs/architecture/erd.md`, `docs/api/error-codes.md`, `docs/api/swagger.md`
- 마이그레이션: 방 배치 테이블 DDL

## 구현 현황

### 2026-05-04 1차 상점 MVP 구현

구현된 범위:

- 상점 가구 목록 조회
- 카테고리별 상점 가구 목록 조회
- 보유 가구 `owned=true`, `soldOut=true` 표시
- 가구 구매
- 월렛 잔액 차감
- 같은 유저의 같은 가구 중복 구매 차단
- 잔액 부족 시 구매 차단
- 판매 중이 아닌 가구 구매 차단
- 내 보유 가구 목록 조회
- 가구 구매 로그 저장

구현된 API:

| Method | Path | 설명 |
|---|---|---|
| GET | `/api/shop/furnitures` | 상점 가구 목록 조회. `category` query optional |
| POST | `/api/shop/furnitures/{furnitureId}/purchase` | 가구 구매 |
| GET | `/api/users/me/furnitures` | 내 보유 가구 목록 조회 |

구현된 파일:

| 종류 | 파일 |
|---|---|
| Controller | `src/main/java/com/doitdo/domain/shop/api/controller/ShopController.java` |
| Service | `src/main/java/com/doitdo/domain/shop/application/ShopService.java` |
| Service impl | `src/main/java/com/doitdo/domain/shop/application/impl/ShopServiceImpl.java` |
| Entity | `src/main/java/com/doitdo/domain/shop/entity/Furniture.java` |
| Entity | `src/main/java/com/doitdo/domain/shop/entity/UserFurniture.java` |
| Entity | `src/main/java/com/doitdo/domain/shop/entity/FurniturePurchaseLog.java` |
| Repository | `src/main/java/com/doitdo/domain/shop/repository/FurnitureRepository.java` |
| Repository | `src/main/java/com/doitdo/domain/shop/repository/UserFurnitureRepository.java` |
| Repository | `src/main/java/com/doitdo/domain/shop/repository/FurniturePurchaseLogRepository.java` |
| Response DTO | `src/main/java/com/doitdo/domain/shop/api/dto/resp/FurnitureShopResp.java` |
| Response DTO | `src/main/java/com/doitdo/domain/shop/api/dto/resp/FurnitureShopItemResp.java` |
| Response DTO | `src/main/java/com/doitdo/domain/shop/api/dto/resp/PurchaseFurnitureResp.java` |
| Response DTO | `src/main/java/com/doitdo/domain/shop/api/dto/resp/UserFurnitureResp.java` |
| Response DTO | `src/main/java/com/doitdo/domain/shop/api/dto/resp/UserFurnitureItemResp.java` |
| Migration SQL | `docs/ops/migrations/2026-05-shop-furniture.sql` |
| Test | `src/test/java/com/doitdo/domain/shop/application/impl/ShopServiceImplTest.java` |

변경된 공통/기존 파일:

- `ShopErrorCode`: `S00-001` ~ `S00-005` 추가
- `UserWallet`: `spend(Integer amount)` 추가
- `UserWalletRepository`: `findByUserIdForUpdate(Long userId)` 추가
- `UserHardDeleteService`: 탈퇴 hard delete 시 `user_furnitures`, `furniture_purchase_logs` 삭제 추가
- `docs/architecture/package-layout.md`: shop 구현 파일 목록 갱신
- `docs/architecture/erd.md`: shop 테이블 매핑 갱신
- `docs/api/error-codes.md`: shop 에러 코드 갱신

검증:

- RED: `ShopServiceImplTest` 작성 후 구현 전 컴파일 실패 확인
- GREEN: `.\gradlew.bat test --tests "com.doitdo.domain.shop.application.impl.ShopServiceImplTest"` 성공
- 전체 테스트: `.\gradlew.bat test --rerun-tasks` 성공

아직 안 한 것:

- 가구 seed 데이터 추가
- 실제 dev DB에 마이그레이션 수동 적용 확인
- Swagger UI에서 응답 예시 확인
- 2차 방 배치 기능

### 2026-05-04 2차-1 방 배치 코어 구현

커밋 단위:

- `feat : shop room furniture placement core`

구현된 범위:

- 보유 가구를 방에 배치하는 서비스 로직
- 배치된 가구로 내 방 목록을 조회하는 서비스 로직
- 배치 위치 수정 서비스 로직
- 방에서 배치만 제거하는 서비스 로직
- 방 배치 Controller/API
- 방 배치 마이그레이션 SQL
- hard delete 시 `room_furniture_placements` 삭제 연동
- 타 사용자 보유 가구를 배치할 수 없도록 보유 가구를 `userId + userFurnitureId` 로 조회
- 배치 삭제 시 `UserFurniture` 는 삭제하지 않고 `RoomFurniturePlacement` 만 삭제

구현된 파일:

| 종류 | 파일 |
|---|---|
| Controller | `src/main/java/com/doitdo/domain/shop/api/controller/ShopController.java` |
| Entity | `src/main/java/com/doitdo/domain/shop/entity/RoomFurniturePlacement.java` |
| Repository | `src/main/java/com/doitdo/domain/shop/repository/RoomFurniturePlacementRepository.java` |
| Service | `src/main/java/com/doitdo/domain/shop/application/RoomFurniturePlacementService.java` |
| Service impl | `src/main/java/com/doitdo/domain/shop/application/impl/RoomFurniturePlacementServiceImpl.java` |
| Request DTO | `src/main/java/com/doitdo/domain/shop/api/dto/req/UpdateRoomFurniturePlacementReq.java` |
| Response DTO | `src/main/java/com/doitdo/domain/shop/api/dto/resp/RoomResp.java` |
| Response DTO | `src/main/java/com/doitdo/domain/shop/api/dto/resp/RoomFurniturePlacementResp.java` |
| Migration SQL | `docs/ops/migrations/2026-05-shop-furniture.sql` |
| Test | `src/test/java/com/doitdo/domain/shop/application/impl/RoomFurniturePlacementServiceImplTest.java` |
| Test | `src/test/java/com/doitdo/domain/shop/api/controller/ShopControllerTest.java` |

변경된 기존 파일:

- `UserFurnitureRepository`: `findByUserIdAndUserFurnitureId(Long userId, Long userFurnitureId)` 추가
- `ShopErrorCode`: `USER_FURNITURE_NOT_FOUND`, `PLACEMENT_NOT_FOUND` 추가
- `UserHardDeleteService`: 탈퇴 hard delete 시 `room_furniture_placements` 삭제 추가
- `docs/architecture/package-layout.md`: shop 방 배치 구현 파일 목록 갱신
- `docs/architecture/erd.md`: shop 테이블 매핑 갱신
- `docs/api/error-codes.md`: shop 방 배치 에러 코드 갱신

검증:

- RED: `RoomFurniturePlacementServiceImplTest` 작성 후 구현 전 컴파일 실패 확인
- GREEN: `.\gradlew.bat test --tests "com.doitdo.domain.shop.application.impl.RoomFurniturePlacementServiceImplTest"` 성공
- RED: `ShopControllerTest` 작성 후 컨트롤러 메서드 미존재 컴파일 실패 확인
- GREEN: `.\gradlew.bat test --tests "com.doitdo.domain.shop.api.controller.ShopControllerTest"` 성공
- 전체 테스트: `.\gradlew.bat test` 성공

아직 안 한 것:

- 가구 seed 데이터 추가
- 실제 dev DB에 마이그레이션 수동 적용 확인
- Swagger UI에서 방 배치 응답 예시 확인
