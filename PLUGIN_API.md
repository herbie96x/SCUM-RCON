# SCUM-RCON Plugin API

Add your own admin commands to a server running **SCUM-RCON** — without
touching or rebuilding the mod. Your commands then work from **RCON** *and*
from the **in-game admin chat**, through SCUM-RCON's own dispatcher.

There are two ways in:

| You are writing | Use | Section |
|---|---|---|
| a **UE4SS Lua mod** (the common case) | the `scum_rcon_*` globals | [§2](#2-lua-mods) |
| a **UE4SS C++ mod** | the exported C ABI | [§3](#3-c-mods) |

Both register into the same command table, so a Lua command and a C++ command
are indistinguishable to the dispatcher and to your admins.

> ABI version for the C path: **`SCUMRCON_API_VERSION = 1`** (`PluginApi.h`,
> shipped in `plugin-api/` next to the mod). Lua needs no header and no
> version handshake — the globals are injected into your state directly.

---

## 1. How commands are addressed

You register a plain name — `ping` — and it is then used exactly like any other
command:

| Where | Typed as |
|---|---|
| in-game admin chat | `#ping`, `#warp home` |
| RCON | `ping`, `warp home` |

Replies come back in-game as chat lines — green for success, red for an error.

### Name collisions

Commands resolve in a fixed order: **vanilla SCUM first, then SCUM-RCON's
built-ins, then plugins.** A plugin therefore cannot override or shadow an
existing command — but it also means the name you pick has to be free:

- Registering a name that is already a vanilla verb or a SCUM-RCON built-in
  **fails** and logs why. Pick another one.
- If a future SCUM update introduces a verb with the same name as your command,
  vanilla wins from then on. SCUM-RCON notices this when it builds its verb map
  and writes a warning naming your command, so it shows up in the log rather
  than as a command that mysteriously stopped working.

`plugins` is reserved: SCUM-RCON answers `#plugins` itself with the list of
every registered command (name, description, admin flag).

---

## 2. Lua mods

SCUM-RCON injects four globals into every Lua mod it sees. Nothing to include,
nothing to link — if SCUM-RCON is loaded, they are there.

```lua
scum_rcon_register_command(name, fn, opts)   --> true / false
scum_rcon_unregister_command(name)           --> true / false
scum_rcon_dispatch(command_line)             --> ok, lines | error
scum_rcon_log(text)
```

### Registering a command

```lua
scum_rcon_register_command("ping", function(args, caller)
    if args[1] then
        return true, { "pong", args[1] }  -- two reply lines
    end
    return true, "pong"                   -- one reply line
end, { admin_only = true, description = "replies pong" })
```

- `name` — bare name, `"ping"` (in-game `#ping`, over RCON `ping`). A leading
  `/` is accepted and stripped. Case-insensitive. `"plugins"` is reserved, and
  a name already taken by a vanilla or built-in command is refused.
- `fn` — your handler, see below.
- `opts` — optional table:
  - `admin_only` (default **`true`**) — in-game callers must be server admins,
    checked against SCUM's `AdminUsers.ini`. **Enforced**: a non-admin is turned
    away before your handler runs. Set `false` for commands every player may use.
  - `description` — one-liner shown by `#plugins`.
- **Returns** `true`, or `false` if the name is taken, reserved, or you called
  from the wrong state (see below).

### The handler

```lua
function(args, caller) -> ok, payload
```

- `args` — array of the arguments **after** the verb: for `#warp home 2`,
  `args[1] == "home"`, `args[2] == "2"`, `#args == 2`.
- `caller` — a table:

  | field | value |
  |---|---|
  | `verb` | the command name |
  | `source` | `"rcon"` or `"ingame"` |
  | `steam_id` | SteamID of the player who typed it, `nil` over RCON |
  | `is_admin` | `true` / `false` |

- **Return values:**

  | return | result |
  |---|---|
  | `true` | success, no output |
  | `true, "line"` | success, one reply line |
  | `true, { "a", "b" }` | success, several reply lines |
  | `false, "why"` | failure, message goes to the caller |

An `error()` inside your handler does not take the server down — it is caught
and reported as that command's error, with the Lua message.

### Calling SCUM-RCON's own commands

```lua
local ok, lines = scum_rcon_dispatch("Announce restart in 5 minutes")
if ok then
    for _, line in ipairs(lines) do scum_rcon_log(line) end
else
    scum_rcon_log("failed: " .. lines) -- on failure the 2nd value is the error
end
```

This runs a full command line through the dispatcher as a trusted caller, the
same path RCON uses, so you can drive vanilla and built-in commands from your
own. Calling it **from inside your handler is supported** (dispatch is
re-entrant on the same thread):

```lua
scum_rcon_register_command("heal", function(args, caller)
    if not caller.steam_id then return false, "in-game only" end
    return scum_rcon_dispatch(
        "Inventory " .. caller.steam_id .. " SpawnAndAddItems Emergency_bandage_Big_ES 1")
end, { admin_only = true, description = "hands the caller a bandage" })
```

### Rules that matter

- **Register from your mod's main state.** Handlers are called from the game
  thread; the async and hook states belong to their own drivers and calling into
  them from there is a race. `scum_rcon_register_command` refuses those states
  and logs why. Top-level code in your `main.lua` is the main state.
- **Your handler runs on the game thread.** Don't block in it: no sleeping, no
  synchronous network calls. A slow handler is a laggy server.
- **Hot-reload is handled.** When your mod stops or is reloaded, SCUM-RCON drops
  its commands and releases the callback references before UE4SS closes the
  state. You do not need to call `scum_rcon_unregister_command` on shutdown; use
  it only when you genuinely want a command gone while the mod keeps running.
- **`scum_rcon_dispatch` and `scum_rcon_log` work from any state**, only
  registration is restricted.

### Complete minimal mod

`Mods/my_plugin/Scripts/main.lua`:

```lua
local ok = scum_rcon_register_command("servertime", function(args, caller)
    local ok2, lines = scum_rcon_dispatch("CheckServerTime")
    if not ok2 then return false, "could not read the server time" end
    return true, lines
end, { admin_only = false, description = "shows the current server time" })

scum_rcon_log(ok and "servertime registered" or "registration failed")
```

> Keep player data behind `admin_only = true`, and when in doubt return less.

If `scum_rcon_register_command` is `nil`, SCUM-RCON is not loaded (or is inert
because its licence gate failed) — guard with
`if not scum_rcon_register_command then return end`.

> A ready-to-run mod that exercises all of this, every return form, the admin
> gate, error handling, re-entrant dispatch and hot-reload, lives in
> `examples/scum_rcon_apitest/` in the SCUM-RCON repository. It writes a
> PASS/FAIL line per check into `UE4SS.log` and is the fastest way to see the
> API working before you write your own.

---

## 3. C++ mods

For a UE4SS **C++** mod, SCUM-RCON exports one function; everything else is a
table of function pointers. Plain C, so no C++ types cross the module boundary.

```c
const ScumRcon_Api* ScumRcon_GetApi(uint32_t abi_version);
```

Our DLL is loaded as `main.dll` inside its own mods folder, so resolve the
export by scanning loaded modules for the one that has it:

```cpp
#include <windows.h>
#include <psapi.h>
#include "PluginApi.h" // from plugin-api/, ship a copy with your plugin

static const ScumRcon_Api* find_scumrcon_api()
{
    HMODULE mods[1024];
    DWORD   needed = 0;
    if (!EnumProcessModules(GetCurrentProcess(), mods, sizeof(mods), &needed))
        return nullptr;

    const size_t count = needed / sizeof(HMODULE);
    for (size_t i = 0; i < count; ++i)
    {
        auto get = reinterpret_cast<const ScumRcon_Api* (*)(uint32_t)>(
            GetProcAddress(mods[i], "ScumRcon_GetApi"));
        if (get)
        {
            if (const ScumRcon_Api* api = get(SCUMRCON_API_VERSION))
                return api;
        }
    }
    return nullptr; // SCUM-RCON not loaded (yet)
}
```

SCUM-RCON may finish loading after your plugin. If this returns `nullptr` at
startup, retry from a later callback (e.g. `on_unreal_init`).

The header is a convenience, not a requirement: it contains only declarations,
so you may also write them out yourself. On x64 Windows there is a single
calling convention, so only field order and signatures have to match.

### The interface

```c
typedef struct ScumRcon_Api
{
    uint32_t abi_version;

    int  (*register_command)(const char* name, ScumRcon_HandlerFn fn,
                             int admin_only, void* user, const char* description);
    int  (*dispatch)(const char* command_line, ScumRcon_Reply* reply);
    void (*log)(const char* line);
    int  (*enqueue_game_thread)(ScumRcon_TaskFn fn, void* user);
} ScumRcon_Api;
```

`register_command`, `dispatch` and `log` mirror the Lua globals above;
`admin_only` and `description` mean the same thing.

**`enqueue_game_thread(fn, user)`** runs `fn(user)` once on the game thread at
the next engine tick — the supported way for your own threads to reach anything
engine-side, including `dispatch`. Safe from any thread. Returns `1` when
queued, `0` when the mod is shutting down (your task will not run); `user` must
outlive the call.

```cpp
struct Job { const ScumRcon_Api* api; std::string cmd; };

static void run_job(void* user) // on the game thread
{
    auto* job = static_cast<Job*>(user);
    job->api->dispatch(job->cmd.c_str(), nullptr);
    delete job;
}

api->enqueue_game_thread(&run_job, new Job{api, "Announce restart in 5"});
```

### The handler

```c
typedef int (*ScumRcon_HandlerFn)(int argc, const char* const* argv,
                                  const ScumRcon_Caller* caller,
                                  ScumRcon_Reply* reply, void* user);
```

- `argv[0]` is the bare command name; `argv[1..]` are the arguments. `argc >= 1`.
- `caller` — the same information the Lua table carries:
  ```c
  typedef struct ScumRcon_Caller {
      int         source;   // SCUMRCON_SOURCE_RCON (0) | SCUMRCON_SOURCE_INGAME (1)
      const char* steam_id; // in-game caller SteamID (UTF-8), NULL over RCON
      int         is_admin; // 0/1
  } ScumRcon_Caller;
  ```
- `reply` — push output and errors back:
  ```c
  typedef struct ScumRcon_Reply {
      void (*emit)(void* ctx, const char* line);     // one reply line
      void (*set_error)(void* ctx, const char* msg); // mark failure
      void* ctx;                                     // pass back unchanged
  } ScumRcon_Reply;
  ```
- **Return** `0` on success, non-zero on failure; on failure also call
  `set_error` so the caller sees why.

> **Lifetime:** `argv`, the strings, `caller` and `reply` are valid **only for
> the duration of the call**. Copy anything you need to keep.

```cpp
static int handle_ping(int argc, const char* const* argv,
                       const ScumRcon_Caller* caller,
                       ScumRcon_Reply* reply, void* /*user*/)
{
    if (reply && reply->emit)
    {
        reply->emit(reply->ctx, "pong");
        if (argc > 1) reply->emit(reply->ctx, argv[1]);
    }
    return 0;
}

void register_my_commands()
{
    const ScumRcon_Api* api = find_scumrcon_api();
    if (!api) return;   // retry later

    api->register_command("ping", &handle_ping, /*admin_only=*/1,
                          /*user=*/nullptr, /*description=*/"replies pong");
    api->log("my-plugin: /ping registered");
}
```

### ABI stability

- Existing fields and function-pointer slots are **never** reordered or changed.
  New capabilities are appended at the **end** and `SCUMRCON_API_VERSION` is
  bumped.
- Because the table only grows, **your plugin keeps working across mod
  updates**: `ScumRcon_GetApi` accepts any version up to the one the installed
  mod provides and hands back a table whose leading slots are exactly what you
  built against.
- It returns `NULL` only if you ask for a version **newer** than the installed
  mod.

---

## 4. What the API does *not* do

- It does **not** let you override vanilla or built-in commands.
- It does **not** expose SCUM internals, use `dispatch` to reach vanilla
  functionality through supported commands.
- It does **not** push events at you (login, death, chat, …). Commands are the
  only entry point today.

---

*Questions or a capability you need exposed? Open an issue with the use case.*
