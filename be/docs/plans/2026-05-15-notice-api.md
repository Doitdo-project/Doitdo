# Notice API Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 앱 초기 진입 공지 모달, 설정 화면 공지 목록/상세, 공지별 다시 안보기를 제공한다.

**Architecture:** `notice` 신규 도메인을 추가한다. 공지 등록은 관리자 API 없이 DB 직접 입력으로 처리하고, 앱은 조회/다시 안보기 API만 사용한다. `notices`는 공지 원본, `notice_dismissals`는 사용자별 공지 숨김 상태를 저장한다.

**Tech Stack:** Spring Boot 3.5, Java 21, Spring Data JPA, MariaDB, springdoc-openapi, JUnit.

---

### Task 1: Documentation Baseline

**Files:**
- Modify: `be/docs/architecture/package-layout.md`
- Modify: `be/docs/architecture/erd.md`
- Modify: `be/docs/api/swagger.md`
- Modify: `be/docs/api/response-format.md`
- Create: `be/docs/ops/migrations/2026-05-15-notice.sql`

**Steps:**
1. Add the `notice` domain to the registered domain list and implementation file table.
2. Document `notices` and `notice_dismissals` in ERD.
3. Document the four endpoints:
   - `GET /api/notices/latest-popup`
   - `GET /api/notices`
   - `GET /api/notices/{noticeId}`
   - `POST /api/notices/{noticeId}/dismiss`
4. Add migration SQL for the two tables and `(user_id, notice_id)` unique key.

### Task 2: Failing Service Tests

**Files:**
- Create: `be/src/test/java/com/doitdo/domain/notice/application/impl/NoticeServiceImplTest.java`

**Steps:**
1. Write tests for latest popup returning `show=true` with latest active notice.
2. Write tests for latest popup returning `show=false` when dismissed.
3. Write tests for listing active notices newest first.
4. Write tests for detail lookup and not-found behavior.
5. Write tests for idempotent dismiss.
6. Run the test and verify it fails because notice classes do not exist yet.

### Task 3: Notice Domain

**Files:**
- Create: `be/src/main/java/com/doitdo/domain/notice/entity/Notice.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/entity/NoticeDismissal.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/repository/NoticeRepository.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/repository/NoticeDismissalRepository.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/api/dto/resp/NoticeResp.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/api/dto/resp/NoticeListResp.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/api/dto/resp/NoticePopupResp.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/application/NoticeService.java`
- Create: `be/src/main/java/com/doitdo/domain/notice/application/impl/NoticeServiceImpl.java`
- Create: `be/src/main/java/com/doitdo/global/exception/NoticeErrorCode.java`
- Modify: `be/src/main/java/com/doitdo/global/exception/ErrorCodeRegistry.java`

**Steps:**
1. Implement entities using existing entity conventions.
2. Store FK values as `Long`, not `@ManyToOne`.
3. Implement active notice queries with `isActive=true`, started/ended window, newest first.
4. Implement dismissal existence check and idempotent save.
5. Register `NoticeErrorCode`.
6. Run service tests and verify pass.

### Task 4: Controller And Swagger Group

**Files:**
- Create: `be/src/main/java/com/doitdo/domain/notice/api/controller/NoticeController.java`
- Modify: `be/src/main/java/com/doitdo/global/config/OpenApiConfig.java`

**Steps:**
1. Add controller under `com.doitdo.domain.notice.api.controller`.
2. Return `GlobalApiResponse<T>` for all endpoints.
3. Add `notice` `GroupedOpenApi`.
4. Add `@ApiErrorCodes` for not-found detail/dismiss paths.
5. Run tests and compile.

### Task 5: Verification

**Commands:**
- `./gradlew test`
- `./gradlew compileJava`

**Expected:**
- Notice service tests pass.
- Java compilation succeeds.

**Commit:** Do not run git add, commit, or push in this workspace.
