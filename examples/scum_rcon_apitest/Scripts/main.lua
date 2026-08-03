-- SCUM-RCON Plugin API — self test and reference mod
--
-- Drop this folder into your server's `ue4ss/Mods/` next to `scum_rcon`, add
-- `scum_rcon_apitest` to `mods.txt` (or keep the `enabled.txt` beside it), and
-- start the server. It does two things:
--
--   1. On load it runs the checks that need no game world and writes one
--      PASS/FAIL line each into UE4SS.log, plus a summary.
--   2. It registers a handful of commands you drive by hand — in-game with
--      `#apitest_…`, over RCON with `apitest_…` — for the cases only a real
--      caller can prove (admin gate, chat replies, re-entrant dispatch).
--
-- It is also the shortest complete example of the API: registration, the
-- handler signature, the return forms, and calling back into the dispatcher.

local TAG = "[apitest]"

-- SCUM-RCON injects its globals when the mod's Lua state starts. If they are
-- missing, SCUM-RCON is not installed, is an older build, or its licence gate
-- failed and it went inert — all three mean "nothing to test here".
if type(_G.scum_rcon_register_command) ~= "function" then
    print(TAG .. " scum_rcon_* globals not available — SCUM-RCON not loaded or inert")
    return
end

local function log(msg)
    print(TAG .. " " .. msg)
    scum_rcon_log("apitest: " .. msg)
end

-- check harness
local passed, failed = 0, 0

local function check(name, ok, detail)
    if ok then
        passed = passed + 1
        log("PASS  " .. name)
    else
        failed = failed + 1
        log("FAIL  " .. name .. (detail and ("  (" .. tostring(detail) .. ")") or ""))
    end
end

-- 1. automatic checks

-- The interactive commands are registered first; their success is a check too.
local function noop_handler(args, caller)
    return true
end

check("register a fresh command",
      scum_rcon_register_command("apitest_probe", noop_handler,
                                 { admin_only = true, description = "registration probe" }) == true)

check("duplicate name is refused",
      scum_rcon_register_command("apitest_probe", noop_handler) == false)

check("reserved name 'plugins' is refused",
      scum_rcon_register_command("plugins", noop_handler) == false)

-- 'listplayers' is a SCUM-RCON built-in: the dispatcher answers it before the
-- plugin table is ever consulted, so registering it must fail loudly instead of
-- leaving a command that silently never runs.
check("built-in name 'listplayers' is refused",
      scum_rcon_register_command("listplayers", noop_handler) == false)

check("empty name is refused",
      scum_rcon_register_command("", noop_handler) == false)

check("non-function handler is refused",
      scum_rcon_register_command("apitest_bad_handler", "not a function") == false)

-- A leading slash is accepted and stripped: this registers 'apitest_slash',
-- reachable as `#apitest_slash` — so registering the bare name after it must
-- collide.
check("leading slash is stripped on register",
      scum_rcon_register_command("/apitest_slash", noop_handler) == true)
check("…and the bare name is then taken",
      scum_rcon_register_command("apitest_slash", noop_handler) == false)

-- unregister round-trip
check("unregister a registered command",
      scum_rcon_unregister_command("apitest_probe") == true)
check("unregister the same name twice fails",
      scum_rcon_unregister_command("apitest_probe") == false)
check("re-register after unregister works",
      scum_rcon_register_command("apitest_probe", noop_handler,
                                 { description = "registration probe" }) == true)

-- dispatch() shape. On a cold server this legitimately fails with "server still
-- starting" — we assert the SHAPE of the answer, not that the command ran.
do
    local ok, payload = scum_rcon_dispatch("plugins")
    check("dispatch returns a boolean", type(ok) == "boolean", type(ok))
    if ok then
        check("dispatch success yields a table of lines", type(payload) == "table", type(payload))
    else
        check("dispatch failure yields an error string", type(payload) == "string", tostring(payload))
        log("note: dispatch said '" .. tostring(payload) .. "' — expected while the server is still booting")
    end
end

-- 2. interactive commands 

-- Echoes what the handler was handed. Run it in-game AND over RCON: in-game
-- `caller.source` must be "ingame" with your SteamID filled in, over RCON it
-- must be "rcon" with steam_id nil.
scum_rcon_register_command("apitest_echo", function(args, caller)
    local lines = {
        ("verb=%s source=%s is_admin=%s"):format(
            tostring(caller.verb), tostring(caller.source), tostring(caller.is_admin)),
        "steam_id=" .. tostring(caller.steam_id),
        ("argc=%d"):format(#args),
    }
    for i, a in ipairs(args) do
        lines[#lines + 1] = ("  arg[%d]=%s"):format(i, a)
    end
    return true, lines
end, { admin_only = true, description = "echoes args + caller" })

-- admin_only = false: the ONE case a non-admin may run in-game. Everything else
-- is turned away by SCUM-RCON's AdminUsers.ini gate before the handler runs.
scum_rcon_register_command("apitest_open", function(args, caller)
    return true, "open to everyone — you are " ..
                 (caller.is_admin and "an admin" or "a regular player")
end, { admin_only = false, description = "callable by any player" })

-- Return-form coverage.
scum_rcon_register_command("apitest_ok", function()
    return true
end, { description = "returns success with no output" })

scum_rcon_register_command("apitest_lines", function()
    return true, { "line one", "line two", "line three" }
end, { description = "returns several reply lines" })

scum_rcon_register_command("apitest_fail", function()
    return false, "deliberate failure — this is the expected result"
end, { description = "returns a failure + message" })

-- A Lua error must NOT take the server down: SCUM-RCON pcalls the handler and
-- turns the error into this command's error message.
scum_rcon_register_command("apitest_error", function()
    error("deliberate Lua error — the server must survive this")
end, { description = "raises a Lua error on purpose" })

-- Re-entrancy: calling the dispatcher from inside a handler. This used to be
-- impossible (the dispatch guard reported "server busy" against itself).
scum_rcon_register_command("apitest_nested", function(args, caller)
    local ok, payload = scum_rcon_dispatch("plugins")
    if not ok then
        return false, "nested dispatch failed: " .. tostring(payload)
    end
    return true, ("nested dispatch ok — %d line(s) came back"):format(#payload)
end, { description = "calls scum_rcon_dispatch from inside a handler" })

-- Hot-reload probe: register a command whose handler closes over local state.
-- Reload this mod (UE4SS mod restart) and call it again — it must answer
-- "unknown command" rather than crash, proving the callback ref of the dead
-- state was released.
local load_stamp = tostring(os.time())
scum_rcon_register_command("apitest_reload", function()
    return true, "handler from mod load " .. load_stamp
end, { description = "for the hot-reload check" })

-- summary 
log(("automatic checks: %d passed, %d failed"):format(passed, failed))
if failed == 0 then
    log("all automatic checks green — now run the manual ones:")
else
    log("SOME AUTOMATIC CHECKS FAILED — see the FAIL lines above")
end
log("  in-game (admin):      #apitest_echo hello world   #apitest_lines   #apitest_nested")
log("  in-game (non-admin):  #apitest_open   (must answer)   #apitest_echo (must be ignored)")
log("  error handling:       #apitest_error   #apitest_fail")
log("  listing:              #plugins")
log("  hot-reload:           restart this mod, then #apitest_reload")
