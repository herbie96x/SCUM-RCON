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

**`SpawnInventoryFullOf`** is the exception that has **no `Location`**: it spawns
a container and fills it, and SCUM always places it **in front of the player**.
Over RCON it is therefore routed through an online player, so **at least one player must be online**, 
and the container appears in front of *that* player.

```
SpawnInventoryFullOf <Container> <SetCount> <Item1> <Item2> … <SteamID>
SpawnInventoryFullOf Improvised_Metal_Chest 1 Weapon_AKM 3
SpawnInventoryFullOf Improvised_Metal_Chest 1 Weapon_AKM 3 76561XXXXXXXXXXXX
```

`<SetCount>` is how many times the whole item set is placed into the container.
**Multiple item names are allowed** — each is added to the container.

### 6. Encounters at a player (`ForceDropshipEncounter`, `ForceAnimalEncounter`)

These spawn an encounter at a **player's location** and take **no** coordinate
argument. Over RCON, append the target player's **SteamID** so the encounter spawns at *that* player.
Without an online player it falls back to world origin.

```
ForceDropshipEncounter <SteamID>
ForceAnimalEncounter <SteamID>
ForceDropshipEncounter 76561XXXXXXXXXXXX
```

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

## Quick reference: who needs a SteamID?

| Command type | Trailing SteamID? | Notes |
|---|---|---|
| Standard (Announce, SetTime, …) | no | server-side |
| Player-affecting (GodMode, skills, injuries) | **yes** | target must be online |
| SendNotification | **yes** (recommended) | or an internal id without SteamID |
| SendChat | **yes** | target must be online |
| Spawn at player | **yes** (as `Location`) | or a coord struct / bare X Y Z |
| Spawn at coords | no | use `Location "{…}"` or `Location X Y Z` |
| SpawnInventoryFullOf | optional | SteamID = target player (dropped from items); else first online; ≥1 player online |
| ForceDropship/AnimalEncounter | optional | SteamID = target player; else first online; no coord arg |
| Silence / Unsilence | **yes** | |
| ListSpawnedVehicles | no | multi-packet reply |
| Inventory (SpawnAndAddItems only) | **yes** | target online; Character_/Grid_* unsupported |
| ShowNamePlates | **yes** | target need to be online |

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
