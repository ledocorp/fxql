# fxql — user design summary

fxql is a **one-shot SQLite CLI**: open a file DB under `--allow`, run one SQL statement, print rows (table or TSV). It is not an interactive `sqlite3` shell.

## Why fxql

| Keep | Refuse (v1) |
|------|-------------|
| Required `--allow` + FsCap | Ambient filesystem |
| One statement, quiet success | REPL / multi-statement product surface |
| Table + `--tsv` | JSON/HTML mode zoo |
| fx for logic; `--cli` for argv | Per-tool host.c |
| Dual-path emit-C + IR | Optional-IR theater |

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | ok |
| 1 | usage / bad flags |
| 2 | path outside allow / open denied / missing DB |
| 3 | SQL / SQLite error |

## Rebuild

See root README. Needs fx 0.9.6+ with `--cli`, `host/cap`, and the SQLite amalgamation wrap.

## Non-goals

REPL · `.dump` · network DB · ORM · macOS claim
