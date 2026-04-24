# Phase 2 Notion 최신화 Payload (2026-04-24)

> **주의**: 이 문서는 read-only 분석 결과다. 아래 payload는 사용자 재승인 후 apply 에이전트가 실행한다.

---

## 항목 1 — N-1: Git Convention 페이지 (커밋 메시지 형식 설명)

- 페이지 ID: `3448ab5f-e9a9-8068-bf77-d1f7a8164045`
- 총 블록 수: 91개 (has_more: false)

### 현재 상태 분석

N-1 페이지에는 `"콜론(`:`)과 공백(` `)으로 구분"` 같은 **메타 설명 문구가 별도 블록으로 존재하지 않는다**.
대신 커밋 형식 자체가 아래 블록들로 표현되어 있다.

#### 핵심 대상 블록: 작성 형식 paragraph

| 항목 | 값 |
|------|-----|
| block_id | `3f0b93b3-3a3a-4515-ab8e-87b6a8ec47eb` |
| type | `paragraph` |
| has_children | `false` |

**현재 rich_text (verbatim)**:
```json
[
  {
    "type": "text",
    "text": { "content": "type : (위치/기능) + 설명", "link": null },
    "annotations": {
      "bold": false, "italic": false, "strikethrough": false,
      "underline": false, "code": false, "color": "default"
    }
  }
]
```
현재 텍스트: `"type : (위치/기능) + 설명"`

### 제안 변경

태스크 목표("Type과 Subject 사이는 콜론(` : `) 앞뒤 공백 1개씩")에 맞춰
기존 형식 블록에 설명 문구를 **추가**하는 방향을 권장한다.

**옵션 A — 기존 블록 텍스트에 설명 삽입**

변경 후 텍스트: `"type : (위치/기능) + 설명"`  
→ 이 형식 자체는 이미 올바르게 ` : ` 앞뒤 공백 포함. **실질 변경 불필요**.

**옵션 B — 설명 bulleted 블록 새로 추가** (권장)

`a97d146d` 헤딩 바로 아래(`3f0b93b3` 이전)에 설명 bullet 추가:

- 추가할 내용: `"Type 과 Subject 사이는 콜론(` : `) 앞뒤 공백 1개씩 표기한다."`

사용할 MCP: `API-patch-block-children` (parent: `a97d146d` or `29bc9f84`)  
또는 `API-update-a-block` (기존 블록 내용 수정)

**옵션 B payload 스니펫 (신규 bullet 삽입)**:
```json
{
  "after": "3f0b93b3-3a3a-4515-ab8e-87b6a8ec47eb",
  "children": [
    {
      "type": "bulleted_list_item",
      "bulleted_list_item": {
        "rich_text": [
          {
            "type": "text",
            "text": { "content": "Type 과 Subject 사이는 콜론(" },
            "annotations": {
              "bold": false, "italic": false, "strikethrough": false,
              "underline": false, "code": false, "color": "default"
            }
          },
          {
            "type": "text",
            "text": { "content": " : " },
            "annotations": {
              "bold": false, "italic": false, "strikethrough": false,
              "underline": false, "code": true, "color": "default"
            }
          },
          {
            "type": "text",
            "text": { "content": ") 앞뒤 공백 1개씩 표기한다." },
            "annotations": {
              "bold": false, "italic": false, "strikethrough": false,
              "underline": false, "code": false, "color": "default"
            }
          }
        ]
      }
    }
  ]
}
```

### 모호점 — 사용자 재승인 필요

- **N-1은 실질적으로 기존 텍스트가 이미 ` : ` 형식을 올바르게 따르고 있음**.  
  "설명 문구(메타 설명)"를 추가할 것인지, 아니면 기존 예시 블록들을 확인/유지로 처리할 것인지 확인 필요.
- 예시 블록들(`5db17476`, `b6765b2b`, `34e176ea`, `f3626aec`, `18cbbb47`, `310c26e3`, `524890fd`)도 이미 `feat : ...` 형식으로 ` : ` 앞뒤 공백이 올바르게 적용되어 있음.

---

## 항목 2 — N-2: BE 규칙 페이지 패키지명 갱신

- 페이지 ID: `3458ab5f-e9a9-80b7-a026-f4652db8b2c8`
- 총 블록 수: 5개 (has_more: false)

