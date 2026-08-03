# scum_rcon_apitest — Plugin API self test

A UE4SS Lua mod that exercises the SCUM-RCON plugin API and reports what works.
It doubles as the shortest complete example of the API: registration, the
handler signature, every return form, and calling back into the dispatcher.

## Run it

1. Copy this folder into your server's `ue4ss/Mods/` (next to `scum_rcon`).
2. Make sure UE4SS loads it: add a line `scum_rcon_apitest : 1` in `mods.txt`.
3. Start the server and watch `UE4SS.log`.

## What it checks by itself

Written to the log as one `PASS`/`FAIL` line each, then a summary:

| Check | Expected |
|---|---|
| register a fresh command | succeeds |
| register the same name twice | second fails |
| register `plugins` | fails — reserved |
| register `listplayers` | fails — SCUM-RCON built-in |
| register an empty name / a non-function handler | fails |
| register `/name`, then `name` | slash stripped, second collides |
| unregister, unregister again, re-register | `true`, `false`, `true` |
| `scum_rcon_dispatch` return shape | boolean + table (or string on failure) |

A dispatch failure with *"server still starting"* right after boot is expected
and not counted as a failure — the boot gate holds commands until the server is
genuinely up.

## What you have to try by hand

These need a real caller, so no script can prove them:

| Command | Expectation |
|---|---|
| `#apitest_echo hello world` (in-game, admin) | `source=ingame`, your SteamID, `is_admin=true`, both args listed |
| `apitest_echo hello world` (RCON) | `source=rcon`, `steam_id=nil`, `is_admin=true` |
| `#apitest_open` as a **non-admin** | answers — it is the one command that opted out of the admin gate |
| `#apitest_echo` as a **non-admin** | ignored; the log shows it was dropped |
| `#apitest_lines` | three separate reply lines |
| `#apitest_fail` | the failure message, in red in-game |
| `#apitest_error` | reports a Lua error — **and the server keeps running** |
| `#apitest_nested` | succeeds; proves a handler may call `scum_rcon_dispatch` |
| `#plugins` | lists every command above, with descriptions and `[admin]` markers |
| restart this mod, then `#apitest_reload` | after the reload it answers again with a *new* load stamp; while it is stopped the command is simply unknown — never a crash |

The hot-reload row is the important one: it proves SCUM-RCON released the Lua
callback references of the stopped state instead of keeping handlers that point
into freed memory.

## Removing it

Delete the folder or simply deactivate the mod in `mods.txt` and restart. Nothing persists.
