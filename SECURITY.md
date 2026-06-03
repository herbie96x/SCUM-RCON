# Security Policy

SCUM-RCON runs with **full admin rights** on game servers and opens a network listener (Source RCON). If you find a security issue, please help keep server operators safe by reporting it **privately** — not in a public issue.

## Reporting a vulnerability

**Please don't open a public GitHub issue for security problems.** Instead:

- Message me on **Discord**: https://discord.gg/HhSraTKfrW (DM `herbie96x`), or
- use GitHub's **private vulnerability reporting** (the repo's *Security* tab → *Report a vulnerability*).

Please include:
- What the issue is and how to reproduce it
- The SCUM-RCON version affected
- The potential impact (e.g. unauthorized command execution, information disclosure)

I'll acknowledge as quickly as I can, work on a fix, and credit you in the release notes if you'd like.

## Scope

**In scope:** the SCUM-RCON listener, command dispatch, auth handling — anything that could let an unauthorized party run commands or read data they shouldn't.

**Out of scope:** issues that require an attacker to already know your RCON password and general SCUM/Gamepires engine bugs unrelated to this mod.

## Operator hygiene

- Always set a strong RCON password in `config.ini`.
- Never expose the RCON port to the open internet without **strong** password — Source RCON is unencrypted by design.
