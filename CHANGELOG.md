# SCUM-RCON — Changelog

User-facing changes. See `USAGE.md` for how to use the commands.

## 0.2.0

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
