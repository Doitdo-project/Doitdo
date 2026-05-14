# Shop Theme Purchase Placement Design

## 배경

현재 단일 가구 구매와 배치는 분리되어 있다.

| 사용자 선택 | API 흐름 |
|---|---|
| 구매만 하기 | `POST /api/shop/furnitures/{furnitureId}/purchase` |
| 바로 배치하기 | 구매 API 성공 후 `POST /api/users/me/room/furnitures/{userFurnitureId}/placements` |

`purchaseFurniture()` 는 보유 가구 생성과 구매 로그 저장까지만 처리하고, `RoomFurniturePlacement` 는 만들지 않는다.
테마 세트 구매도 이 정책을 따라 구매와 배치를 분리한다.

## 목표

- 테마 목록 응답에서 구매 모달에 필요한 가격/보유/가구 상세 정보를 한 번에 내려준다.
- 테마 구매 API는 미보유 가구 구매만 처리하고 자동 배치하지 않는다.
- 테마 바로 배치는 구매 성공 후 별도 일괄 배치 API로 처리한다.
- 단일 가구의 "구매만 하기 / 바로 배치하기" UX와 동일한 흐름을 유지한다.

## 비목표

- 테마 할인, 쿠폰, 기간 한정 판매는 이번 범위가 아니다.
- 부분 환불, 테마 구매 취소, 구매 이력 그룹 테이블은 이번 범위가 아니다.
- 구매 API body 옵션으로 `autoPlace` 를 받지 않는다.

## API 설계

### 테마 목록 조회

`GET /api/shop/themes`

로그인 사용자의 보유 여부를 반영해야 하므로 컨트롤러에서 `userId` 를 전달한다.

응답은 테마 카드와 구매 모달을 한 번에 그릴 수 있도록 가구 목록을 인라인으로 포함한다.

```json
{
  "status": 200,
  "code": "SUCCESS",
  "data": {
    "items": [
      {
        "themeCode": "MOON",
        "themeName": "달빛",
        "thumbnailUrl": "https://.../moon_background.webp",
        "furnitureCount": 4,
        "ownedCount": 1,
        "totalPrice": 1200,
        "purchasePrice": 900,
        "alreadyOwned": false,
        "furnitures": [
          {
            "furnitureId": 12,
            "name": "침대",
            "price": 300,
            "thumbnailUrl": "https://...",
            "owned": false
          }
        ]
      }
    ]
  }
}
```

정책:

- `furnitures[]` 는 `displayOrder ASC` 성격의 정렬을 사용한다. 현재 별도 displayOrder 컬럼이 없으면 `zIndex ASC, furnitureId ASC` 로 정렬한다.
- `totalPrice` 는 테마 내 판매 대상 가구 가격 합계다.
- `purchasePrice` 는 사용자가 아직 보유하지 않은 가구 가격 합계다.
- `alreadyOwned=true` 는 테마 내 구매 대상 가구를 모두 보유한 상태다.
- `ownedCount` 는 테마 내 보유 가구 수다.
- `thumbnailUrl` 은 구매 모달에서 바로 렌더링할 수 있도록 포함한다.

### 테마 구매

`POST /api/shop/themes/{themeCode}/purchase`

Body 없음.

테마 구매 API는 구매만 처리한다. 자동 배치는 하지 않는다.

```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "테마 구매 완료",
  "data": {
    "themeCode": "MOON",
    "themeName": "달빛",
    "purchasedCount": 3,
    "skippedOwnedCount": 1,
    "totalPaid": 900,
    "balance": 600,
    "purchasedFurnitures": [
      {
        "userFurnitureId": 101,
        "furnitureId": 12,
        "name": "침대",
        "price": 300
      }
    ]
  }
}
```

처리 순서:

1. `themeCode` 를 대문자로 정규화한다.
2. 활성 테마를 조회한다.
3. 테마 가구 목록을 조회한다.
4. 테마 가구가 없으면 `THEME_EMPTY` 를 반환한다.
5. 사용자의 보유 가구 ID 목록을 조회한다.
6. 미보유 가구만 결제 대상으로 만든다.
7. 모두 보유 중이면 `THEME_ALREADY_OWNED` 를 반환한다.
8. 총 결제 금액을 계산하고 월렛을 비관적 락으로 조회한다.
9. 잔액을 차감한다. 잔액 부족이면 전체 롤백한다.
10. `UserFurniture` 를 일괄 저장한다.
11. 가구별 구매 로그를 저장한다.
12. 구매 결과와 결제 후 잔액을 반환한다.

### 테마 일괄 배치

`POST /api/users/me/room/themes/{themeCode}/placements`

사용자가 보유한 해당 테마 가구를 한 번에 방에 배치한다.

