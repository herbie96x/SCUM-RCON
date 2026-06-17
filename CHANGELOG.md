# SCUM-RCON — Changelog

User-facing changes. See `USAGE.md` for how to use the commands.

## 0.4.5

### New

- **`SpawnBrenner`, `SpawnRazor` and `SpawnInventoryFullOf` can now be placed
  freely.** These commands spawn at the caller's position and take no native
  location argument, so over RCON they used to land at world origin `(0,0,0)`.
  You can now give a target position three ways:
  - **coordinates** — a `{X=.. Y=.. Z=..}` struct, keyed `x=.. y=.. z=..` (any
    case), or bare `X Y Z` — drop the spawn at that point;
  - **a trailing online SteamID** spawns it in front of *that* player;
  - **neither** keeps the old behaviour (origin, or the first online player for
    `SpawnInventoryFullOf`).

  `SpawnInventoryFullOf` can finally place a **filled container at free
  coordinates** — a long-standing community request (previously it only spawned
  in front of an online player). Tip: for it, prefer the keyed/struct coord form
  — its container/count arguments are numeric too, so bare trailing numbers
  could be read as coordinates.

  ```
  SpawnBrenner "{X=132609 Y=-67805 Z=34385}"
  SpawnRazor <SteamID>
  SpawnInventoryFullOf <Container> <SetCount> <Item1> <Item2> … x=.. y=.. z=..
  ```

- **`ForceDropshipEncounter` / `ForceAnimalEncounter` can now be sent to
  coordinates.** They spawn at the caller's location and had no coordinate
  argument, so over RCON they only landed at a player (trailing SteamID) or world
  origin. They now take the same placement forms as the spawn commands: a
  `{X=.. Y=.. Z=..}` struct, keyed `x=.. y=.. z=..` or bare `X Y Z` are accepted.
  `ForceAnimalEncounter` is experimental at the moment.

  ```
  ForceDropshipEncounter "{X=140220 Y=-68551 Z=34645}"
  ```

- **`Unstuck <SteamID>` — free a player stuck in terrain/geometry.** Reads the
  player's current position and lifts them **2 m straight up** (under SCUM's
  fall-damage threshold) via the native Teleport, so they drop free. The player
  must be online. Same X/Y, only Z changes — no risk of flinging them across the
  map.

  ```
  Unstuck <SteamID>
  ```

- **`DeleteActiveQuestsForUser <SteamID>` — unstick a player who is kicked on
  every login by a broken quest.** Some quests replicate so many interactables when the
  player logs in that the client's reliable network buffer overflows and the
  server force-closes the connection — *before* the player can abandon the quest.
  This command deletes that player's `active_quest` rows straight from the live `SCUM.db`,
  clearing the offending quest so they can log back in. Run it while the affected
  player is **offline**. The write is safe: the DB runs in WAL mode and the delete
  runs on the RCON worker thread, so it can never stall the game thread. See
  `USAGE.md` §11.

- **`FindQuestLockouts` + `RunQuestUnstick` + Auto-Unstick — the quest-lockout
  toolkit, now hands-free.** Where `DeleteActiveQuestsForUser` fixes one known
  player, these handle a whole offending quest. Name it once in `config.ini`
  (`[quests] blocked = <quest>`, comma-separated, matched by stem in any form):
  - **`FindQuestLockouts`** (read-only) lists every player still holding a blocked
    quest — the lockout candidates;
  - **`RunQuestUnstick`** clears the blocked-quest rows for all of them at once,
    with a circuit breaker (`auto_unstick_max_delete`) that aborts a too-broad
    sweep;
  - **Auto-Unstick** (`auto_unstick = true`, **off by default**) runs that sweep
    once at boot, so a locked-out player is freed before they even reconnect — no
    admin action. `auto_unstick_dry_run` previews into the log without deleting.

  Every delete runs on the RCON worker thread and only
  touches the quests you listed. See `USAGE.md` §11

### Fixed

