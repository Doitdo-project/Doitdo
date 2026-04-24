# Streak Reward Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 7일 단위 스트릭 보상 API를 추가해 유저 지갑에 두레딧 100을 지급한다.

**Architecture:** 기존 `streak` 도메인 컨트롤러/서비스에 보상 API를 추가한다. 중복 지급은 `streak_reward_logs` 엔티티와 `(user_id, streak_start_date, streak_count)` 유니크 키로 막는다.

**Tech Stack:** Spring Boot 3.5.13, Java 21, Spring Data JPA, JUnit 5, Mockito.

---

### Task 1: Service Test

**Files:**
- Create: `src/test/java/com/doitdo/domain/streak/application/impl/UserStreakServiceImplRewardTest.java`

**Step 1:** 7일 스트릭이면 보상 로그 저장, 지갑 잔액 +100, 응답 `rewarded=true` 검증.

**Step 2:** 같은 구간 7일 보상을 이미 받은 경우 잔액이 증가하지 않고 `rewarded=false` 검증.

**Step 3:** 6일 스트릭이면 지급하지 않음 검증.

### Task 2: Domain Model

**Files:**
- Create: `src/main/java/com/doitdo/domain/streak/entity/StreakRewardLog.java`
- Create: `src/main/java/com/doitdo/domain/streak/repository/StreakRewardLogRepository.java`
- Modify: `src/main/java/com/doitdo/domain/user/entity/UserWallet.java`
- Modify: `src/main/java/com/doitdo/domain/user/repository/UserWalletRepository.java`

**Step 1:** 보상 로그 엔티티와 조회 메서드 추가.

**Step 2:** `UserWallet.addBalance(int amount)` 추가.

### Task 3: Service/API

**Files:**
- Create: `src/main/java/com/doitdo/domain/streak/api/dto/resp/StreakRewardResp.java`
- Modify: `src/main/java/com/doitdo/domain/streak/application/UserStreakService.java`
- Modify: `src/main/java/com/doitdo/domain/streak/application/impl/UserStreakServiceImpl.java`
- Modify: `src/main/java/com/doitdo/domain/streak/api/controller/UserStreakController.java`

**Step 1:** `claimSevenDayReward(Long userId)` 서비스 추가.

**Step 2:** `POST /api/users/me/streak/rewards` 컨트롤러 추가.

### Task 4: Verify

Run:

```powershell
.\gradlew test --tests "com.doitdo.domain.streak.application.impl.UserStreakServiceImplRewardTest"
.\gradlew test
```
