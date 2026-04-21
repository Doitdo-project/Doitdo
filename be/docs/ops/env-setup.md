# 환경 셋업 (env-setup)

로컬 개발 환경 준비. 한 번만 하면 된다.

## 1. JDK 21

시스템에 OpenJDK 21이 있어야 한다. 위치 예시:

```bash
/usr/lib/jvm/java-21-openjdk-amd64
```

`JAVA_HOME` 을 셸 rc(`.bashrc`/`.zshrc`)에 영구 등록하거나, 실행 시 inline 으로 지정해도 된다 ([run-local.md](run-local.md) 참고).

## 2. env 파일

DB 접속정보는 git에 올리지 않는다. 템플릿을 복사해 채워 사용한다.

```bash
cp be/env/dev.env.example be/env/dev.env
# 편집기로 열어서 DB 호스트/유저/비밀번호 입력
```

| 파일 | 용도 | git 추적 |
|---|---|---|
| `env/dev.env.example` | 템플릿 (키만, 값 비움) | O |
| `env/dev.env` | 로컬 dev 프로파일 실제 값 | X (gitignore) |
| `env/prod.env.example` | 운영용 템플릿 | O |

로딩 위치: `src/main/resources/application-dev.properties` 의 `spring.config.import` 가 `env/dev.env` 를 읽는다.

## 3. DB 접근 확인

dev 프로파일은 원격 테스트 DB(`168.107.48.80`)에 붙는다. VPN/방화벽 정책으로 접근이 막혀 있으면 부팅 실패하니 사전에 확인할 것.

## 4. (선택) IDE 코드 스타일

IntelliJ 에서 프로젝트 제공 `code-style.xml` 을 import 한다. 자세한 네이밍/포맷 규칙은 [`../conventions/naming.md`](../conventions/naming.md).
