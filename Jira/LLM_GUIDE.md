# JIRA CLI Tools - LLM Guide

## CRITICAL RULES - READ FIRST

### 1. Never read issue bodies from terminal output
Use `search_issues.py`, capture `TEMP_FILE_PATH`, then read the temp markdown file.

### 2. Project scope follows `.env` `JIRA_PROJECT_KEY`
Use the project key from `.env` as the only read and write scope.

- Read operations: only query issues in `JIRA_PROJECT_KEY`
- Write operations: only create, update, or link issues in `JIRA_PROJECT_KEY`
- If a request mentions another project key, rewrite it to the configured project key

### 3. Environment setup comes before Jira commands

- The packaged skill ships only `.env.example`
- If `.env` is missing or still contains placeholders, stop and tell the user to create or edit `.env` from `.env.example`
- Run `bash scripts/ensure_environment.sh` before the first Jira command in a session
- Prefer `./.venv/bin/python` over `python`

### 4. Always change directory first

```bash
cd <LLM current workspace>/Jira
```

### 5. Always apply Jira convention rules
Before create or update operations, read and follow:
`<LLM current workspace>/Jira/jiraconvention.md`

- Enforce issue title convention (Meeting/Docs/Feat/Fix/Refactor/Style/Rename/Remove)
- Enforce story description template (`완료 조건`, `기타`)
- Enforce story point scale and assignment guidance

---

## Setup

### Before first use

**1. Create and validate the local environment**

```bash
cd <LLM current workspace>/Jira
bash scripts/ensure_environment.sh
```

If the script says `.env` is missing or contains placeholders, tell the user to create `.env` from `.env.example` and replace the example values with their own Jira URL, email, API token, and project key.

**2. If Python is missing**

Check whether `python3` or `python` exists. If neither exists, ask the user to install Python 3.11+ first.

**3. Required packages**

`bash scripts/ensure_environment.sh` installs:

- `jira`
- `python-dotenv`

---

## Core Scripts

### `search_issues.py` - primary search tool

Use this for all search and read operations.

```bash
./.venv/bin/python search_issues.py [--project PROJECT] [--filter KEYWORD] [--jql JQL_QUERY]
```

**Parameters**
- `--project`: project key, defaulting to `.env` `JIRA_PROJECT_KEY`
- `--filter`: keyword to search in summary and description
- `--jql`: custom JQL query

**Output format**

```text
TEMP_FILE_PATH:/path/to/temp.md
ISSUE_COUNT:N
```

**Examples**

```bash
./.venv/bin/python search_issues.py --project $JIRA_PROJECT_KEY
./.venv/bin/python search_issues.py --filter "WebSocket"
./.venv/bin/python search_issues.py --jql "project = $JIRA_PROJECT_KEY AND issuetype = Epic"
./.venv/bin/python search_issues.py --jql "assignee = currentUser()"
```

**Always**
1. Run the command
2. Extract `TEMP_FILE_PATH`
3. Read that markdown file
4. Present formatted results to the user

### `create_issues.py` - create issues

```bash
./.venv/bin/python create_issues.py --project PROJECT --summary "TITLE" --description "DESC" [OPTIONS]
```

**Parameters**
- `--project`: required, use `.env` `JIRA_PROJECT_KEY`
- `--summary`: required issue title
- `--description`: issue description
- `--type`: issue type, default `Task`
- `--priority`: `High`, `Medium`, `Low`
- `--points`: story points integer

**Examples**

```bash
./.venv/bin/python create_issues.py --project $JIRA_PROJECT_KEY --summary "Feat: New Feature" \
  --description "## ✅ 완료 조건\n- Item 1" --type Story --priority High --points 8

./.venv/bin/python create_issues.py --project $JIRA_PROJECT_KEY --summary "LLM" --type Epic --priority High
```

### `update_issues.py` - update issues

```bash
./.venv/bin/python update_issues.py --key ISSUE_KEY [OPTIONS]
```

**Parameters**
- `--key`: required issue key such as `<PROJECT_KEY>-3`
- `--status`: example values `진행 중`, `완료`, `해야 할 일`
- `--assign`: `me` or username
- `--comment`: comment text
- `--priority`: `High`, `Medium`, `Low`
- `--points`: story points integer

**Examples**

