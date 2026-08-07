# SCUM-RCON by skrypt.gg

[![Latest release](https://img.shields.io/github/v/release/herbie96x/SCUM-RCON?label=release&color=success)](https://github.com/herbie96x/SCUM-RCON/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/herbie96x/SCUM-RCON/total?label=downloads)](https://github.com/herbie96x/SCUM-RCON/releases)
[![License: free-to-use (EULA)](https://img.shields.io/badge/license-free--to--use%20(EULA)-brightgreen)](LICENSE)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?logo=discord&logoColor=white)](https://discord.gg/HhSraTKfrW)
[![Support on Ko-fi](https://img.shields.io/badge/Ko--fi-support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/skrypt)


A fully compliant **Source RCON** server for SCUM dedicated servers. Execute admin commands seamlessly from any Source-RCON-compatible client—including the bundled `rcon_console`, mcrcon, rcon-cli, WebRcon, or your custom Discord bots. No in-game admin character required.

Anything that speaks the Valve Source RCON protocol can connect to it. The download is a drop-in bundle that includes UE4SS, meaning there is absolutely no additional setup or dependencies required.

> ⚠️ **Disclaimer:** Use at your own risk. There is no warranty or guarantee against future game updates breaking the mod, or against potential bans.

> ⚖️ **Zero-Tolerance Policy:** SCUM-RCON is free for server owners and not licensed for commercial use — there is no paid tier, and no commercial license is available. Any monetized product, paid installer, bundled software, or commercial hosting service found shipping or integrating SCUM-RCON will face an immediate DMCA takedown directed at their hosting provider and domain registrar — **without any prior warning**.

---

## Features

* **True Source RCON:** Implements the standard Valve Source RCON protocol — use your existing tooling, no proprietary client. Long replies (like `ListSpawnedVehicles`) are split across packets instead of truncated.
* **In-Game Commands:** Every SCUM-RCON command also works straight from the in-game admin chat as `#CountItemsWithinRadius …`, `#SetEnv …`, `#Whois …`. Admin-gated against your `AdminUsers.ini`, and it stays out of the way of vanilla commands.
* **Write Your Own Commands:** A plugin API lets any UE4SS **Lua** mod add commands to SCUM-RCON — a few lines, nothing to compile. Your command answers over RCON and in-game, is told who ran it (SteamID, admin status), and can be admin-only or open to every player. `LuaReload <mod>` reloads your script live, so you iterate without restarting the server. C++ mods get the same through an exported C interface.
* **Live Survival Tuning:** Change how fast players get **wet**, **dry off**, get **rained on** and get **dirty** while the server runs — no restart. Set the defaults in `config.ini`, adjust on the fly with `SetEnv`.
* **SteamID-First Routing:** Commands targeting players or inventories take plain SteamIDs; the mod resolves them to the entity IDs the engine wants and picks the right dispatch path (player, location, or direct) for you. Spawn commands need a player as their context — name one in `config.ini` and their confirmation lines stop popping up on whichever player happened to be online.
* **Free Placement:** Caller-anchored spawns and encounters (`SpawnBrenner`, `SpawnRazor`, `SpawnInventoryFullOf`, `ForceDropshipEncounter`, `ForceAnimalEncounter`) can be dropped at any coordinate or sent to a specific player instead of landing at world origin — optionally snapped to the terrain so nothing floats or clips under it.
* **Quest Lockout Recovery:** Frees players who are permanently kicked on every login by a broken quest — pinpoint who's affected, clear the offending quest straight from the live database, or wipe it automatically at boot.
* **Player Unstuck:** Lift a player wedged in terrain or geometry 2 m straight up via native teleport — no fall damage, no flinging them across the map.
* **Live Database Reads:** Player lookups, vehicle owners, squads and flags read straight from the server database — accurate no matter who's online, opened read-only, and answered without ever touching the game thread.
* **Hardened Runtime:** Commands sent before the world is up are answered straight away instead of hanging. Wrong RCON passwords cost the caller a second and lock the address out after five tries; silent connections can't squat the listener. Works on servers where AV/EDR (Defender, Bitdefender, ESET…) has rewritten the game's code in memory, and the bundled UE4SS survives the stale-object iteration that used to take whole servers down.
* **Scripted Client:** The bundled bilingual (EN/DE) console chains commands with `;` and pauses with `sleep <seconds>` — drive a timed restart sequence from a single line, interactively or piped from a bot.
* **Drop-In Install:** Extract the bundle into `Win64`, set a password, start the server — UE4SS is included and pre-configured. Or run `SCUM-RCON-Setup-0.X.X.exe` and let the installer place everything for you.

---

## ❓ Why a real RCON server?

While some "RCON" mods bypass the standard protocol and run commands as in-engine scripts, **SCUM-RCON** implements the actual Valve Source RCON protocol. 

* **Universal Compatibility:** Your existing tools (client, dashboards, bots) connect perfectly right out of the box, over the network, from anywhere.
* **No Vendor Lock-in:** You aren't tied to a specific mod's proprietary command format or custom client. Your client, your rules.
* **Engineered Stability:** Dispatching is handled via compiled C++ behind Structured Exception Handling guards. The authentication path is strictly audited, and the boot gate prevents commands from executing before the server is ready.

---

## 🚀 Install

1.  **Download** the `SCUM-RCON-Setup-X.X.X.exe` from the release section.
2.  **Double-click** the Setup.exe.
3.  **Choose** for with **user scope** it should get installed.
4.  **Select** your preferred **language** (en/de).
5.  **Select** the desired **installation folder for RCON and installation scope**; you can install just the mod or the entire bundle, including the console and tester GUI. The installer will automatically detect the SCUM Server installation; adjust the path if necessary.
6.  **Configure** your desired **settings**, such as `IP`, `port`, `password`, and `max. connections`.
7.  You can optionally let the installer create a desktop shortcut.
8.  The installer is now installing.

---

## ⚙️ Manual Install

1.  **Download** the `Win64.zip` from the [latest release](https://github.com/herbie96x/SCUM-RCON/releases/latest).
2.  **Extract** the contents (`dwmapi.dll` and the `ue4ss` folder) directly into your server's `SCUM\Binaries\Win64\` directory.
3.  **Configure** your credentials. Open `ue4ss\Mods\scum_rcon\config.ini` and set a secure password. *(Note: The listener will refuse to start if the password remains `CHANGE_ME_BEFORE_USE`)*.

    ```ini
    bind_address = 127.0.0.1
    port = 28015
    password = CHANGE_ME_BEFORE_USE  ; Change this!
    ```

4.  **Start your server.** Check `ue4ss\UE4SS.log` for the `[SCUM-RCON]` entries to verify the listener address (default is `127.0.0.1:28015`) or to troubleshoot if it didn't start.

> 🔒 **Security Note:** Source RCON is unencrypted by design. Never expose the RCON port to untrusted networks without a strong password.

*For comprehensive step-by-step instructions, please refer to the **MANUAL_INSTALL.txt** file included in the download. The easiest way is to use the installer.*

---

## 💻 Use

📚 **Read the guide in [USAGE.md](USAGE.md)** for details on chat-color codes, SteamID command requirements, spawn-location formats, and common pitfalls.

---

## ⚡ Support & Early Access: The Zero-Day Tier

SCUM-RCON is free and it always will be. That doesn't change.

Here's what does: every SCUM patch eventually breaks RCON. You know the drill — an update drops and tools and mods go dark for days. Getting it working
again means immediate, deep reverse-engineering to repair the Mod.

To keep that sustainable, there's now the **Zero-Day Tier** on Ko-fi (€3.5/mo):

* **Zero-Day (EA) Supporters** get every patch-fix first — right in the critical window after an update, when downtime hurts most.
* **Everyone else** gets the exact same fix for free — just a few days later, once it's verified stable.

You're not paying for RCON. You're paying to skip the line, cut your server's downtime, and fund the hardware and upkeep that keep this project alive.
Don't want to? You still get everything, 100% free, exactly as before.

Only need the fast fix for one patch? Subscribe, grab it, cancel anytime — that's completely fine. You supported the project exactly when it helped you.

If the tool's worth something to you → **[Support on Ko-fi](https://ko-fi.com/skrypt)**.
If not, no hard feelings.

---

## 📄 License

This project is closed-source but **free to use** for personal, non-commercial users under the EULA found in the `LICENSE` file. 

* **Permitted:** Downloading and running it on your own servers for free, provided your server complies with SCUM's EULA.
* **Restricted:** Selling, modifying, or redistributing outside the official release channel.
* **Third-Party:** The bundled UE4SS is licensed under MIT.

*SCUM-RCON is an independent project and is not affiliated with Gamepires. SCUM is a trademark of Gamepires.*

Built with AI support, reviewed by a human.