- **`ListPlayers` / `ListFlags` now return their real output.** These commands send 
  their result over a Client-RPC, not the chat path the output-capture hooked, 
  so they hit the empty fallback even with players/flags present. That RPC is now captured too.

## 0.4.2

### New

- **Startup security-software scan.** On load, SCUM-RCON now checks whether a
  known inline-hooking AV/EDR product (Bitdefender, Windows Defender, Kaspersky,
  ESET, Sophos and others) has injected itself into the server process and logs
  a clear `env-scan:` warning if so. Such products patch function prologues
  in-process and can clash with UE4SS/RCON hooks, causing otherwise-inexplicable
  random crashes — the warning turns that into a one-line lead in the log, with a
  hint to exclude `ScumServer.exe` and the `ue4ss` folder from real-time
  monitoring. Purely informational; it never blocks startup.
- **RCON-Client v2.3: send several commands at once.** In the interactive console
  you can now separate multiple commands with `;` and they run in order over a
  single connection, e.g.
  `ListPlayers ; Announce "restart in 5 min" ; SpawnItem ...`. A `;` inside a quoted
  message does not split, so `Announce "warning; restarting soon"` stays one
  command. Works in the piped/bot mode too.

### Fixed

- **Random server crashes during object lookups no longer take the whole server
  down.** Under heavy object churn (e.g. a Lua mod polling `FindAllOf`) made
  worse by AV inline-hooks in the process (see the `env-scan:` note above), the
  engine's object iteration could hit a stale/freed object and access-violate,
  killing the server. This was behind the recurring random crashes. The UE4SS
  build shipped with SCUM-RCON is now hardened: such a fault is caught per object
  and that single entry is skipped, so one bad object can no longer crash the
  process. **If you run your own UE4SS or an old version update it to the bundled build to get
  this fix.**
- **No more mass disconnects / server freezes caused by RCON.**
  SCUM-RCON reads a few values straight from the live `SCUM.db` (SteamID lookups,
  entitiy ID resolver, vehicle owner). It opened the database the wrong way, which still
  takes a SQLite read lock and that could collide with the server's own write
  transaction, freezing the game thread until the lock cleared and timing every
  player out at once. The database is now opened immutable, so RCON can never block the server again.
- **Commands no longer hang on `-nobattleye` servers.** The boot-gate that holds
  dispatch until the server is fully up used to wait for BattlEye's
  master connection. With `-nobattleye` it never appeared, so the gate sat in its fail-open the
  whole time. The gate now waits for SCUM's BattlEye-independent DB-writes and the fail-open 
  timeout are now 2 min. instead of engine ticks. The "please wait" reply no longer falsely mentions BattlEye.
- **Commands no longer return `Not authorized` to players.** The in-game
  authorization hook was matching the wrong function after a update, so the internal
  auth-bypass never took effect for some commands.

## 0.4.1

### Fixed

- **`ShowNamePlates` now actually toggles in-game.** In 0.4.0 the
  command was dispatched through the wrong pipeline that ran server-side but never replicated the
  overlay to the client, so RCON replied `ok` while nothing happened in-game. It
  now goes through the right path.

## 0.4.0

### New

- **`#Inventory` now accepts the player's SteamID** — no more hunting for a
  numeric entity id. SCUM's `#Inventory` wants the target's prisoner *entity id*
  as its `<PlayerId>`; the mod now resolves a 17-digit SteamID to that id for you, 
  so a single SteamID is enough:

  ```
  #Inventory <SteamID> SpawnAndAddItems <Item>_ES <count>
  ```

  A bare entity id still works, and an explicit trailing SteamID lets you target
  a different player than the caller if ever needed. Tip: some items need their
  `_ES` "entity setup" name (e.g. `Weapon_AKM_ES`, `Magazine_RPK_ES`) — the bare
  name gives `'...' is not a valid item entity setup`.

- **Boot gate — commands wait until the server is genuinely up.** The mod watches
  the server log for BattlEye's `Connected to BE Master` line and holds **every**
  command back until then (replying `server still starting …` in the meantime).
  That is the reliable "fully up" marker — more precise than the engine-class
  check and a guard against the early-boot command crash class. A one-time
  `SCUM-RCON READY` line lands in the log when it flips, for tooling that wants to
  wait for it. It fails open after a short timeout so a missing/unreadable log
  never leaves the mod stuck.

