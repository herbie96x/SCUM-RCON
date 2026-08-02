# SCUM-RCON — Linux / WINE / Proton Setup

Running a SCUM Dedicated Server on Linux (WINE or Proton) and want to load
SCUM-RCON? There's **one extra step** compared to native Windows. Everything
else — the `scum_rcon` folder, `config.ini`, the password — is identical to the
Windows install. Many thanks goes to **Trelain** who pointed that out!

---

## The one thing you have to do

SCUM-RCON loads through a `dwmapi.dll` shim in the server's `…/Win64/` folder.
On Linux, **WINE/Proton ships its own built-in `dwmapi`** and prefers it, so the
shim in the game folder is ignored — and the mod never loads.

Fix: tell WINE to use the **native** `dwmapi.dll` (the one in `Win64/`) instead
of its built-in. That's a single environment variable:

```
WINEDLLOVERRIDES=dwmapi=n,b
```

- `n` = **native first** (the `dwmapi.dll` from the game folder — our shim),
- `b` = **built-in as fallback** (WINE's own, so nothing else breaks).

Set it in the environment of the process that launches `SCUMServer.exe`. Where
exactly depends on how you run the server (systemd unit, launch script, or an
instance manager — see below).

> This is a WINE/Proton loading quirk, not a SCUM-RCON bug. The same override is
> what any `dwmapi`-based UE4SS setup needs under WINE.

---

## AMP instance manager (Ubuntu 24.04 and similar)

AMP passes environment variables to the server through the instance's
`GenericModule.kvp`. Add `WINEDLLOVERRIDES` to the `App.EnvironmentVariables`
line so WINE loads the native `dwmapi.dll` from `Win64/`:

```
App.EnvironmentVariables={"SteamAppId":"513710","STEAM_COMPAT_DATA_PATH":"{{$FullRootDir}}.proton/compatdata","STEAM_COMPAT_CLIENT_INSTALL_PATH":"{{$FullBaseDir}}.steam/steam","HOME":"{{$FullBaseDir}}","WINEDLLOVERRIDES":"dwmapi=n,b"}
```

The load-bearing part is the added key:

```
"WINEDLLOVERRIDES":"dwmapi=n,b"
```

> Edit `GenericModule.kvp` the proper AMP way (through AMP's config handling, not
> by hand while the instance is running). If you use AMP you already know how —
> we won't re-explain AMP config editing here.

---

## systemd / launch script (no instance manager)

If you start the server yourself, just export the variable before launching:

```bash
# in your launch script, before running SCUMServer.exe
export WINEDLLOVERRIDES="dwmapi=n,b"
```

or, for a systemd unit:

```ini
[Service]
Environment=WINEDLLOVERRIDES=dwmapi=n,b
```

---

## Verify it loaded

After restarting the server with the override set, check the UE4SS log:

```
…/Win64/ue4ss/UE4SS.log
```

You should see SCUM-RCON come up, e.g.:

```
[SCUM-RCON] init - v0.4.7
[SCUM-RCON] SCUM-RCON ready - listening on 0.0.0.0:<port>
```

If those lines are missing, the override didn't take — the mod isn't being
loaded. Double-check the env var reached the `SCUMServer.exe` process (a common
miss is setting it in the wrong shell/scope, so the server never sees it).

---

## Troubleshooting

- **No `[SCUM-RCON]` lines in `UE4SS.log` at all** → the `dwmapi` shim isn't
  loading. The `WINEDLLOVERRIDES=dwmapi=n,b` didn't reach the server process.
- **UE4SS loads but no SCUM-RCON** → that's a normal mod-install problem, not a
  Linux one: check the `scum_rcon` folder is in the UE4SS `Mods` directory with
  its `dlls/main.dll` and an `enabled.txt`.
- **Everything loads but the listener won't start** → not Linux-related; set a
  real `password` in `config.ini` (the listener refuses to start on the default
  placeholder).