```bash
./.venv/bin/python update_issues.py --key <PROJECT_KEY>-3 --assign me
./.venv/bin/python update_issues.py --key <PROJECT_KEY>-3 --status "진행 중" --comment "Started work"
./.venv/bin/python update_issues.py --key <PROJECT_KEY>-3 --points 8
```

### `link_epic.py` - link issues to epics

```bash
./.venv/bin/python link_epic.py --issue ISSUE_KEY --epic EPIC_KEY
```

**Example**

```bash
./.venv/bin/python link_epic.py --issue <PROJECT_KEY>-3 --epic <PROJECT_KEY>-1
```

---

## Common Workflows

### 1. Show recent issues

```bash
cd <LLM current workspace>/Jira
bash scripts/ensure_environment.sh
./.venv/bin/python search_issues.py --project $JIRA_PROJECT_KEY
```

### 2. Search by keyword

```bash
cd <LLM current workspace>/Jira
bash scripts/ensure_environment.sh
./.venv/bin/python search_issues.py --filter "WebSocket"
```

### 3. Show my assigned issues

```bash
cd <LLM current workspace>/Jira
bash scripts/ensure_environment.sh
./.venv/bin/python search_issues.py --jql "assignee = currentUser()"
```

### 4. Create a new story

```bash
cd <LLM current workspace>/Jira
bash scripts/ensure_environment.sh
./.venv/bin/python create_issues.py --project $JIRA_PROJECT_KEY --summary "Feat: Feature Name" \
  --description "Details here" --type Story --priority High --points 8 --assign me
```

### 5. Update issue status

```bash
cd <LLM current workspace>/Jira
bash scripts/ensure_environment.sh
./.venv/bin/python update_issues.py --key <PROJECT_KEY>-3 --status "완료"
```

### 6. Create epic and link stories

```bash
cd <LLM current workspace>/Jira
bash scripts/ensure_environment.sh
./.venv/bin/python create_issues.py --project $JIRA_PROJECT_KEY --summary "LLM" --type Epic
./.venv/bin/python create_issues.py --project $JIRA_PROJECT_KEY --summary "Feat: Story" --type Story --points 8
./.venv/bin/python link_epic.py --issue <PROJECT_KEY>-3 --epic <PROJECT_KEY>-1
```

---

## Error Handling

| Error | Solution |
|-------|----------|
| Authentication failure | Check `.env` `JIRA_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` |
| IP not allowed | Contact Jira admin to whitelist the IP |
| Invalid JQL | Check JQL syntax and quote strings correctly |
| UTF-8 encoding error | Use `search_issues.py`, not `read_issues.py` |
| Story points failed | `customfield_10016` may differ in the target Jira instance |
| Python not found | Install Python 3.11+ and rerun setup |
| `jira` module not found | Run `bash scripts/ensure_environment.sh` again |
| `.env` missing or placeholders remain | Tell the user to create or edit `.env` from `.env.example` |

---

## Quick Reference

### Default settings
- Project: `.env` `JIRA_PROJECT_KEY`
- Story points field: `customfield_10016`

### Most common commands

```bash
./.venv/bin/python search_issues.py --project $JIRA_PROJECT_KEY
./.venv/bin/python search_issues.py --filter "KEYWORD"
./.venv/bin/python search_issues.py --jql "issuetype = Epic"

./.venv/bin/python create_issues.py --project $JIRA_PROJECT_KEY --summary "Title" --type Story --points 8

./.venv/bin/python update_issues.py --key KEY --status "완료"
./.venv/bin/python update_issues.py --key KEY --assign me
./.venv/bin/python update_issues.py --key KEY --points 8

./.venv/bin/python link_epic.py --issue STORY_KEY --epic EPIC_KEY
```

### JQL quick examples

```jql
project = <PROJECT_KEY>
project = <PROJECT_KEY> AND issuetype = Epic
project = <PROJECT_KEY> AND status = "해야 할 일"
assignee = currentUser()
key in (<PROJECT_KEY>-1, <PROJECT_KEY>-3)
```

---

## Remember

1. Always use `search_issues.py` plus the temp file for read operations.
2. Always `cd` into the Jira skill directory before running commands.
3. Always keep the read and write scope inside `.env` `JIRA_PROJECT_KEY`.
4. Always read `jiraconvention.md` before create or update operations.
5. Always run `bash scripts/ensure_environment.sh` before the first Jira command in a session.
6. Never generate `.env`; tell the user to create it from `.env.example`.
7. Always present friendly summaries rather than raw terminal output.