### Fixed

- **`SpawnInventoryFullOf` now accepts a target player's SteamID.** Appending the
  SteamID used to make it get parsed as a fill item (`'…' is not allowed to be
  spawned`). It is now recognised as the routing target — the container spawns in
  front of *that* player and the SteamID is dropped from the item list. Without
  one, the first online player is used. Multiple item names are allowed.

  ```
  SpawnInventoryFullOf <Container> <SetCount> <Item1> <Item2> … [<SteamID>]
  ```

- **`ForceDropshipEncounter` / `ForceAnimalEncounter` now spawn at a player.**
  They anchor to a player's location and take no coordinate argument; over RCON
  they previously fired at world origin `(0,0,0)`. Append the target player's
  SteamID (or omit it for the first online player):

  ```
  ForceDropshipEncounter <SteamID>
  ```

- **`SetAIInvisibility` now reaches the target.** It was running on the synthetic
  controller (which has no pawn) and did nothing. It now uses the target player's
  pawn as caller, like `SetGodMode`. It takes a bool: `SetAIInvisibility <1|0>
  <SteamID>`.

## 0.3.2

### New

- **`SpawnInventoryFullOf` over RCON** —
  `SpawnInventoryFullOf <Container> <SetCount> <Item1> <Item2> … <sid>`. It spawns a
  filled container **in front of a player** (no location argument — an engine
  limit), so it routes through an online player: at least one player must be
  online and the container appears in front of them. See `USAGE.md`.

### Fixed

- **Admin commands returning `controller is null` / nothing on some hosts
  (`#ListPlayers`, `#ListFlags`, …).** To run admin commands without a real
  player, the mod spawns a synthetic "system" controller. During boot it could pick 
  a transient / half-initialized world state, which made that spawn fail so commands
  had no caller. It now selects the live game world (the one with a valid
  `AuthorityGameMode`), validates the cached world's liveness, and invalidates +
  retries on a spawn fault (caching only on full success). If the controller still 
  can't be built on a host, commands fall back to a real online player's controller as 
  the caller when one is available.
- **Server crash ~1 minute after start.** While the last map cell was streaming
  in and the first players were connecting, a queued command could run on the
  wrong engine thread and access-violate, taking the whole server down
  (timing-dependent, so intermittent). Command dispatch is now gated to the game
  thread, with a safety net so a fault during a volatile world state fails
  cleanly and retries instead of crashing. Introduced in 0.3.0 — update strongly
  recommended.

## 0.3.0

### New

- **Map / HUD overlay toggles over RCON.** Flip a player's on-screen markers
  from RCON: name plates, plus the vehicle / flag / other-player **location**
  *and* **info** overlays, plus line-markers for NPCs, zombies and animals
  (`ShowNamePlates`, `ShowVehicleLocations`/`ShowVehicleInfo`,
  `ShowFlagLocations`/`ShowFlagInfo`,
  `ShowOtherPlayerLocations`/`ShowOtherPlayerInfo`, `ShowArmedNPCsLocation`,
  `ShowZombiesLocation`, `ShowAnimalLocation`). They render on the **target
  player's own client**, so end the command with that player's online 17-digit
  SteamID.

### Fixed

- **Shutdown no longer crashes with an open RCON connection.** Restarting or
  shutting the server down while an RCON client was still connected could
  access-violate and take the whole server with it. The mod now detects the
  shutdown, gates its command drain and closes the listener cleanly first.
- **`ListSpawnedVehicles` returns the real list** — one line per vehicle (id,
  type, position, owner). Long lists are split across **multiple packets**, so
  use an RCON client that supports multi-packet replies (the bundled
  `rcon_console` does; `mcrcon` reads only the first packet).

### Known limitations (by engine)

