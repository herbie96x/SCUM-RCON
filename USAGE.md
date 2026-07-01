# SCUM-RCON — Command Usage Guide

How to send commands over RCON, what the special commands expect, and the
notification / chat-colour codes.

---

## Basics

- Send commands as plain text over the RCON connection — exactly the verb and
  arguments, nothing else.
- **No `#` needed.** In-game you type `#SpawnItem …`; over RCON the bare verb
  `SpawnItem …` is correct. A leading `#` is accepted and ignored, so muscle
  memory won't bite you.
- **Quotes group words.** Any argument containing spaces — a message, a
  multi-word player name, a coordinate struct — must be wrapped in double
  quotes. `Teleport 1000 2000 300 "SUPER ADMIN"` finds the two-word player;
  without quotes only `SUPER` is searched.
- **SteamID = 17 digits.** Wherever a command needs a target player, it's the
  player's 17-digit SteamID64, given as the **last** argument.
- Replies come back as UTF-8 plain text (umlauts, Cyrillic, Chinese, all
  work).

---

## Command families

### 1. Standard admin commands

Most of SCUM's ~230 admin commands work as-is, no SteamID, dispatched
server-side without anyone online:

```
Announce Hello everyone
SetTime 9
SetWeather 0.5
ListSquads 1
ListPlayers
ShutdownServer Pretty Please
```

### 2. Player-affecting commands (need a target SteamID)

Commands whose effect is applied **to a specific player** must end with that
player's SteamID — **and the player must be online**. The SteamID picks the
target; you don't need to be in-game yourself.

```
SetGodMode true <SteamID>
SetImmortality true <SteamID>
DisableBodyEffects true <SteamID>
SetInfiniteStamina true <SteamID>
SetAttributes 3 3 3 3 <SteamID>
SetSkillLevel Driving 5 <SteamID>
AddBleedingInjury <SteamID>
AddRadiationPresence <SteamID>
Suicide <SteamID>
Knockout 30 <SteamID>
```

If the target isn't online you get `player <SteamID> is not online`.

> **⚠️ `SetGodMode` and non-admin targets:** GodMode in SCUM is a
> build cheat: it lets the player *fill placeable blueprints for free*
> But SCUM validates that interaction **server-side against the real admin list** 
> the player must be a genuine configured server admin. If not:
> SCUM's own anti-cheat **auto-bans them**. This is SCUM's design, not an RCON
> bug and it cannot be worked around from the RCON side. **Only give GodMode to
> players who are already real server admins.**

### 3. SendNotification — pop-up / toast / banner

A short on-screen notification to one player. **Recommended form** (resolves
the internal id from the SteamID for you):

```
SendNotification <type> 0 "<message>" <SteamID>
```

The `0` is a placeholder — it's overwritten automatically. Example:

```
SendNotification 2 0 "Welcome to the server!" <SteamID>
```

| type | Style | Where |
|---|---|---|
| **1** | Toast | top-right (cargo-drop style) |
| **2** | Announce | centre — the default for announce messages |
| **3** | LevelUP Notify | Don't use, message isn't customizable |
| **4** | Self-talk | subtle character thought (e.g. "I feel cold") |
| **5** | Killfeed-Banner | bottom-centre highlight |

> Advanced: if you already know a player's internal id you may pass it directly
> as `SendNotification <type> <id> "<message>"` (no SteamID). The SteamID form
> above is simpler and is what you'll normally want.

### 4. SendChat — a real coloured chat line

Unlike a notification, this writes an actual line into the player's **chat
scrollback**, in a chosen colour. Good for small, non-intrusive messages
(bounty hits, rewards) where a big `Announce` would be too loud.

```
SendChat <type> "<message>" <SteamID>
```

| type | Colour | Channel feel |
|---|---|---|
| **0** | white | default |
| **1** | white | local |
| **2** | blue | global |
| **3** | green | squad |
| **4** | yellow | admin |
| **6** | orange | server message |
| **7** | red | error / warning |

Example:

```
SendChat 4 "Bounty claimed: +500" <SteamID>          (yellow)
SendChat 7 "You entered a no-build zone" <SteamID>   (red)
```

### 5. Spawning at a location

`SpawnItem`, `SpawnVehicle`, `SpawnZombie` and friends spawn at the **caller's**
position by default. Give an explicit `Location` argument if you don't want that item spawn on the moon. 
Three accepted forms:

