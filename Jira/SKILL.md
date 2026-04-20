---
name: jira
description: Use when the user explicitly mentions Jira or 지라, or asks to search, create, update, assign, link, or review Jira issues, epics, sprints, and project work with the bundled local Jira CLI tools.
---

# Jira

## Overview

Use this skill only for explicit Jira or 지라 requests. The skill bundles the local Jira CLI scripts, validates the environment, and enforces the project-scoped read/write workflow.

## First Run

1. Work from this skill directory.
2. Run `bash scripts/ensure_environment.sh`.
3. If the script reports missing or placeholder `.env` values, stop and tell the user to create `.env` from `.env.example` and fill in their own Jira values.
4. Read `LLM_GUIDE.md` before executing Jira operations.
5. For create, update, assign, comment, or epic-link requests, also read `jiraconvention.md` first.

## Environment Rules

- Ship only `.env.example`. Do not create or commit `.env` on the user's behalf.
- Keep credentials local to this installed skill directory.
- Prefer `./.venv/bin/python` for every bundled Python script.
- If `scripts/ensure_environment.sh` fails, surface the exact error and stop instead of guessing.

## Read Workflow

- Always use `search_issues.py` for read operations.
- Never trust terminal-rendered issue bodies. Parse `TEMP_FILE_PATH`, then read the temp markdown file.
- Keep the project scope pinned to `.env` `JIRA_PROJECT_KEY`. Rewrite other project keys to the local configured project.
- Present results in a human summary, not raw terminal output.

## Write Workflow

- Read `jiraconvention.md` first.
- Create issues with `create_issues.py`.
- Update status, assignee, priority, comments, or story points with `update_issues.py`.
- Link stories and tasks to epics with `link_epic.py`.
- Keep all issue keys within `.env` `JIRA_PROJECT_KEY`.

## Bundled Files

- `scripts/install_local_skill.sh`: copies this directory into `~/.codex/skills/jira` without copying `.env`
- `scripts/ensure_environment.sh`: creates `.venv`, installs dependencies, and validates `.env`
- `LLM_GUIDE.md`: operational command rules and examples
- `jiraconvention.md`: issue naming, description template, and story-point rules