- **GodMode is for real admins only.** Setting `SetGodMode` over RCON does flip
  the flag, but a **non-admin** who then free-builds (the *GodModeFill*
  interaction) is auto-banned by **SCUM's own anti-cheat** — it validates that
  interaction against the real admin list. Only give GodMode to genuine server
  admins
  (`SetImmortality` — damage immunity — is unaffected and safe.)
- **`#Inventory`: only `SpawnAndAddItems` works over RCON.** The `Character_*`
  and `Grid_*` sub-commands are server-authoritative inventory operations that
  silently do nothing over RCON — an engine limitation, documented in
  `USAGE.md`.

## 0.2.5

### New

- **`#Inventory … SpawnAndAddItems`** — grant items straight into an online
  player's inventory over RCON:
  `#Inventory <PlayerId> SpawnAndAddItems <item> <count> <online-SteamID>`.
  At least one player must be online (the command needs a real player context).

## 0.2.4

### New

- **`SendChat` can broadcast to everyone.** Leave off the trailing SteamID and
  the coloured chat line goes to **all online players** — for event
  announcements, warnings or notices in a normal chat colour, instead of the
  big `Announce` banner. With a SteamID it still goes to just that player.

### Fixed

- **Spawning weapons no longer crashes the server.** `SpawnItem` for a weapon —
  e.g. `SpawnItem Weapon_MK18` — could access-violate and take the whole server
  down, while simple items (Banana) and vehicles spawned fine. Root cause: the
  spawn ran mid-frame, so the weapon's animation blueprint started updating
  before the weapon had finished initialising. Commands now run on the engine's
  frame boundary, so the spawn completes its init cycle first. Weapons spawn
  cleanly.

### Requires

- **`HookEngineTick = 1`** in the `[Hooks]` section of `ue4ss\UE4SS-settings.ini`.
  The settings file in the download already has it set — this only matters if you
  carry over your own settings file from an older install. Without it, weapon
  spawns can still crash (SCUM-RCON warns you about it in `UE4SS.log` on startup).

## 0.2.1

### New

- **SendChat** — send a real coloured chat line to a player (white, blue,
  green, yellow, orange, red), for small messages where a full `Announce`
  would be too loud.
- **Player-targeted commands now work over RCON** — GodMode, Immortality,
  the body-effect and infinite-stat toggles, attributes, skills, injuries,
  `Suicide`, `Knockout`, and more. Give the target player's 17-digit SteamID
  as the last argument; the player must be online.
- **More ways to place spawns.** `SpawnItem`, `SpawnVehicle` and friends now
  accept three `Location` forms: a coordinate struct, a player's SteamID
  (spawn at that player), or bare `X Y Z` coordinates.
- **USAGE.md** — a complete command guide: notification and chat-colour
  tables, which commands need a SteamID, the spawn-location forms, and the
  common mistakes.

### Fixed

- **Quoted multi-word arguments were broken.** A message, a two-word player
  name, or a coordinate struct in quotes got shredded. Quotes now work as
  expected — e.g. `Teleport X Y Z "First Last"` finds the right player.
- **SendNotification could return "Not authorized to execute command".**
  Fixed — the notification now shows reliably, and you can address the
  target by SteamID instead of an internal id.
- **A leading `#` gave "unknown command".** In-game console habit is fine
  now — `#SpawnItem …` works the same as `SpawnItem …`.

## 0.1.8

- **Non-ASCII text fixed.** Umlauts, Cyrillic, Chinese characters and emoji
  in command arguments (e.g. `Announce`) come through correctly instead of
  as garbled characters.

## 0.1.5 – 0.1.7

- **Compatibility with the May 2026 SCUM update** restored. The update
  changed the server internals and temporarily broke command dispatch and
  reply capture; both work again.

## 0.1.0 – 0.1.4

- Initial release: a standard Source RCON server over TCP, password
  authentication, automatic discovery of SCUM's admin commands, and
  server-side command dispatch (no in-game admin needs to be online).
- Licensing settled on a **free-to-use EULA**: download and run on your own
  server for free; no selling, no redistribution outside the official channel.
