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

## The second thing: a TLS backend for Wine

Only relevant if the mod loads but stops at the licence check, with this in
`UE4SS.log`:

```
[SCUM-RCON] EngineHooks: license server unreachable after 8 attempts
```

SCUM-RCON talks to its licence server over **HTTPS from inside the game
process**, using Windows' own `WinHTTP`. Under Wine, WinHTTP's TLS runs through
Wine's `secur32`, and that needs **GnuTLS** on the host. Slim Docker images
usually don't ship it — and then every in-process HTTPS request fails while
everything else looks perfectly healthy.

> **`curl` working proves nothing here.** `curl` is a native Linux binary with
> its own TLS; it never touches Wine. The same is true of `ping`, `wget` and a
> reachability test from the host. Only the *in-process* request is affected.

Install the TLS backend (Debian/Ubuntu-based images):

```bash
apt-get update && apt-get install -y libgnutls30
```

On a 32-bit Wine prefix, add `libgnutls30:i386`. Then restart the server — no
mod or config change is needed, and `WINEDLLOVERRIDES` stays exactly as above.

> **That is the whole requirement.** You do **not** need `ca-certificates`, you
> do **not** need `wineboot -u`, and it does **not** matter that your Wine
> prefix has an empty certificate store — which in a Docker image it almost
> always does, because the prefix is usually created before `ca-certificates` is
> installed and Wine never backfills it afterwards.
>
> Since **v0.5.2** the mod carries the certificate authorities it needs and
> checks the connection against those itself, instead of asking Wine's store.
> `libgnutls30` only provides the encryption, which the mod cannot ship itself.
>
> If you are on **v0.5.1 or older**, the store did matter, and no amount of
> fiddling with it reliably fixed this. Update rather than chase it.

**Confirming it before you install anything.** Wine prints its own warning at
startup:

```
err:winediag:secur32 ... no support for encryption
```

Or start the server once with Wine's debug channels:

```bash
WINEDEBUG=+secur32,+winhttp wine SCUMServer.exe
```

Since v0.5.2 the mod also names the cause itself. A missing TLS backend logs:

```
[SCUM-RCON] license transport: send failed (WinHTTP error 12157) - TLS handshake failed …
```

| Code | Meaning | Wine-specific? |
|---|---|---|
| `12157` | secure channel error | **yes** — the usual "no TLS backend" code |
| `12175` | secure failure | **yes** — same class |
| `12045` | certificate authority invalid | **yes** — same class |
| `12007` | DNS could not resolve the host | no |
| `12029` | connection refused or blocked | no |
| `12002` | timed out | no |

The first three all mean "TLS never came up" — install `libgnutls30`. The last
three are ordinary network problems and have nothing to do with Wine.

The mod needs outbound HTTPS to **`up.skrypt.gg`** (licence check) and
**`api.ipify.org`** (public-IP detection, so the licence is filed under the
address the outside world sees). If your egress is filtered, allow both. The
public-IP call is best-effort — if it fails, the licence still provisions from
the address the server connects with.

---

## Verify it loaded

After restarting the server with the override set, check the UE4SS log:

```
…/Win64/ue4ss/UE4SS.log
```

You should see SCUM-RCON come up, e.g.:

```
[SCUM-RCON] init - v0.5.2
[SCUM-RCON] license VALID (community) - payload verified
[SCUM-RCON] SCUM-RCON ready - listening on 0.0.0.0:<port>
```

The middle line is the one worth checking: it means the licence check got
through, which on Linux is the step that fails first when something is wrong.

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
- **`license server unreachable` although the container has internet** → Wine has
  no TLS backend. See *A TLS backend for Wine* above; `curl` succeeding does not
  rule this out.
- **`certificate check REJECTED`** → the connection was intercepted, or you are
  behind a proxy that re-signs TLS. The mod validates the licence server against
  authorities it carries itself and refuses anything else on purpose. A
  TLS-inspecting proxy cannot be made to work here; exempt `up.skrypt.gg` from
  it.
- **`this SCUM-RCON version is no longer accepted`** → your build was retired.
  Your licence is still valid — install the current release and it works again.
  Nothing to un-revoke, nothing to ask for.
- **Everything works, then stops after a while** → check whether your public IP
  changed (common on Cloudflare WARP or a dynamic address). The mod re-registers
  itself automatically; if it does not come back, send the `[SCUM-RCON]` lines.

