# SCUM-RCON by skrypt.gg

[![Latest release](https://img.shields.io/github/v/release/herbie96x/SCUM-RCON?label=release&color=success)](https://github.com/herbie96x/SCUM-RCON/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/herbie96x/SCUM-RCON/total?label=downloads)](https://github.com/herbie96x/SCUM-RCON/releases)
[![License: free-to-use (EULA)](https://img.shields.io/badge/license-free--to--use%20(EULA)-brightgreen)](LICENSE)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?logo=discord&logoColor=white)](https://discord.gg/HhSraTKfrW)
[![Support on Ko-fi](https://img.shields.io/badge/Ko--fi-support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/skrypt)

A fully compliant **Source RCON** server for SCUM dedicated servers. Execute admin commands seamlessly from any Source-RCON-compatible client—including the bundled `rcon_console`, mcrcon, rcon-cli, BattleMetrics, WebRcon, or your custom Discord bots. No in-game admin character required.

Anything that speaks the Valve Source RCON protocol can connect to it. The download is a drop-in bundle that includes UE4SS, meaning there is absolutely no additional setup or dependencies required.

> ⚠️ **Disclaimer:** Use at your own risk. There is no warranty or guarantee against future game updates breaking the mod, or against potential bans.

---

## ✨ Features

* **True Source RCON:** Implements the standard Valve Source RCON protocol. Use your existing tooling without proprietary clients.
* **Offline Administration:** Commands are dispatched natively inside the server process. No ingame admin needed.
* **Drop-In Bundle:** Ships pre-configured with UE4SS. Just extract into `Win64`, set a password and start your server.
* **SteamID-First:** Commands targeting players or inventories accept SteamIDs. The mod automatically resolves them to the engine's required entity IDs.
* **Boot Gate Protection:** Safely holds incoming commands in a queue until the server is genuinely ready.
* **Multi-Packet Replies:** Long server outputs (like `ListSpawnedVehicles`) are delivered flawlessly without truncation.
* **Smart Routing:** Broad command coverage with automated player, location, and SteamID routing handled for you.
* **Quest Lockout Recovery:** Frees players who are permanently kicked on every login by a broken quest — pinpoint who's affected, clear the offending quest straight from the live database, or wipe it automatically at boot.
* **Free Placement:** Caller-anchored spawns and encounters (`SpawnBrenner`, `SpawnRazor`, `SpawnInventoryFullOf`, `ForceDropshipEncounter`, `ForceAnimalEncounter`) can be dropped at any coordinate or sent to a specific player.
* **Player Unstuck:** Lift a player wedged in terrain or geometry 2 m straight up via native teleport — no fall damage, no flinging them across the map.
* **Live Database Reads:** The SteamID→entity resolver, the vehicle-owner lookup and squad lists read straight from the server database — accurate no matter who's online — opened read-only so they can never block or freeze the game thread.
* **Crash-Hardened Runtime:** The bundled UE4SS survives the stale/freed objects during iteration that previously took whole servers down and flags inline-hooking AV/EDR (Bitdefender, Defender, ESET…) that can destabilise the process.
* **Scripted Client:** The bundled bilingual console chains commands with `;` and pauses with `sleep <seconds>` — drive a timed restart sequence from a single line, interactively or piped from a bot.

---

## ❓ Why a real RCON server?

While some "RCON" mods bypass the standard protocol and run commands as in-engine scripts, **SCUM-RCON** implements the actual Valve Source RCON protocol. 

* **Universal Compatibility:** Your existing tools (BattleMetrics, dashboards, bots) connect perfectly right out of the box, over the network, from anywhere.
* **No Vendor Lock-in:** You aren't tied to a specific mod's proprietary command format or custom client. Your client, your rules.
* **Engineered Stability:** Dispatching is handled via compiled C++ behind Structured Exception Handling guards. The authentication path is strictly audited, and the boot gate prevents commands from executing before the server is ready.

---

## 🚀 Install

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

*For comprehensive step-by-step instructions, please refer to the **INSTALL.txt** file included in the download.*

---

## 💻 Use

The releases includes **`rcon_console.exe`**, a ready-to-run bilingual RCON client. 
Simply double-click it, configure `ini\scum_rcon.ini` (host, port, password) and send admin commands as plain text:

```text
rcon> Announce hello world
rcon> ListSpawnedVehicles
```

**Community Client Alternatives:**
Prefer a different client? [SCUM-RCON-Client](https://github.com/Neo2Go/SCUM-RCON-Client) by @Neo2Go is a lightweight, single-binary Go client that is config-compatible with the bundled console. 
*(Note: This is an independent community project and is used at your own discretion).*

📚 **Read the full guide in [USAGE.md](USAGE.md)** for details on chat-color codes, SteamID command requirements, spawn-location formats, and common pitfalls.

---

## 🤝 Contributing & Collaboration

* **Collaboration:** Want to work together? Open a **Collaboration request** issue and review our **[CONTRIBUTING.md](CONTRIBUTING.md)**.
* **Bugs & Questions:** Please open an issue on GitHub or post in the Nexus Mods comments/bug section on the SCUM-RCON page.

---

## ⚡ Support & Early Access — The Zero-Day Tier

SCUM-RCON is free, and it always will be. That doesn't change.

Here's what does: every SCUM patch eventually breaks RCON. You know the drill — an update drops and tools and mods go dark for days. Getting it working
again means immediate, deep reverse-engineering to repair the Mod.

To keep that sustainable, there's now the **Zero-Day Tier** on Ko-fi (€3.5/mo):

* **Zero-Day (EA) Supporters** get every patch-fix first — right in the critical window after an update, when downtime hurts most.
* **Everyone else** gets the exact same fix for free — just a few days later, once it's verified stable.

You're not paying for RCON. You're paying to skip the line, cut your server's downtime, and fund the hardware and upkeep that keep this project alive.
Don't want to? You still get everything, 100% free, exactly as before.

Only need the fast fix for one patch? Subscribe, grab it, cancel anytime — that's completely fine. You supported the project exactly when it helped you.

If the tool's worth something to you → **[Support on Ko-fi](https://ko-fi.com/skrypt)**.
If not, no hard feelings — it's all still yours.

---

## 📄 License

This project is closed-source, but **free to use** under the EULA found in the `LICENSE` file. 

* **Permitted:** Downloading and running it on your own servers for free, provided your server complies with SCUM's EULA.
* **Restricted:** Selling, modifying, or redistributing outside the official release channel.
* **Third-Party:** The bundled UE4SS is licensed under MIT.

*SCUM-RCON is an independent project and is not affiliated with Gamepires. SCUM is a trademark of Gamepires.*
