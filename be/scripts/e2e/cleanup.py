#!/usr/bin/env python3
import argparse
import os
import re
import shutil
import subprocess
import sys


DEFAULT_PATTERN = r"e2e\_%@e2e.local"
ALLOWED_PATTERN_RE = re.compile(r"^[A-Za-z0-9_\\\-%.@]+$")


TABLES = [
    {
        "name": "notifications",
        "entity": "Notification",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id",
    },
    {
        "name": "device_tokens",
        "entity": "DeviceToken",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id",
    },
    {
        "name": "snooze_history",
        "entity": "SnoozeHistory",
        "condition": "user_id IN ({users}) OR todo_id IN ({todos})",
        "reason": "user_id and todo_id child of todos",
    },
    {
        "name": "purchase_logs",
        "entity": "PurchaseLog",
        "condition": "user_id IN ({users}) OR user_item_id IN ({user_items})",
        "reason": "user_id and user_item_id child of user_items",
    },
    {
        "name": "todos",
        "entity": "Todo",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id, references categories",
    },
    {
        "name": "categories",
        "entity": "Category",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id, parent of todos",
    },
    {
        "name": "character_unlocks",
        "entity": "CharacterUnlock",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id, references characters",
    },
    {
        "name": "user_character",
        "entity": "UserCharacter",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id, may reference user_items via equiped_items_id",
    },
    {
        "name": "user_items",
        "entity": "UserItem",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id, parent of purchase_logs",
    },
    {
        "name": "user_settings",
        "entity": "UserSetting",
        "condition": "user_id IN ({users})",
        "reason": "primary key user_id",
    },
    {
        "name": "user_wallets",
        "entity": "UserWallet",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id",
    },
    {
        "name": "refresh_tokens",
        "entity": "RefreshToken",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id",
    },
    {
        "name": "auto_providers",
        "entity": "AutoProvider",
        "condition": "user_id IN ({users})",
        "reason": "direct user_id",
    },
    {
        "name": "users",
        "entity": "User",
        "condition": "email LIKE '{pattern}'",
        "reason": "target parent rows",
    },
]


ENTITY_TABLE_MAPPING = [
    ("AutoProvider", "auto_providers", "user_id"),
    ("RefreshToken", "refresh_tokens", "user_id"),
    ("Item", "items", "-"),
    ("UserItem", "user_items", "user_id, item_id"),
    ("DeviceToken", "device_tokens", "user_id"),
    ("Notification", "notifications", "user_id"),
    ("UserSetting", "user_settings", "user_id PK"),
    ("PurchaseLog", "purchase_logs", "user_id, user_item_id"),
    ("Character", "characters", "-"),
    ("CharacterAction", "character_actions", "character_id"),
    ("CharacterUnlock", "character_unlocks", "user_id, character_id"),
    ("UserCharacter", "user_character", "user_id, character_id, equiped_items_id"),
    ("Category", "categories", "user_id, color_id"),
    ("Palette", "palettes", "-"),
    ("PaletteColor", "palette_colors", "palette_id"),
    ("SnoozeHistory", "snooze_history", "todo_id, user_id"),
    ("Todo", "todos", "user_id, category_id"),
    ("User", "users", "user_id"),
    ("UserWallet", "user_wallets", "user_id"),
]


def default_env_file():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    be_dir = os.path.abspath(os.path.join(script_dir, "..", ".."))
    return os.path.join(be_dir, "env", "dev.env")