**a) Coordinate struct** (full position + rotation — the form SCUM's own docs
use):

```
SpawnVehicle BPC_Rager 1 Location "{X=140220.3 Y=-68551.4 Z=34645.6|P=0 Y=270 R=0}"
SpawnItem Military_Backpack_02_04 1 Location "{X=289265 Y=-188112 Z=15217|P=0 Y=0 R=0}"
```

**b) At a player's position** — give the player's SteamID as the location:

```
SpawnItem Apple 1 Location <SteamID>
```

**c) Bare coordinates** (X Y Z, no rotation):

```
SpawnItem Apple 1 Location 289265 -188112 15217
```

> The struct in **(a)** contains spaces, so it **must** be quoted. A common
> mistake is `Location "289265 -188112 15217"` (three bare numbers in quotes) —
> that is **not** valid; use one of the three forms above.

**Caller-anchored spawns without a native `Location`** —
`SpawnInventoryFullOf`, `SpawnBrenner`, `SpawnRazor`. SCUM spawns these at the
invoking player's position, so they have **no `Location` parameter of their
own** and over RCON used to land at world origin. The mod fills that gap by
positioning its dispatch context for you — the same placement forms as above,
given at the **end** of the line:

- **coordinates** (a `{X=.. Y=.. Z=..}` struct, keyed `x=.. y=.. z=..` any case,
  or bare `X Y Z`) — spawns at that point;
- **a trailing online SteamID** — spawns in front of *that* player;
- **neither** — origin for `SpawnBrenner` / `SpawnRazor`; the first online
  player for `SpawnInventoryFullOf`.

```
SpawnBrenner "{X=132609 Y=-67805 Z=34385}"
SpawnRazor <SteamID>
SpawnInventoryFullOf <Container> <SetCount> <Item1> <Item2> … x=.. y=.. z=..
SpawnInventoryFullOf <Container> <SetCount> <Item1> <Item2> … <SteamID>
SpawnInventoryFullOf Improvised_Metal_Chest 1 Weapon_AKM 3 76561XXXXXXXXXXXX
```

For `SpawnInventoryFullOf`, `<SetCount>` is how many times the whole item set is
placed into the container, and **multiple item names are allowed**. Prefer the
keyed/struct coord form for it — its container/count arguments are numeric too,
so bare trailing numbers could be mistaken for coordinates.

### 6. Encounters at a player (`ForceDropshipEncounter`, `ForceAnimalEncounter`)

> **⚠️ Experimental.** The coordinate routing goes through a synthetic caller.
> `ForceDropshipEncounter` is confirmed working. `ForceAnimalEncounter` runs and
> spawns at the point too, but the animals appear **on the ground at the coords**
> (you must be there to see them), and exact behaviour can vary by encounter.

These spawn an encounter at a location and have **no native coordinate
argument**, so over RCON the mod gives you three ways to place them (same forms
as the spawn commands in section 5):

- **coordinates** — `{X=.. Y=.. Z=..}` struct, keyed `x=.. y=.. z=..`, or bare
  `X Y Z` — drop the encounter at that point (the mod positions a synthetic
  caller there);
- **a trailing online SteamID** — at *that* player;
- **neither** — first online player, else world origin.

```
ForceDropshipEncounter "{X=140220 Y=-68551 Z=34645}"
ForceDropshipEncounter x=140220 y=-68551 z=34645
ForceAnimalEncounter "{X=140220 Y=-68551 Z=34645}"
ForceDropshipEncounter <SteamID>
ForceAnimalEncounter <SteamID>
```

> Use coordinates **or** a SteamID, not both — a 17-digit SteamID appended after
> coordinates would be misread as a coordinate.

> Commands that destroy/clear "within radius" or "at player location"
> (`DestroyCorpsesWithinRadius`, `DestroyZombiesWithinRadius`, …) instead take an
> explicit `Location` (they carry a `TransformOrLocation` argument), e.g.
> `DestroyCorpsesWithinRadius 5000 Location <SteamID>`.

### 7. Silence / Unsilence

```
Silence <SteamID>
Unsilence <SteamID>
```

### 8. List commands

Most list commands (`ListPlayers`, `ListSquads`, `ListMutedPlayers`, …) run.