### 현재 상태

페이지 내 블록 목록:

| # | block_id | type | 내용 요약 |
|---|----------|------|----------|
| 1 | `3458ab5f-e9a9-80ab-a72d-e90254df730f` | divider | (구분선) |
| 2 | `3458ab5f-e9a9-80c4-95e4-c852813b861c` | paragraph | (빈 paragraph) |
| 3 | `3458ab5f-e9a9-80c6-bc9e-d245ce278250` | heading_3 | `"doitdo 로 수정 해야함"` |
| 4 | `3458ab5f-e9a9-80b7-8930-e9ff5a011784` | paragraph | (빈 paragraph) |
| 5 | `3458ab5f-e9a9-8045-abee-cf7769b758bf` | code | 전체 패키지 구조 가이드 (markdown 형식) |

#### 메모 H3 블록 (block 3)

| 항목 | 값 |
|------|-----|
| block_id | `3458ab5f-e9a9-80c6-bc9e-d245ce278250` |
| type | `heading_3` |
| 현재 텍스트 | `"doitdo 로 수정 해야함"` |
| 처리 방안 | 코드 블록 갱신 완료 후 **삭제 필요** (용도 소멸) |

#### 코드 블록 (block 5) — 주요 변경 대상

| 항목 | 값 |
|------|-----|
| block_id | `3458ab5f-e9a9-8045-abee-cf7769b758bf` |
| type | `code` |
| language | `markdown` |
| com.woojudraw 등장 | **2회** (1. Base Package 섹션, 2. Package Structure Overview 섹션) |
| com/woojudraw 등장 | **1회** (src/main/java/com/woojudraw) |
| WoojudrawApplication 등장 | **1회** (WoojudrawApplication.java) |

**현재 코드 블록 상단부 (verbatim)**:
```
# Backend Package Structure Guide

## 1. Base Package

백엔드의 최상위 패키지는 다음과 같이 구성한다.

```
com.woojudraw
```

예시

```
src/main/java/com/woojudraw
 ├ WoojudrawApplication.java
 ├ domain
 └ global
```

# 2. Package Structure Overview

프로젝트는 **DDD 스타일 기반의 Layered Architecture**로 구성한다.

```
com.woojudraw
 ├ domain
 │   └ {domain}
   ...
```
```

### 제안 변경

치환 규칙:
- `com.woojudraw` → `com.doitdo` (2회)
- `com/woojudraw` → `com/doitdo` (1회)
- `WoojudrawApplication` → `DoitdoApplication` (1회)

**변경 후 상단부 예시**:
```
# Backend Package Structure Guide

## 1. Base Package

백엔드의 최상위 패키지는 다음과 같이 구성한다.

```
com.doitdo
```

예시

```
src/main/java/com/doitdo
 ├ DoitdoApplication.java
 ├ domain
 └ global
```
```

사용할 MCP: `API-update-a-block`  
block_id: `3458ab5f-e9a9-8045-abee-cf7769b758bf`

**payload 스니펫 (code 블록 업데이트)**:
```json
{
  "code": {
    "rich_text": [
      {
        "type": "text",
        "text": {
          "content": "<전체 코드 내용 — com.woojudraw→com.doitdo, com/woojudraw→com/doitdo, WoojudrawApplication→DoitdoApplication 치환 후 전문>"
        },
        "annotations": {
          "bold": false, "italic": false, "strikethrough": false,
          "underline": false, "code": false, "color": "default"
        }
      }
    ],
    "language": "markdown"
  }
}
```

> **주의**: `language: "markdown"` 반드시 보존. rich_text 배열은 단일 원소.

#### H3 메모 블록 삭제 payload

사용할 MCP: `API-delete-a-block`  
block_id: `3458ab5f-e9a9-80c6-bc9e-d245ce278250`

```json
{
  "block_id": "3458ab5f-e9a9-80c6-bc9e-d245ce278250"
}
```

---

## 항목 3 — N-4: API 기본 명세서(구) 페이지 휴지통 이동

### 검색 결과

`post-search` query=`"API 기본 명세서"` 결과에서 제목이 `"API 기본 명세서(구)"`인 페이지 확인:

