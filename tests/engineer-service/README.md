# Engineer repair/refuel protocol validation

Run `node tests/engineer-service/validate_source.cjs`. The older engineer-repair
and engineer-refuel source entry points also run this shared check. It validates
registration, protocol boundaries and delimiter balance, not SQF execution.

Ownership is resolved only on the server: `owner` returns zero on clients.
Clients send controls to server ID 2; the server authenticates the player and
remembers the vehicle's owner for that session. Workers accept server controls,
and the server validates worker replies before forwarding them to the player.
Source checks reject client/worker uses of the server-only `owner` command.

## Dedicated-server execution

Copy validate_engine.sqf into `tests/engineer-service/` in a disposable copy of
the mission before packaging it. Use an Engineer with a toolkit for repair.
Prepare a stationary vehicle with at least 15% damage or missing
fuel, then point at it and run locally:

```sqf
['repair',cursorObject] execVM 'tests\engineer-service\validate_engine.sqf';
// Or, on another prepared vehicle:
['refuel',cursorObject] execVM 'tests\engineer-service\validate_engine.sqf';
```

The script exercises the real RPC handshake, waits for running, checks actual
work, cancels, checks retained/stable progress, and resumes to completion. It
changes the selected vehicle. Use an undamaged fuel tank for the fuel-retention
check; normal leakage would invalidate that assertion. Keep the engine off for
the automated fuel-retention check so normal consumption cannot affect it.
Allow up to five minutes.
Look for `[QS ENGINEER TEST] PASS` and `completion=true` in the client RPT.

Repeat with a server-owned vehicle and one owned by another player. Also test:

- Cancel during Requesting, including delayed acceptance. No work may happen
  without the client's ready message. Retry immediately after cleanup.
- Two engineers start the same vehicle: one accepted, one explicit busy reply.
- Start either action with the engine running, and toggle the engine during
  service: work continues while stationary. Normal fuel consumption still applies.
- Remove toolkit/role, move away, move the vehicle or hit it: a reason is
  returned and progress retained. Rejection must not claim work was saved.
- Disconnect the engineer or vehicle-owning client, or transfer locality: lock
  cleanup/expiry permits a new session; client does not hang on old progress.
- Stop client heartbeats in an instrumented disposable session: owner expires
  after eight seconds without a heartbeat. It must stop applying updates.
- Deliver an old response after restarting: session/sender checks ignore it.
- Full repair leaves fuel unchanged; full refuel leaves damage/ammo unchanged.
- Very slight damage and nearly full fuel: completion is owner-confirmed, with
  no progress-timer cancellation. Verify service pads still work independently.

Client, server and owner log `[QS ENGINEER]` at request/route/accept/reject/stop/finish,
including session identity, owner or reason. A client request must show `target=2`;
the server's route entry must name a target of 2 or higher, never 0. If the owner
stops replying, its server route expires after 12 seconds. Do not infer success
from static checks. Capture the client and server RPTs, plus the vehicle-owning
client's RPT if applicable, when a dedicated-server run fails. No per-tick logging.
