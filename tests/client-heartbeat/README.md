# Client heartbeat validation

Run `node tests/client-heartbeat/validate_source.cjs` from the repository root.
This checks source structure, recovery integration, diagnostic fields, and the
ordering of confirmation, counter updates, and UI suspension.

In a disposable multiplayer test mission, copy `validate_engine.sqf` into the
mission and run it on a player client after mission time 120. It extracts and
executes the production decision and recovery code, omitting the final RPC/UI
section so the harness can assert kick decisions without ending the session.
It restores the heartbeat, pending failure, and kick counter afterward. Expect
`QS HEARTBEAT TEST failures=0 details=[]` in the client RPT. Engine execution is
required to verify SQF semantics.

Perform these additional checks with the complete mission on a test server.

| Scenario | Expected result |
| --- | --- |
| Startup before mission time 120 | No report or debriefing, pending failure cleared |
| Join in progress and respawn | Healthy client continues, pending state starts empty at client initialization |
| Temporary client loop stall | One suspected-stall diagnostic, recovery clears pending state, no debriefing |
| Persistent client loop stall | Confirmation at a later invalid check at least 60 real seconds after suspicion, one server report and existing debriefing |
| Two clients, one stalled | Only the stalled client accumulates pending failure |
| Shooting range | Compare affected weapon and magazine firing into ground versus targets, record onset and kick times, collect client and server RPTs |

For a controlled stall, use a disposable mission build to pause the main client
loop while leaving heartbeat RPCs running. Server checks remain roughly 60
mission seconds apart. Never simulate recovery with an independent heartbeat
writer during normal operation, since that would conceal a stalled client loop.

Search client logs for `QS HEARTBEAT suspected stall`, `QS HEARTBEAT recovered`,
and `QS HEARTBEAT confirmed stall`. Diagnostics include timestamps, signed age,
grace elapsed, FPS, script counts, weapon, magazine, and range membership. On
confirmation, the dedicated server receives the existing
`Main game thread terminated` event. The mitigation adds at least 60 real seconds
after initial suspicion, with polling and scheduling affecting the total delay.