| 항목 | 값 |
|------|-----|
| page_id | `ac28ab5f-e9a9-83e9-9dae-81d6bbda2953` |
| 제목 | `API 기본 명세서(구)` |
| URL | https://www.notion.so/API-ac28ab5fe9a983e99dae81d6bbda2953 |
| 생성일 | 2026-04-14T00:12:00.000Z |
| 최종 편집 | 2026-04-14T05:26:00.000Z |
| 부모 | page_id: `cb98ab5f-e9a9-8245-8b92-81a741ef019a` |
| is_archived | false / in_trash: false |

신버전 `API 기본 명세서`(page_id: `3428ab5f-e9a9-80c7-90a6-f9161a900f22`)와 구분됨.

### 하위 트리 규모

직속 자식 블록 분석 결과:

| block_id | type | 내용 |
|----------|------|------|
| `3428ab5f-e9a9-80e1-aced-e603e628f450` | child_database | `"엔드포인트 (2)"` |
| `3428ab5f-e9a9-80b5-a2fe-e0fc8d726712` | child_page | `"공통양식 (1)"` (has_children: true) |
| `3428ab5f-e9a9-80a9-89b4-f8eca321c795` | child_page | `"글로벌"` (has_children: true) |
| 기타 | paragraph, heading_2, heading_3, numbered_list_item, column_list 등 | 템플릿 소개 본문 |

- **child_database 1개** (`엔드포인트 (2)`)
- **child_page 2개** (`공통양식 (1)`, `글로벌`) — 각 페이지 내부에도 하위 자식 있음

### Backlink / 참조 여부

Notion Public API는 backlink 직접 조회 기능을 제공하지 않는다.  
**UI 수동 확인 필요** — 실제 archive 전 Notion UI에서 해당 페이지의 backlink 탭 확인 권장.

### 추천 방법

**`API-patch-page` + `archived: true`** 권장 (delete-a-block 보다 안전)

근거:
- page 리소스는 `patch-page`의 `archived` 필드로 휴지통 이동하는 것이 Notion 관용적 방법
- `delete-a-block`도 동일하게 archive되지만, page를 block으로 다루는 방식은 혼동을 유발
- 둘 다 복구 가능 (Notion 휴지통에서 30일 이내 복구 가능)
- archive는 **하위 child_page, child_database까지 cascade** 적용됨 → `공통양식 (1)`, `글로벌` 페이지 및 `엔드포인트 (2)` DB도 함께 휴지통 이동

**payload 스니펫**:
```json
{
  "page_id": "ac28ab5f-e9a9-83e9-9dae-81d6bbda2953",
  "archived": true
}
```

사용할 MCP: `API-patch-page`

---

## 주의 · 모호점 (사용자 재승인 필요 사항)

1. **N-1 변경 범위 불명확**: 현재 N-1 페이지에 `"콜론(`:`)과 공백(` `)으로 구분"` 같은 메타 설명 문구가 별도 블록으로 존재하지 않는다. 기존 예시/형식 블록들은 이미 ` : ` 앞뒤 공백을 올바르게 사용 중. → **설명 bulleted 블록을 신규 추가할지**, 아니면 **"이미 올바른 상태"로 N-1 을 skip할지** 사용자 판단 필요.

2. **N-4 cascade 범위 확인**: `API 기본 명세서(구)` archive 시 child_page 2개(`공통양식 (1)`, `글로벌`) + child_database 1개(`엔드포인트 (2)`)가 함께 휴지통 이동된다. 의도한 범위인지 확인 필요.

3. **N-4 backlink**: Notion API로 backlink를 직접 조회할 수 없으므로, 다른 페이지에서 `API 기본 명세서(구)`를 링크/참조하는 경우 dangling link가 발생할 수 있다. Notion UI 수동 확인 권장.

4. **N-2 WoojudrawApplication → DoitdoApplication 치환 범위**: 코드 블록 내 `WoojudrawApplication.java` 항목을 `DoitdoApplication.java`로 치환 포함 여부 확인 (패키지명 외 클래스명도 포함하는지).

---

## 다음 단계

사용자 재승인 후, apply 에이전트가 N-2 `API-update-a-block` → N-2 H3 `API-delete-a-block` → N-4 `API-patch-page archived:true` → N-1 처리 순으로 실행한다.
