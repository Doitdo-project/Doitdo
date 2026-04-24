# QUESTION: withdraw 후 잔여 토큰 차단이 실제로 동작하지 않음

**상태**: ESCALATE — 코드 버그 발견, 판단 대기

## 증상

`DELETE /api/users/me` 호출 시 204 응답이 오지만:
- DB의 `users.is_deleted` 가 0으로 남음
- `users.email` / `users.username` 익명화 미실행
- 이후 동일 access token으로 `GET /api/users/me` 호출 시 200 응답 (401/403 아님)

## 근본 원인

`UserServiceImpl.withdraw()` 흐름:

```
user = userRepository.findById(userId)   // user 엔티티 로드 → L1 캐시에 managed 상태
...
userCharacterRepository.softDeleteAllByUserId(userId)  // @Modifying(clearAutomatically = true)
...
categoryRepository.deleteAllByUserId(userId)
...
user.withdraw()   // this.isDeleted = true 등 수정
```

`userCharacterRepository.softDeleteAllByUserId` 에 **`@Modifying(clearAutomatically = true)`** 가 선언되어 있음.  
이 설정은 bulk JPQL UPDATE 후 EntityManager L1 캐시를 전체 삭제(clear)한다.  
→ `user` 엔티티가 **detached** 상태가 됨  
→ 이후 `user.withdraw()` 로 필드를 변경해도 Hibernate dirty-checking이 변경을 감지하지 못함  
→ transaction commit 시 `UPDATE users` 쿼리가 전혀 발행되지 않음

재현: Hibernate show-sql 로그에서 withdraw 전체 시퀀스에 `UPDATE users ...` 가 없음.

## 재현 환경

- `doitdo-local-app` 컨테이너 (2026-04-24 12:45 빌드)
- `DELETE /api/users/me` + `{"currentPassword": "E2ePass!eabdb5cd"}`
- 204 응답 확인
- `SELECT user_id, email, is_deleted+0 FROM users WHERE user_id = 20;` → `is_deleted=0`

## 같은 원인으로 영향받는 파일

- `NotificationRepository.softDeleteAllByUserId` 도 `clearAutomatically = true` → notifications soft delete 후 user 엔티티도 detach됨
- `TodoRepository.softDeleteAllByUserId` 동일

## 수정 방안 (제안)

`UserServiceImpl.withdraw()` 끝에 `user.withdraw()` 호출 후 `userRepository.saveAndFlush(user)` 추가:

```java
// 6. User 익명화 + isDeleted=true
user.withdraw();
userRepository.saveAndFlush(user);  // detached 우회: saveAndFlush로 merge + 즉시 flush
```

또는 `user` 로드를 `deleteAllByUserId` 계열 호출 이후로 이동:

```java
// 모든 hard/soft delete 완료 후 user 다시 로드
user = userRepository.findById(userId)
    .orElseThrow(() -> new CustomException(UserErrorCode.U04_002));
user.withdraw();
```

두 방법 모두 동작. `saveAndFlush` 방식이 더 국소적 변경.

## e2e 처리

- 현재 `be/chore/e2e-sync-current-apis` 브랜치의 e2e 작업에서 **"탈퇴 후 잔여 토큰 401 확인" 스텝은 추가하지 않음**
- 버그 수정 후 별도 커밋에서 추가 예정
- 탈퇴 자체 (`DELETE /api/users/me` → 204 확인) 스텝은 예정대로 추가

## 필요한 결정

1. `UserServiceImpl.withdraw()` 버그 수정을 이 브랜치에서 같이 처리할지, 별도 be/fix/* 브랜치로 분리할지
2. 수정 방안 (`saveAndFlush` vs re-fetch) 중 어느 것을 채택할지
3. e2e의 "잔여 토큰 차단 검증" 스텝을 버그 수정 이후에 추가할지 여부
