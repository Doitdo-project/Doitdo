# JIRA CLI 도구

JIRA API를 사용하여 이슈를 조회, 생성, 수정하는 Python 스크립트 모음입니다.

사용자는 LLM에게 "JIRA 최근 이슈 알려줘"와 같이 요청하면, LLM이 이 도구를 사용하여 결과를 제공합니다.

---

## 사용자 가이드

### 설정

`.env.example`를 참고해 `.env`를 직접 만들고 본인 값을 입력하세요:

```bash
cp .env.example .env
```

그 다음 `.env`에 아래 값을 채웁니다.

```env
JIRA_URL=https://your-company.atlassian.net
JIRA_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-api-token-here
JIRA_PROJECT_KEY=YOUR_PROJECT_KEY
```

LLM 또는 사용자는 먼저 아래 명령으로 환경을 준비합니다.

```bash
bash scripts/ensure_environment.sh
```

API 토큰 생성: https://id.atlassian.com/manage-profile/security/api-tokens

### LLM에게 요청하는 방법

다음과 같이 자연어로 요청하세요:

- "JIRA 최근 이슈 10개 알려줘"
- "MCP 프로젝트의 진행 중인 이슈 보여줘"
- "나에게 할당된 이슈 목록 확인해줘"
- "AI 관련 이슈만 검색해줘"
- "새로운 Task 이슈 만들어줘"
- "MCP-01 이슈 상태를 In Progress로 변경해줘"

LLM이 적절한 스크립트를 실행하여 결과를 제공합니다.

### LLM 사용 전 필수 설정

JIRA 도구를 사용하기 전에 LLM에게 다음 프롬프트를 먼저 제공하세요:

```
Jira/LLM_GUIDE.md 파일을 읽고 JIRA 도구 사용법을 숙지해줘.
```

이후 자유롭게 JIRA 관련 요청을 하면 됩니다.