`ListPlayers`, `ListSquads`, `ListSpawnedVehicles` and `ListSpawnedAnimals` read
their data directly (a native object-array walk or a `SCUM.db` query), so they
keep returning real output after SCUM 1.3.1 broke the old client-RPC reply path.
`ListSpawnedVehicles` now also reports each vehicle's **custom name** and its
**owner's database id**, not just the model; `ListSquads` resolves all members in
one bulk query instead of a request per member.

**`ListSpawnedVehicles` is the exception**. Because the list can be long, the reply
may exceed Source-RCON's 4096-byte per-packet limit and is then split across
**multiple packets** (same request id). Use an RCON client that supports
multi-packet responses to see the whole list — the bundled **`rcon_console`**
handles this; `mcrcon` reads only the first packet (roughly the first 60
vehicles).

### 9. Inventory — limited support

```
#Inventory <PlayerId> SpawnAndAddItems <item> <count> <online-SteamID>
```

**Only `SpawnAndAddItems` works over RCON** — it grants items into the target's
inventory. End the line with an online player's SteamID; at least one player must be online.

**The `Character_*`/`Grid_*` sub-commands do NOT work over RCON.** That covers
`Character_SetItemInHands`, `…_SetItemOnLShoulder` / `…_OnRShoulder`,
`Character_EquipClothes` / `…_UnequipClothes`, `Character_Pickup`,
`Grid_AddOrMoveEntry`, `RemoveEntry`. They are server-authoritative inventory
operations gated on live game state that the RCON dispatch path cannot reproduce,
so they **silently do nothing**. This is an engine limitation of driving those ops from outside
a real client, not a bug we can fix from the RCON side.

> **`#Inventory` is a SCUM dev command.** Run *in-game*, even a
> configured elevated admin gets `Player must be developer.` — that is normal
> SCUM behaviour, not an RCON problem. Over RCON the mod dispatches regardless of executor level.

---

### 10. Show-* — client-rendered map / HUD toggles

**`ShowNamePlates` works** — it toggles a target player's name-plate display.
End the line with that player's online SteamID (it acts on that player):

```
#ShowNamePlates true <SteamID>
#ShowNamePlates false <SteamID>
```

**The map overlays are NOT supported over RCON:** `ShowOtherPlayerLocations` /
`…Info`, `ShowVehicleLocations` / `…Info`, `ShowFlagLocations` / `…Info`,
`ShowArmedNPCsLocation`, `ShowZombiesLocation`, `ShowAnimalLocation`. Those are
rendered on the *client* and the server can only light them by faking that
client's local admin status which, as a side effect, unlocked admin UI
on a regular player's own screen (the admin chat tab, the "remove admin locks"
prompt, etc.). Nothing there actually worked but it confused players. That is a client feature,
not native server-side dispatch, so it has been removed along with the admin
spoof. `ShowNamePlates` is the exception because it needs no such spoof.

---

### 11. DeleteActiveQuestsForUser — unstick a quest login-lockout

```
DeleteActiveQuestsForUser <SteamID>
```

Deletes **all** `active_quest` rows for the given player from the live
`SCUM.db`. Use it when a player is kicked on every login because the server
crashes while spawning a broken quest's interactables (observed with the T3
city-scan quest, which overflows the reliable buffer → the player is
force-closed before they can abandon it, so the row never clears and the loop
repeats). The player can't fix this themselves; this command can.

- **Target need NOT be online** — unlike the other player commands this writes
  the DB directly, so run it *while the affected player is logged out*, then let
  them reconnect.
- Reply: `deleted N active quest(s) for <SteamID>`. `N = 0` means the player had
  no active quests (or the SteamID is unknown).
