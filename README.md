# SCUM-RCON

[![Latest release](https://img.shields.io/github/v/release/herbie96x/SCUM-RCON?label=release&color=success)](https://github.com/herbie96x/SCUM-RCON/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/herbie96x/SCUM-RCON/total?label=downloads)](https://github.com/herbie96x/SCUM-RCON/releases)
[![License: free-to-use (EULA)](https://img.shields.io/badge/license-free--to--use%20(EULA)-brightgreen)](LICENSE)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?logo=discord&logoColor=white)](https://discord.gg/HhSraTKfrW)

A standard **Source RCON** server for SCUM dedicated servers. Run admin
commands on your server from any Source-RCON-compatible client — the bundled
`rcon_console`, mcrcon, rcon-cli, BattleMetrics, WebRcon, a custom Discord bot,
your own tooling — and you don't need an admin character online in-game to do it.

Anything that speaks the Valve Source RCON protocol can talk to it. The
download is a drop-in bundle that includes UE4SS, so there's nothing else to
install.

> **Use at your own risk — no warranty, and no guarantee against future game**
> **updates breaking the mod or against bans.**

## Install

1. Download `Win64.zip` from the latest release.
2. Extract its contents — `dwmapi.dll` and the `ue4ss` folder — into your
   server's `SCUM\Binaries\Win64\` directory.
3. Open `ue4ss\Mods\scum_rcon\config.ini` and set a real password — the
   listener refuses to start while it's still `CHANGE_ME_BEFORE_USE`.

   ```ini
   bind_address = 0.0.0.0
   port = 28015
   password = CHANGE_ME_BEFORE_USE   ; change this
   ```

4. Start the server. In `ue4ss\UE4SS.log`, look for the `[SCUM-RCON]` lines —
   they report the listener address (default `0.0.0.0:28015`), or why it
   didn't start.

Full step-by-step instructions are in **INSTALL.txt** inside the download.

> Don't expose the RCON port to untrusted networks without a strong password
> — Source RCON is unencrypted by design.

## Use

The download includes a ready-to-run console — **`rcon_console.exe`**,
a bilingual (English / German) RCON client. Double-click it, fill
in the `ini\scum_rcon.ini` (host, port, password), then send admin
commands as plain text:

```
rcon> Announce hello world
rcon> ListSpawnedVehicles
```

Any other Source RCON client (rcon-cli, BattleMetrics, a bot, …) works too —
SCUM-RCON speaks the standard protocol.

See **[USAGE.md](USAGE.md)** for the full guide — the notification and
chat-colour codes, which commands need a player's SteamID, the three
spawn-location forms, and the common pitfalls.

## Contributing & Collaboration

Want to collaborate more closely? Open a **Collaboration request** issue. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for details.

## License

Closed-source, **free to use** under the EULA in `LICENSE`: download and run on
your own server for free; no selling, no modifying, no redistribution outside
the official release channel. Running it is fine as long as your server
complies with SCUM's own EULA. The bundled UE4SS keeps its own license (MIT).
Not affiliated with Gamepires; SCUM is a trademark of Gamepires.

## Bugs & questions

Open an issue here, or post in the Nexus Mods comments/bug section on the SCUM-RCON page.
