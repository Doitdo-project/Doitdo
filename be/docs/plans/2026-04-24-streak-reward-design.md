# Streak Reward Design

## Goal

7일 단위 스트릭 달성 시 모바일이 호출하는 API를 제공하고, 해당 유저 지갑에 두레딧 100을 지급한다.

## Design

- API: `POST /api/users/me/streak/rewards`
- 지급 조건: 현재 스트릭 수가 7 이상이며 7의 배수일 때만 지급한다.
- 중복 방지: `streak_reward_logs` 테이블에 `user_id`, `streak_start_date`, `streak_count` 유니크 제약을 둔다.
- 실패 후 다시 7일 달성한 경우는 `streak_start_date`가 달라지므로 다시 지급 가능하다.
- 지급 대상: `user_wallets.balance += 100`

## Response

```json
{
  "rewarded": true,
  "streakCount": 7,
  "rewardAmount": 100,
  "balance": 100
}
```

이미 지급했거나 지급 조건이 아니면 `rewarded=false`, `rewardAmount=0`으로 반환한다.
