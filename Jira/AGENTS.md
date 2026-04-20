# Workspace Skills Bootstrap

- If the user explicitly mentions `Jira` or `지라` and `~/.codex/skills/jira/SKILL.md` does not exist, install the local Jira skill first by running `bash /mnt/c/ssafy/특화/Jira/scripts/install_local_skill.sh`.
- After installing, use `/mnt/c/ssafy/특화/Jira/SKILL.md` for the current session and tell the user to restart Codex so the installed skill is auto-discovered in later sessions.
- Do not copy or generate `.env` during installation. The installed skill must ship only `.env.example`, and the user must create `.env` from that template with their own Jira values.
