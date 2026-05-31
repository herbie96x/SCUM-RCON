# SCUM-RCON

A standard **Source RCON** server for SCUM dedicated servers. Run admin
commands on your server from any Source-RCON-compatible client — mcrcon,
rcon-cli, BattleMetrics, WebRcon, a custom Discord bot, your own tooling — and
you don't need an admin character online in-game to do it.

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

Connect with any Source RCON client and send admin commands as plain text:

```
mcrcon -H <server-ip> -P 28015 -p <your-password> "Announce hello"
```

Examples:

```
SetTime 9
SendNotification 2 0 "Welcome to the server!" <steamid>
SendChat 4 "Bounty claimed: +500" <steamid>
SetGodMode true <steamid>
SpawnItem Apple 1 Location <steamid>
```

See **[USAGE.md](USAGE.md)** for the full guide — the notification and
chat-colour codes, which commands need a player's SteamID, the three
spawn-location forms, and the common pitfalls.

## License

Closed-source, **free to use** under the EULA in `LICENSE`: download and run on
your own server for free; no selling, no modifying, no redistribution outside
the official release channel. Running it is fine as long as your server
complies with SCUM's own EULA. The bundled UE4SS keeps its own license (MIT).
Not affiliated with Gamepires; SCUM is a trademark of Gamepires.

## Bugs & questions

Open an issue here, or post in the Nexus Mods comments/bug section on the SCUM-RCON page.
