# SCUM-RCON — Changelog

User-facing changes. See `USAGE.md` for how to use the commands.

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