def parse_env_file(path):
    values = {}
    if not os.path.exists(path):
        return values
    with open(path, "r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip()
    return values


def parse_args():
    parser = argparse.ArgumentParser(
        description="Delete e2e_*@e2e.local users and related rows from the Doitdo DB"
    )
    parser.add_argument("--yes", action="store_true", help="execute DELETE statements")
    parser.add_argument("--env-file", default=default_env_file(), help="Spring properties env file")
    parser.add_argument("--pattern", default=DEFAULT_PATTERN, help="SQL LIKE pattern for target emails")
    parser.add_argument("--host", help="DB host override")
    parser.add_argument("--port", help="DB port override")
    parser.add_argument("--db", help="DB name override")
    parser.add_argument("--user", help="DB user override")
    parser.add_argument("--password", help="DB password override")
    return parser.parse_args()


def resolve_config(args):
    env_values = parse_env_file(args.env_file)
    config = {
        "host": env_values.get("db.host"),
        "port": env_values.get("db.port"),
        "db": env_values.get("db.name"),
        "user": env_values.get("db.username"),
        "password": env_values.get("db.password"),
    }
    for key in ("host", "port", "db", "user", "password"):
        override = getattr(args, key)
        if override:
            config[key] = override

    missing = [key for key, value in config.items() if not value]
    if missing:
        raise ValueError("DB 접속정보 누락: %s" % ", ".join(missing))
    return config


def validate_pattern(pattern):
    if not ALLOWED_PATTERN_RE.match(pattern):
        raise ValueError("pattern contains disallowed characters")


def sql_quote(value):
    return "'" + value.replace("'", "''") + "'"


def ensure_mysql():
    if shutil.which("mysql"):
        return
    print("mysql 클라이언트가 설치되어 있지 않습니다.")
    print("Ubuntu/WSL:   sudo apt install -y mysql-client")
    print("MacOS:        brew install mysql-client")
    sys.exit(1)


def run_mysql(config, sql):
    env = os.environ.copy()
    env["MYSQL_PWD"] = config["password"]
    cmd = [
        "mysql",
        "-h",
        config["host"],
        "-P",
        str(config["port"]),
        "-u",
        config["user"],
        config["db"],
        "--batch",
        "--skip-column-names",
        "-e",
        sql,
    ]
    return subprocess.run(cmd, env=env, check=True, capture_output=True, text=True)


def scalar(config, sql):
    result = run_mysql(config, sql)
    output = result.stdout.strip()
    if output == "":
        return 0
    first = output.splitlines()[0].strip()
    return int(first or "0")


def table_exists(config, table_name):
    sql = (
        "SELECT COUNT(*) FROM information_schema.tables "
        "WHERE table_schema = DATABASE() AND table_name = %s" % sql_quote(table_name)
    )
    return scalar(config, sql) > 0


def build_fragments(pattern_sql):
    users = "SELECT user_id FROM users WHERE email LIKE %s" % pattern_sql
    todos = "SELECT todo_id FROM todos WHERE user_id IN (%s)" % users
    user_items = "SELECT user_item_id FROM user_items WHERE user_id IN (%s)" % users
    return {"pattern": pattern_sql.strip("'"), "users": users, "todos": todos, "user_items": user_items}


def condition_sql(table_info, fragments):
    return table_info["condition"].format(**fragments)


def existing_cleanup_tables(config):
    existing = []
    for table_info in TABLES:
        if table_exists(config, table_info["name"]):
            existing.append(table_info)
    return existing


def collect_counts(config, tables, fragments):
    counts = {}
    for table_info in tables:
        condition = condition_sql(table_info, fragments)
        counts[table_info["name"]] = scalar(
            config, "SELECT COUNT(*) FROM %s WHERE %s" % (table_info["name"], condition)
        )
    return counts


def print_mapping():
    print("엔티티→테이블 매핑:")
    for entity, table, refs in ENTITY_TABLE_MAPPING:
        print("  %-18s -> %-20s %s" % (entity, table, refs))
    print("")


def print_report(tables, counts, target_users, dry_run):
    print("대상 users: %d 명" % target_users)
    print("영향:")
    for table_info in tables:
        name = table_info["name"]
        print("  %-22s %8d" % (name + ":", counts.get(name, 0)))
    print("")
    print("삭제 순서:")
    for idx, table_info in enumerate(tables, start=1):
        print("  %2d. %-20s (%s)" % (idx, table_info["name"], table_info["reason"]))
    print("")
    if dry_run:
        print("dry-run: 실제 DELETE 는 실행하지 않았습니다. 실행하려면 --yes 를 사용하세요.")


def execute_delete(config, tables, fragments):
    statements = ["START TRANSACTION"]
    for table_info in tables:
        condition = condition_sql(table_info, fragments)
        statements.append("DELETE FROM %s WHERE %s" % (table_info["name"], condition))
    statements.append("COMMIT")
    sql = ";\n".join(statements) + ";"
    run_mysql(config, sql)


def print_deleted(counts):
    parts = []
    for table_info in TABLES:
        name = table_info["name"]
        if name in counts:
            parts.append("%s %d" % (name, counts[name]))
    print("삭제 완료 — " + ", ".join(parts))


def main():
    args = parse_args()
    try:
        validate_pattern(args.pattern)
        config = resolve_config(args)
    except ValueError as exc:
        print("설정 오류: %s" % exc, file=sys.stderr)
        return 1

    ensure_mysql()

    pattern_sql = sql_quote(args.pattern)
    fragments = build_fragments(pattern_sql)

    try:
        if not table_exists(config, "users"):
            print("users 테이블이 없습니다.")
            return 0

        tables = existing_cleanup_tables(config)
        target_users = scalar(config, "SELECT COUNT(*) FROM users WHERE email LIKE %s" % pattern_sql)

        print_mapping()
        if target_users == 0:
            print("대상 없음")
            return 0

        counts = collect_counts(config, tables, fragments)
        print_report(tables, counts, target_users, dry_run=not args.yes)

        if not args.yes:
            return 0

        execute_delete(config, tables, fragments)
        print_deleted(counts)
        return 0
    except subprocess.CalledProcessError as exc:
        print("mysql 실행 실패", file=sys.stderr)
        if exc.stderr:
            print(exc.stderr.strip(), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
