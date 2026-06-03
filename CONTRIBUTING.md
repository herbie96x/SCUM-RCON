# Contributing to SCUM-RCON

Thanks for your interest! SCUM-RCON is **free for everyone to use**, and contributions that make it better for the community are very welcome — within some clear boundaries.

## What's welcome 👍

- **Bug reports & feature requests** — open an issue.
- **RCON clients, panels, Discord bots, wrappers** — anything that talks to SCUM-RCON over the Source RCON protocol. Build your own tooling in any language; the protocol is the contract.
- **Documentation** — improvements to the README, USAGE.md, examples, install guides, command lists, translations.
- **Pull requests** for the above — fork the repo and open a PR. For most contributions that's all you need.

## What's NOT open ✋

SCUM-RCON is **closed-source under a free-to-use EULA** (see `LICENSE`). That's a deliberate, permanent decision:

- The core mod (the DLL and its source) is **not** published and won't be — it's built on a lot of reverse-engineering work and contains reverse-engineered internals of `SCUMServer.exe` that I won't publish, out of respect for Gamepires and for the obvious IP reasons.
- Please **don't** reverse-engineer, decompile, or redistribute the DLL, and please don't ask for the source or the "how" of the mechanisms. The answer is a friendly but firm no.

In short: the **what** (working commands, a stable RCON interface) is open to build on. The **how** stays closed.

## Want to collaborate more closely? 🤝

If you'd like to actively help — build a maintained client, a panel, write docs, run tests, or help triage issues — open a **Collaboration request** issue. Tell me what you'd like to work on and what you bring.

Depending on the scope, that stays on the fork-and-PR flow, or — for trusted, ongoing contributors — can mean **triage access** up to **write access** for proven co-maintainers. Either way, collaboration always happens **on top of** the RCON API, never inside the closed core.

## License

By contributing, you agree your contribution is provided under the project's EULA (`LICENSE`). The bundled UE4SS keeps its own MIT license.
