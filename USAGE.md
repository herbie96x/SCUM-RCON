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

> **⚠️ `SetGodMode` and non-admin targets — read this.** GodMode in SCUM is a
> build cheat: it lets the player *fill placeable blueprints for free*
> (the "GodModeFill" interaction). But SCUM validates that interaction
> **server-side against the real admin list** — the player must be a genuine
> configured server admin. Setting GodMode over RCON flips the godmode flag (so
> the player's client *offers* free-building), but it does **not** make them an
> admin. The instant a non-admin player actually free-builds while godmoded,
> SCUM's own anti-cheat (`AConZGameMode::BanPlayerById`, an "Interaction
> Violation: GodModeFill") **auto-bans them**. This is SCUM's design, not an RCON
> bug, and it cannot be worked around from the RCON side. **Only give GodMode to
> players who are already real server admins.** (`SetImmortality` — damage
> immunity — is unaffected and safe to grant to anyone.)

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

Most list commands (`ListPlayers`, `ListSquads`, `ListMutedPlayers`, …) run, but
their output goes through an internal path RCON can't capture, so you'll get a
short canned reply rather than the live list. To read those, query SCUM's own
database / logs. (See "Known Limitations" in `INTEGRATION.md`.)

**`ListSpawnedVehicles` is the exception — it returns the real list**, one line
per vehicle (id, name, position, owner). Because the list can be long, the reply
may exceed Source-RCON's 4096-byte per-packet limit and is then split across
**multiple packets** (same request id). Use an RCON client that supports
multi-packet responses to see the whole list — the bundled **`rcon_console`**
handles this; `mcrcon` reads only the first packet (roughly the first 60
vehicles). It needs at least one player online.

### 8. Inventory — limited support

```
#Inventory <PlayerId> SpawnAndAddItems <item> <count> <online-SteamID>
```

**Only `SpawnAndAddItems` works over RCON** — it grants items into the target's
inventory. End the line with an online player's 17-digit SteamID (used as the
caller context); at least one player must be online.

**The `Character_*` / `Grid_*` sub-commands do NOT work over RCON.** That covers
`Character_SetItemInHands`, `…_SetItemOnLShoulder` / `…_OnRShoulder`,
`Character_EquipClothes` / `…_UnequipClothes`, `Character_Pickup`,
`Grid_AddOrMoveEntry`, `RemoveEntry`. They are server-authoritative inventory
operations gated on live game state (a bound entity-inventory component, the
right per-pawn execution context) that the RCON dispatch path cannot reproduce,
so they **silently do nothing** — verified across every dispatch route (direct
dispatch, target-player caller, and the per-target chat pipeline). This is an
engine limitation of driving those ops from outside a real client, not a bug we
can fix from the RCON side.

> Full give / equip-by-name (clothing on the body, item in hands, etc.) is
> provided by the **skrypt.gg** server's own plugin suite, which manipulates the
> live inventory natively. It is intentionally not part of this mod.

---

### 9. Show-* — client-rendered map / HUD toggles

```
#ShowNamePlates true <online-SteamID>
#ShowVehicleLocations true <online-SteamID>
#ShowFlagLocations true <online-SteamID>
#ShowOtherPlayerLocations true <online-SteamID>
#ShowOtherPlayerInfo true <online-SteamID>
#ShowFlagInfo true <online-SteamID>
#ShowVehicleInfo true <online-SteamID>
#ShowArmedNPCsLocation true <online-SteamID>
#ShowZombiesLocation true <online-SteamID>
#ShowAnimalLocation true <online-SteamID>
```

The `…Info` variants are the same map overlays as their `…Locations`
counterparts, with extra info; the `…Location` markers draw a line to every
NPC / zombie / animal.

These toggle a HUD/map overlay **on the target player's own client**, so they
end with that player's SteamID and the player must be online. They are routed
through the client pipeline (a `Chat_Client_*` RPC) — direct dispatch would run
the server body only and the overlay would never reach the client.

> `ShowNamePlates` shows *other* players' name plates, so on an empty server
> there is nothing to render; test with `ShowVehicleLocations` (vehicle markers
> appear on the map) when you are the only one online.

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
| ListSpawnedVehicles | no | multi-packet reply; needs a player online |
| Inventory (SpawnAndAddItems only) | **yes** | target online; Character_*/Grid_* unsupported |
| Show-* (NamePlates, VehicleLocations, …) | **yes** | toggles the target's own client HUD |

---

## Common pitfalls

- **Spawn lands at (0,0,0)** — no `Location` argument, or the location was a
  quoted list of bare numbers. Use a coord struct, a SteamID, or bare `X Y Z`.
- **Player command does nothing / "not online"** — the target SteamID must
  belong to a **currently online** player.
- **Two-word name not found** — wrap it in quotes:
  `Teleport X Y Z "First Last"`.
- **ListSpawnedVehicles shows only ~60 vehicles** — your RCON client only read
  the first packet. The list is split across multiple packets; use a
  multi-packet-capable client (the bundled `rcon_console` handles it; `mcrcon`
  does not).
- **#Inventory Character_* does nothing** — those sub-commands are unsupported
  over RCON (see section 8); only `SpawnAndAddItems` works. For full give/equip
  use the skrypt.gg plugin suite.
- **Show-* / #ShowNamePlates does nothing visible** — the target must be online
  (it toggles *their* client HUD), and `ShowNamePlates` needs other players in
  view to render anything.
- **A player got banned after I gave them `SetGodMode`** — expected for a
  non-admin: free-building while godmoded trips SCUM's own anti-cheat. Only
  godmode real server admins (see the warning under section 2).
