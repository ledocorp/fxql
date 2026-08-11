// fxql_lib — SQLite query CLI under FsCap (--cli auto-host).
// Public design: docs/FXQL.md (this tree) · fxlang host/cli + host/cap
// Rebuild: fx build fxql_lib.fx -o out --emit-c --cli (+ wrap/cap links; no author host.c).
module fxql_lib;

using core;
import std/io;
import std/string;
import std/strutil;

extern "c" {
    fn fx_cli_argc() -> i32;
    fn fx_cli_arg(i: i32) -> string;
    effects { alloc } fn fx_guest_begin(root: string, arena_bytes: i64) -> i64;
    effects { alloc } fn fx_guest_end(ctx_handle: i64) -> i32;
    effects { alloc } fn fx_guest_mint_fscap(ctx_handle: i64, root: string) -> i64;
    fn fx_sqlite_open_fscap(fs_handle: i64, path: string) -> i32;
    fn fx_sqlite_exec(h: i32, sql: string) -> i32;
    fn fx_sqlite_query_print_tsv(h: i32, sql: string) -> i32;
    fn fx_sqlite_query_print_table(h: i32, sql: string) -> i32;
    fn fx_sqlite_close(h: i32) -> i32;
}

fn eq(a: string, b: string) -> bool {
    return string.compare(a, b);
}

fn usage() -> i32 effects { io } {
    let _u = io.write_err("usage: fxql --allow <dir> [--tsv] <db-path> <sql>");
    return 1;
}

fn path_has_dotdot(s: string) -> bool {
    return strutil.contains(s, "..");
}

/// Cap paths must be `allow/...`. Join relative db under allow when needed.
fn resolve_db_path(allow: string, db: string) -> Result<string, core_Err> effects { alloc } {
    let al = string.len(allow);
    let dl = string.len(db);
    if (dl > al) {
        if (strutil.starts_with(db, allow) == true) {
            let c = string.byte_at(db, al);
            if (c == 47) {
                return Ok(db);
            }
            if (c == 92) {
                return Ok(db);
            }
        }
    }
    let mid = string.concat(allow, "/")?;
    return string.concat(mid, db);
}

fn looks_like_query(sql: string) -> bool {
    let n = string.len(sql);
    let i: i32 = 0;
    while (i < n) {
        let c = string.byte_at(sql, i);
        if (c != 32) {
            if (c != 9) {
                if (c != 10) {
                    if (c != 13) {
                        break;
                    }
                }
            }
        }
        i = i + 1;
    }
    if (i + 6 > n) {
        return false;
    }
    // SELECT / select / WITH / with (CTE)
    let c0 = string.byte_at(sql, i);
    let c1 = string.byte_at(sql, i + 1);
    let c2 = string.byte_at(sql, i + 2);
    let c3 = string.byte_at(sql, i + 3);
    let c4 = string.byte_at(sql, i + 4);
    let c5 = string.byte_at(sql, i + 5);
    if (c0 == 83 || c0 == 115) {
        if (c1 == 69 || c1 == 101) {
            if (c2 == 76 || c2 == 108) {
                if (c3 == 69 || c3 == 101) {
                    if (c4 == 67 || c4 == 99) {
                        if (c5 == 84 || c5 == 116) {
                            return true;
                        }
                    }
                }
            }
        }
    }
    if (c0 == 87 || c0 == 119) {
        if (c1 == 73 || c1 == 105) {
            if (c2 == 84 || c2 == 116) {
                if (c3 == 72 || c3 == 104) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn run_query(allow: string, path: string, sql: string, tsv: i32) -> i32 effects { alloc, io } {
    let g = fx_guest_begin(allow, 65536);
    if (g == 0) {
        let _g = io.write_err("fxql: guest begin failed");
        return 2;
    }
    let fs = fx_guest_mint_fscap(g, "");
    if (fs == 0) {
        let _e0 = fx_guest_end(g);
        let _f = io.write_err("fxql: mint_fs failed");
        return 2;
    }
    let h = fx_sqlite_open_fscap(fs, path);
    if (h == -5) {
        let _e1 = fx_guest_end(g);
        let _d = io.write_err("fxql: open denied or path outside allow");
        return 2;
    }
    if (h < 1) {
        let _e2 = fx_guest_end(g);
        let _o = io.write_err("fxql: open failed");
        return 2;
    }
    let st: i32 = 0;
    if (looks_like_query(sql) == true) {
        if (tsv != 0) {
            st = fx_sqlite_query_print_tsv(h, sql);
        } else {
            st = fx_sqlite_query_print_table(h, sql);
        }
    } else {
        st = fx_sqlite_exec(h, sql);
    }
    let _c = fx_sqlite_close(h);
    let _en = fx_guest_end(g);
    if (st != 0) {
        let _s = io.write_err("fxql: sql error");
        return 3;
    }
    return 0;
}

fn cli_main() -> Result<i32, core_Err> effects { alloc, io } {
    let allow = "";
    let db = "";
    let sql = "";
    let tsv: i32 = 0;
    let argc = fx_cli_argc();
    let i: i32 = 1;
    while (i < argc) {
        let a = fx_cli_arg(i);
        if (eq(a, "--help") == true) {
            return Ok(usage());
        }
        if (eq(a, "-h") == true) {
            return Ok(usage());
        }
        if (eq(a, "--tsv") == true) {
            tsv = 1;
            i = i + 1;
        } else {
            if (eq(a, "--allow") == true) {
                i = i + 1;
                if (i >= argc) {
                    let _m = io.write_err("fxql: --allow requires a directory");
                    return Ok(1);
                }
                allow = fx_cli_arg(i);
                i = i + 1;
            } else {
                if (string.len(a) > 0) {
                    if (string.byte_at(a, 0) == 45) {
                        let _u = io.write_err("fxql: unknown flag");
                        return Ok(1);
                    }
                }
                if (string.len(db) == 0) {
                    db = a;
                    i = i + 1;
                } else {
                    if (string.len(sql) == 0) {
                        sql = a;
                        i = i + 1;
                    } else {
                        let _e = io.write_err("fxql: extra arguments");
                        return Ok(1);
                    }
                }
            }
        }
    }
    if (string.len(allow) == 0) {
        let _a = io.write_err("fxql: --allow <dir> is required");
        return Ok(1);
    }
    if (string.len(db) == 0) {
        let _d = io.write_err("fxql: missing <db-path>");
        return Ok(1);
    }
    if (string.len(sql) == 0) {
        let _s = io.write_err("fxql: missing <sql>");
        return Ok(1);
    }
    if (path_has_dotdot(allow) == true) {
        let _pa = io.write_err("fxql: path outside allow / denied");
        return Ok(2);
    }
    if (path_has_dotdot(db) == true) {
        let _pb = io.write_err("fxql: path outside allow / denied");
        return Ok(2);
    }

    let path = resolve_db_path(allow, db)?;
    let code = run_query(allow, path, sql, tsv);
    return Ok(code);
}
