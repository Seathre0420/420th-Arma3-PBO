# Protected cargo unloading

Run `node tests/cargo-unload/validate_source.cjs` from the repository root.
Use Arma Tools CfgConvert `-test Apex_framework.terrain/description.ext` to
validate function/RPC registrations with the mission configuration. These are
structural checks, not a simulation or multiplayer test.

The owner worker freezes simulation and damage before releasing real cargo,
reapplies protection after synchronous cargo callbacks, and moves/attaches it
without yielding. Ground placement settles for two frames before restoring the
saved flags. Carried objects retain their flags in a replicated snapshot. A
server watchdog checks abandoned carry leases every 0.25 seconds and attempts
recovery after five seconds. A failed/overlapping placement returns cargo to
its original carrier, or finds an empty position. If neither is safe, it stays
protected and recovery retries every five seconds, recording `[CARGO MOVE]` in
the RPT. Simulation is never blindly enabled to resolve a failed recovery.

The clearance check projects the cargo bounding box onto its original carrier's
axes. It is conservative and can reject a close placement that would clear the
vehicle's actual geometry. Previously disabled simulation/damage stays disabled.
Ammo crates/static weapons retain their normal protection when reloaded; stale
unload callbacks cannot re-enable their damage while protected or loaded. Virtual
cargo serialization preserves the original flags rather than the temporary
freeze. Simple objects, person transport, and native airborne paradrops keep
their original release paths. Angular-velocity clearing requires Arma 3 2.18+.

## Multiplayer acceptance checks (not executed)

Server execution tests were skipped at the user's request. No successful native
or S.O.G. reproduction/fix verification is claimed.

Use the updated mission in an isolated dedicated multiplayer session with two
clients. Run the following with S.O.G. Prairie Fire both enabled and disabled,
using a vanilla `B_Truck_01_flatbed_F` and both `B_CargoNet_01_ammo_F` and
`CargoNet_01_box_F`. Observe the truck and cargo on both clients and record RPT
script errors, damage, velocity, ownership, and the cargo's
`QS_cargoMove_state`/`QS_cargoMove_busy` variables.

| Scenario | Required result |
| --- | --- |
| Unload to carry, then place on clear ground | No impulse/explosion at release; frozen while carried; original simulation/damage restored after placement; state cleared. |
| Ground placement using a preview | Real cargo remains loaded until confirmation; placement finishes at the chosen pose without an impulse. |
| Direct/fallback unload and onboard ground unload | Same protection and restoration as preview placement. |
| Server-owned cargo; client-owned cargo; ownership changes during settling | Release occurs on the current owner; completion/recovery survives the handoff; no permanently frozen cargo. |
| Enable simulation inside an additional CargoUnloaded handler | Worker reapplies the freeze before returning to the engine physics step. |
| Previously disabled simulation or damage | The disabled flag stays disabled after placement and recovery. |
| Duplicate clicks; stale completion/recovery token | No second release or overwriting the original flags; stale token ignored. |
| Cancel preview | Original cargo stays loaded. |
| Cancel/interrupt carrying; die, respawn or disconnect while carrying | Cargo returns safely to the original carrier or an empty position; freeze state eventually clears when recovery succeeds. |
| Place inside the original HEMTT's bounding box | Placement is rejected/recovered before physics resumes. |
| Move the HEMTT back into cargo during settling | Completion rechecks clearance and recovers instead of enabling physics in an overlap. |
| Carry and load into another vehicle; fail that load | Successful loads retain normal cargo protection; failed loads recover safely. |
| Carry and serialize virtual cargo, then unload it again | Serialized simulation/damage reflects the original flags, not the temporary freeze. |
| Ammo crate/static weapon unloaded and immediately reloaded | A delayed old unload callback does not enable damage on loaded cargo. |
| Native aircraft paradrop, simple objects, incapacitated units | Existing behavior remains functional. |

Also verify UI placement, rotation and height adjustment while simulation is
disabled, and that nearby players can still interact with restored cargo.