- This is a **write** to the live DB. It is safe because SCUM runs `SCUM.db` in
  WAL mode (a second writer only contends on the short write lock, never blocks
  the server's reads) and the delete runs on the RCON worker thread, never the
  game thread. Deletes *all* of that player's active quests, not just the broken
  one — they re-acquire quests normally afterwards.

#### Finding & clearing a blocked quest in bulk

`DeleteActiveQuestsForUser` fixes one known player. When a whole quest is the
culprit, name it once in `config.ini` and let the mod find/clear it for everyone:

```
[quests]
blocked = T3_DC_Interact_ScanAbandonedCity
```

Names are matched by **stem**, so any form works — a vanilla name, a
`Quests/Override/<name>.json` path, or a bare stem. Comma-separate several.

- **`FindQuestLockouts`** — *read-only*, no SteamID. Lists every player still
  holding a blocked quest (the lockout candidates). Use it to see who's affected
  before clearing anything.
- **`RunQuestUnstick`** — deletes the blocked-quest rows for **all** matching
  players now. A circuit breaker (`auto_unstick_max_delete`) aborts the sweep if
  more rows would go than that (guards a too-broad list). Preview with
  `FindQuestLockouts` first.

**Auto-Unstick** runs that sweep once automatically at server boot — a
locked-out player is freed before they even try to log in, no admin action.
**Off by default**; opt in via `config.ini`:

```
[quests]
blocked = T3_DC_Interact_ScanAbandonedCity
auto_unstick = true
auto_unstick_dry_run = true      ; log what WOULD be deleted, delete nothing
auto_unstick_max_delete = 25     ; circuit breaker
```

Safe rollout: set `blocked` → `FindQuestLockouts` to preview → `auto_unstick =
true` with `auto_unstick_dry_run = true` and check the boot log line
`auto-unstick (boot): N match(es), 0 deleted [dry-run]` → once it looks right,
set `dry_run = false`. Every delete runs on the RCON worker thread (never the
game thread) and only touches the quests you listed.

---

### 12. Unstuck — free a player stuck in geometry

```
Unstuck <SteamID>
```

Lifts the player **2 m straight up** from their current position (same X/Y, only
Z changes), which is enough to pop them out of terrain/objects they are wedged
in. 2 m is under SCUM's fall-damage threshold, so they take no damage on landing.

- **Target must be online** — the mod reads the live pawn position, then runs the
  native `Teleport` to `(x, y, z + 2 m)`.
- Reply: `unstuck: lifted <SteamID> +2m (z <old> -> <new>)`.
- This is the in-place **Z-lift**. The web panel's player modal additionally
  offers a *history-aware* unstuck (teleport to the last safe position from the
  movement trail) — that one stays panel-side.

---

### 13. Whois — instant player dossier from the DB

```
Whois <SteamID | name>
```

Reads a full profile straight from the live `SCUM.db` — **the player need not be
online**. Accepts a 17-digit SteamID or a (partial) character name.

Reply (one dossier, several lines):

```
Whois: <name>  (SteamID <steam>)
  Fame: <n>   Money: <n>
  Kills: <n>  Deaths: <n>  K/D: <r>  Puppets: <n>  HS: <n>
  Playtime: <h> h
  Squad: <name | ->
  Vehicles owned: <n>
```

- **Read-only** — never writes the DB.
- **Schema-robust** — it probes the DB layout at runtime; a missing table or
  column degrades to `0` / `-` instead of erroring, so a SCUM schema change
  won't break it.
- `No player found for "<query>".` means the name/SteamID didn't resolve.

---

### 14. Sentry / mech area-control

Enumerate and clear the roaming military mechs (`ASentry2`) that no external tool
can reach — these walk the live object array in-process.

```
ListSentries
DestroySentriesWithinRadius <radius> <x> <y> <z>
RespawnSentriesWithinRadius <radius> <x> <y> <z>
SuppressSentryRespawn <on|off>
```

- **`ListSentries`** — every *active* sentry with world position. Sentries
  reporting origin `(0,0,0)` are destroyed/deactivated corpses still awaiting GC
  and are filtered out, so the list is the live mechs only.
- **`DestroySentriesWithinRadius <radius> <x> <y> <z>`** — destroys every sentry
  within `radius` cm of the point. It turns suppression **on first** (see the
  warning), so the cleared mechs don't instantly respawn and don't provoke a
  defender horde. One command → a mech-free event zone.
- **`RespawnSentriesWithinRadius`** — lifts the suppression again; the mechs
  return. (The radius args are kept for symmetry; the suppression it reverses is
  global.)
- **`SuppressSentryRespawn <on|off>`** — the manual switch for that same
  suppression, on its own.

> ⚠️ **Suppression is GLOBAL, not per-radius.** It works by freezing the single
> server-wide guarded-zone manager, so while it's on, the whole military
> guarded-zone system pauses **everywhere on the map**: no sentry respawns in any
> guarded zone, and shooting sentries no longer triggers the defender-horde
> response. Nothing is deleted or reconfigured; mechs already spawned keep acting
> on their own AI; abandoned bunkers and cargo/convoy encounters are separate
> systems and keep running. Always lift it after your event
> (`RespawnSentriesWithinRadius` or `SuppressSentryRespawn off`).

---

## Quick reference: who needs a SteamID?

| Command type | Trailing SteamID? | Notes |
|---|---|---|
| Standard (Announce, SetTime, …) | no | server-side |
| Player-affecting (GodMode, skills, injuries) | **yes** | target must be online |
| SendNotification | **yes** (recommended) | or an internal id without SteamID |
| SendChat | **yes** | target must be online |
| Spawn at player | **yes** (as `Location`) | or a coord struct / bare X Y Z |
| Spawn at coords | no | use `Location "{…}"` or `Location X Y Z` |
| SpawnInventoryFullOf | optional | coords (keyed/struct) place it freely; SteamID = at that player; else first online |
| SpawnBrenner / SpawnRazor | optional | coords place it; SteamID = at that player; else world origin |
| ForceDropship/AnimalEncounter | optional | coords (keyed/struct) place it freely; SteamID = at that player; else first online |
| Silence / Unsilence | **yes** | |
| ListSpawnedVehicles | no | multi-packet reply |
| Inventory (SpawnAndAddItems only) | **yes** | target online; Character_/Grid_* unsupported |
| ShowNamePlates | **yes** | target need to be online |
| Unstuck | **yes** | target online; +2 m Z-lift via native Teleport |
| DeleteActiveQuestsForUser | **yes** | DB write; target should be **offline** |
| FindQuestLockouts | no | read-only; lists players holding a `[quests] blocked` quest |
| RunQuestUnstick | no | DB write; clears blocked-quest rows for all matching players |
| Whois | no | read-only DB dossier; accepts a SteamID **or** a name; target may be offline |
| ListSentries | no | active sentries only (`0,0,0` corpses filtered) |
| DestroySentriesWithinRadius | no | args `<radius> <x> <y> <z>`; auto-suppresses respawn first |
| RespawnSentriesWithinRadius | no | lifts suppression (global) — mechs return |
| SuppressSentryRespawn | no | `<on\|off>`; **global** guarded-zone freeze |

---

## Common pitfalls

- **Spawn lands at moon** — no `Location` argument, or the location was a
  quoted list of bare numbers. Use a coord struct, a SteamID, or bare `X Y Z`.
- **Player command does nothing or "not online"** — the target SteamID must
  belong to a **currently online** player.
- **Two-word name not found** — wrap it in quotes:
  `Teleport X Y Z "First Last"`.
- **ListSpawnedVehicles shows only ~60 vehicles** — your RCON client only read
  the first packet. The list is split across multiple packets; use a
  multi-packet-capable client (the bundled `rcon_console` handles it; `mcrcon`
  does not).
- **#Inventory: `'...' is not a valid item entity setup`** — the item needs its
  `_ES` "entity setup" name (e.g. `Weapon_AKM_ES`, not `Weapon_AKM`). See
  section 9.
- **#Inventory: `Could not find entity`** — `<PlayerId>` must be the target's
  17-digit SteamID (the mod resolves it) or the numeric entity id — not the name
  or an internal db id. The target must be online.
- **Command replies `server still starting …`** — the mod holds every command
  until the server has fully booted (it watches the log for BattlEye's master
  connection). Wait a few seconds and retry.
- **#Inventory Character_ does nothing** — those sub-commands are unsupported
  over RCON (see section 8); only `SpawnAndAddItems` works.
- **Show-* commands do nothing** — the client-rendered map overlays
  (`ShowVehicleLocations`, `ShowFlagLocations`, `ShowOtherPlayer*`, …) are not
  supported over RCON (see section 10); they required faking client admin status,
  which is out of scope for this mod. `ShowNamePlates` is the one that works —
  end it with the target's online SteamID.
- **A player got banned after I gave them `SetGodMode`** — expected for a
  non-admin: free-building while godmoded trips SCUM's own anti-cheat. Only
  godmode real server admins (see the warning under section 2).
- **Sentries won't respawn anywhere on the map** — suppression from
  `SuppressSentryRespawn on` / `DestroySentriesWithinRadius` is **global**, not
  scoped to your radius (see section 14). Lift it with
  `RespawnSentriesWithinRadius` or `SuppressSentryRespawn off`.
