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
  quotes. `Teleport 1000 2000 300 "SUPER ADMIN ` finds the two-word player;
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
SetGodMode true <steamid>
SetImmortality true <steamid>
DisableBodyEffects true <steamid>
SetInfiniteStamina true <steamid>
SetAttributes 3 3 3 3 <steamid>
SetSkillLevel Driving 5 <steamid>
AddBleedingInjury <steamid>
AddRadiationPresence <steamid>
Suicide <steamid>
Knockout 30 <steamid>
```

If the target isn't online you get `player <steamid> is not online`.

### 3. SendNotification — pop-up / toast / banner

A short on-screen notification to one player. **Recommended form** (resolves
the internal id from the SteamID for you):

```
SendNotification <type> 0 "<message>" <steamid>
```

The `0` is a placeholder — it's overwritten automatically. Example:

```
SendNotification 2 0 "Welcome to the server!" <steamid>
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
SendChat <type> "<message>" <steamid>
```

| type | Colour | Channel feel |
|---|---|---|
| **0** | white | default |
| 1 | white | local |
| **2** | blue | global |
| **3** | green | squad |
| **4** | yellow | admin |
| **6** | orange | server message |
| **7** | red | error / warning |

Example:

```
SendChat 4 "Bounty claimed: +500" <steamid>      (yellow)
SendChat 7 "You entered a no-build zone" <steamid>   (red)
```

### 5. Spawning at a location

`SpawnItem`, `SpawnVehicle`, `SpawnZombie` and friends spawn at the **caller's**
position by default — over RCON that's world origin `(0,0,0)`, which is almost
never what you want. Give an explicit `Location` instead. Three accepted forms:

**a) Coordinate struct** (full position + rotation — the form SCUM's own docs
use):

```
SpawnVehicle BPC_Rager 1 Location "{X=140220.3 Y=-68551.4 Z=34645.6|P=0 Y=270 R=0}"
SpawnItem Military_Backpack_02_04 1 Location "{X=289265 Y=-188112 Z=15217|P=0 Y=0 R=0}"
```

**b) At a player's position** — give the player's SteamID as the location:

```
SpawnItem Apple 1 Location <steamid>
```

**c) Bare coordinates** (X Y Z, no rotation):

```
SpawnItem Apple 1 Location 289265 -188112 15217
```

> The struct in **(a)** contains spaces, so it **must** be quoted. A common
> mistake is `Location "289265 -188112 15217"` (three bare numbers in quotes) —
> that is **not** valid; use one of the three forms above.

### 6. Silence / Unsilence

```
Silence <steamid>
Unsilence <steamid>
```

### 7. List commands (read-only)

`ListPlayers`, `ListSquads`, `ListMutedPlayers`, … run, but their output goes
through an internal path RCON can't capture, so you'll get a short canned reply
rather than the live list. To read the real lists, query SCUM's own
database / logs. (See "Known Limitations" in `INTEGRATION.md`.)

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
| Silence / Unsilence | **yes** | |

---

## Common pitfalls

- **`unknown command: '#spawnitem'`** — you sent `#SpawnItem` and the `#` got
  attached; harmless now (it's stripped), but if you see this on an older build,
  drop the `#`.
- **Spawn lands at (0,0,0)** — no `Location` argument, or the location was a
  quoted list of bare numbers. Use a coord struct, a SteamID, or bare `X Y Z`.
- **Player command does nothing / "not online"** — the target SteamID must
  belong to a **currently online** player.
- **Two-word name not found** — wrap it in quotes:
  `Teleport X Y Z "First Last"`.
- **Notification/chat not visible** — check the type code (type 3 is silent),
  and that the target SteamID is online.
