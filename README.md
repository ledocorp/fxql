# fxql

**SQLite one-shot query CLI for [fx](https://github.com/ledocorp/fxlang) projects.**

fxql runs a single SQL statement against a file database under `--allow` (FsCap). Product logic is **fx**; rebuild with `fx build … --cli` (shared argv/process spine — no author-written host.c). Dual-path: emit-C and IR.

| | |
|--|--|
| **Requires** | [fx](https://github.com/ledocorp/fxlang) **0.9.6+** (with `--cli`) |
| **Platforms** | Windows + Linux **x86_64** |
| **License** | GPL-3.0 (tool) · SQLite blessing (bundled amalgamation) |
| **Org** | [LedoCorp](http://www.ledocorp.org) |

## Install (release binaries)

1. Install [fx 0.9.6+](https://github.com/ledocorp/fxlang/releases/tag/v0.9.6).  
2. Download the asset for your OS from [Releases](https://github.com/ledocorp/fxql/releases).  
3. Put `bin/windows/fxql.exe` or `bin/linux/fxql` on your `PATH`.

```text
# Windows (PowerShell)
Invoke-WebRequest -Uri https://github.com/ledocorp/fxql/releases/download/v0.1.0/fxql-0.1.0-windows-x86_64.zip -OutFile fxql.zip
Expand-Archive fxql.zip -DestinationPath .
.\bin\windows\fxql.exe --help

# Linux
curl -LO https://github.com/ledocorp/fxql/releases/download/v0.1.0/fxql-0.1.0-linux-x86_64.tar.gz
tar xzf fxql-0.1.0-linux-x86_64.tar.gz
./bin/linux/fxql --help
```

Optional: `fxql-ir` is the IR dual-path binary (same CLI).

## Quick start

```text
fxql --allow . demo.db "SELECT 1 AS n;"
fxql --allow . --tsv demo.db "SELECT name FROM sqlite_master;"
```

Paths must resolve under `--allow`. Errors go to stderr; row output to stdout.

## CLI

| Invocation | Behavior |
|------------|----------|
| `fxql --allow <dir> <db> <sql>` | Open DB under allow; run one statement; print table |
| `fxql --allow <dir> --tsv <db> <sql>` | Same; TSV rows |
| `fxql --help` | Usage |

Exit codes: `0` ok · `1` usage / bad flags · `2` path deny / missing DB · `3` SQL error.

## Rebuild from source

With `fx` 0.9.6+ on `PATH`, `FX_STD_ROOT` pointing at fx `std/`, and access to the SQLite wrap + `host/cap` from an fx checkout:

```text
fx build fxql_lib.fx -o out --emit-c --cli \
  --link <wrap_sqlite>/sqlite_ref.c \
  --link <wrap_sqlite>/third_party/sqlite3.c \
  --link <host>/cap/fx_cap_runtime.c \
  --link-include <wrap_sqlite>/third_party \
  --link-include <host>/cap
```

Same links with `--backend ir` for the IR binary. No author-written `host.c`.

## Non-goals (v1)

REPL · full `.dump` · network DB · ORM · JSON/HTML mode zoo · stdin SQL · macOS prebuilt claim

## Docs

- [docs/FXQL.md](docs/FXQL.md) — design summary  
- [docs/releases/](docs/releases/) — release notes  
- Language: [ledocorp/fxlang](https://github.com/ledocorp/fxlang)

## License

Copyright Shawn Londono · LedoCorp · GPL-3.0 — see [LICENSE](LICENSE).