```json
{
  "status": 200,
  "code": "SUCCESS",
  "message": "테마 배치 완료",
  "data": {
    "themeCode": "MOON",
    "placedCount": 4,
    "items": [
      {
        "placementId": 501,
        "userFurnitureId": 101,
        "furnitureId": 12,
        "name": "침대",
        "category": "BED",
        "imageUrl": "https://...",
        "x": 0,
        "y": 0,
        "zIndex": 10,
        "rotation": 0,
        "preview": false
      }
    ]
  }
}
```

정책:

- 테마 내 모든 가구를 사용자가 보유해야 배치한다.
- 미보유 가구가 하나라도 있으면 전체 실패한다.
- 같은 카테고리 기존 배치는 단일 배치 API처럼 제거하고 새 가구로 교체한다.
- 배치 좌표는 가구 마스터의 `defaultX/defaultY/zIndex` 를 사용한다.
- `rotation` 은 0으로 저장한다.
- 트랜잭션 안에서 기존 배치 제거와 신규 배치를 함께 처리한다.

## 에러 정책

기존 `ShopErrorCode` 의 `S03` 테마 카테고리를 확장한다.

| 이름 | 코드 | HTTP | 상황 |
|---|---|---:|---|
| `THEME_NOT_FOUND` | `S03-001` | 404 | 존재하지 않거나 비활성 테마 |
| `THEME_CATEGORY_DUPLICATED` | `S03-002` | 409 | 테마에 같은 카테고리 가구 중복 |
| `THEME_EMPTY` | `S03-003` | 422 | 활성 테마에 구매/배치할 가구 없음 |
| `THEME_ALREADY_OWNED` | `S03-010` | 409 | 테마 풀세트를 이미 보유 |
| `INSUFFICIENT_BALANCE` | `S00-003` | 409 | 잔액 부족 |

이미지 설계안의 `SH00-*` 는 최종 코드 형식과 맞지 않으므로 현재 레포 규칙인 `S03-*` 를 사용한다.
잔액 부족은 기존 단일 가구 구매와 동일하게 `S00-003` 을 재사용한다.

## 구현 영향 범위

- `ShopController`
  - `GET /api/shop/themes` 에 인증 사용자 반영
  - `POST /api/shop/themes/{themeCode}/purchase` 추가
  - `POST /api/users/me/room/themes/{themeCode}/placements` 추가
- `ShopService`
  - `listThemes(Long userId)` 로 시그니처 변경
  - `purchaseTheme(Long userId, String themeCode)` 추가
- `RoomFurniturePlacementService`
  - `placeTheme(Long userId, String themeCode)` 추가
- DTO
  - `FurnitureThemeResp` 확장
  - `FurnitureThemeFurnitureResp` 추가
  - `PurchaseThemeResp` 추가
  - `PurchaseThemeFurnitureResp` 추가
  - `PlaceThemeResp` 추가
- Repository
  - 테마 가구 조회는 기존 `findAllByThemeCodeAndIsDeletedFalseOrderByZIndexAscFurnitureIdAsc` 재사용
  - 사용자 보유 가구 조회는 기존 `findFurnitureIdsByUserId` 와 보유 목록 조회를 재사용
- Docs
  - `docs/api/error-codes.md`
  - `docs/api/swagger.md`
  - `docs/architecture/package-layout.md`

## 프론트 계약

구매만 하기:

1. `GET /api/shop/themes` 의 `purchasePrice`, `furnitures[]` 로 모달 표시
2. `POST /api/shop/themes/{themeCode}/purchase`
3. 성공 후 보유 상태/잔액 갱신

바로 배치하기:

1. `POST /api/shop/themes/{themeCode}/purchase`
2. 성공하면 `POST /api/users/me/room/themes/{themeCode}/placements`
3. 배치 성공 응답으로 방 상태 갱신

이미 풀세트 보유 상태에서 바로 배치하기:

1. 구매 API를 호출하지 않는다.
2. `POST /api/users/me/room/themes/{themeCode}/placements` 만 호출한다.

## 테스트 시나리오

- 테마 목록은 보유 가구를 반영해 `ownedCount`, `purchasePrice`, `alreadyOwned`, `furnitures[].owned` 를 반환한다.
- 테마 구매는 미보유 가구만 저장하고 보유 가구는 건너뛴다.
- 테마 구매는 배치를 만들지 않는다.
- 풀세트 보유 상태에서 테마 구매를 호출하면 `THEME_ALREADY_OWNED` 를 반환한다.
- 잔액 부족 시 월렛, 보유 가구, 구매 로그가 모두 롤백된다.
- 테마 일괄 배치는 같은 카테고리 기존 배치를 제거하고 테마 가구로 교체한다.
- 테마 일괄 배치는 미보유 가구가 있으면 아무 배치도 변경하지 않고 실패한다.
