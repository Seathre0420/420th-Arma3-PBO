# Protected cargo unloading

Run `node tests/cargo-unload/validate_source.cjs` from the repository root.
Use Arma Tools CfgConvert `-test Apex_framework.terrain/description.ext` to
validate function/RPC registrations with the mission configuration. These are
structural checks, not a simulation or multiplayer test.

All client-originated cargo RPCs enter through the server before owner routing.
Arma's `owner` command returns 0 on clients, so authenticating a direct client
RPC at the cargo owner rejects legitimate requests. The 2026-10-31 12:45:52 client
RPT records this as `sender=4 actorOwner=0` for GUI PLACE requests. The same route
was used by ATTACH, preventing a second Carry once cargo became client-local.
Carry, GUI confirmation, onboard unloading and fallback ground unloading now
use server routing. Direct local placement/completion calls remain local.
The structural validator checks client cargo RPC destinations across functions.

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

Protected carry loads share the owner worker, including legacy hidden storage
at `[0,0,-100]`. Their token and next revision are required for LOAD. Loading marks placement as
committing after confirmation; delayed cancellation is ignored during settling,
and the watchdog finishes transfers instead of releasing them again. Custom attachments count as
successful loads as well as native vehicle cargo. Failed capacity/lock checks
on the owner recover the cargo safely. The client reports physical load success
only after protection clears and the destination still contains the cargo.

The loading exception for disabled simulation applies only to the requesting
player's active, idle carry token, with originally enabled simulation and normal
logistics eligibility, including configured cargo classes, static weapons and
native-compatible cargo without a pre-existing `QS_logistics` flag. Successful
physical loads register that flag for subsequent unloading. The physical and
virtual volume helpers keep their cargo arrays private so capacity checks cannot
overwrite the worker's cargo object reference. Other movement restrictions still apply. Intentionally
disabled cargo is not made loadable by this exception.

## Multiplayer acceptance checks (not executed)

Carry placement now retains its player lease until owner confirmation. The
client pauses placement drawing while the request is pending. State field 8 is
`CARRY`, `PLACE`, `LOAD` or `RECOVER`; field 10 is the attempt revision and field
11 holds the last carry attachment/relative orientation for a rejected placement.
FINISH includes the revision; old completions cannot finish a newer retry.
`QS_cargoMove_result` records `[token,revision,outcome]` for client confirmation.
Successful placement keeps the requested position before physics resumes.
Owner-side world edge tests and original-carrier separation checks can reject a
placement; rejection returns a living player's object to carrying rather than
searching for another position. Genuine interruptions retain safe recovery.
The watchdog measures abandoned lease grace on the server, allowing five seconds
for replication. Carry checks existing protection before showing its progress bar.
Failed request confirmation is logged with token/revision/result in the RPT.

Physical loading and placement now share the confirmation path. Local cargo
requests and their FINISH callback execute on the owner directly; non-local
requests enter through the server for sender validation and routing. Rejected
authenticated requests return REJECTED and log the owner/token/revision/state,
rather than leaving the client waiting for an obstruction result. BLOCKED is
reserved for a failed placement check. Loading retains the carry UI until a
LOADED result; rejected loads resume adjustment. Cancellation and incapacitation
can interrupt a pending UI request. Escape now cancels protected carrying as well
as previews. Old local rejection replies are cleared before retries, and the
watchdog retries completion/recovery for operations busy for five seconds.
No dedicated-server reproduction has been
run for these changes; the remaining timeout diagnostic is needed if a request
fails before it reaches the worker.

Additional manual acceptance sequences (not executed):

- Repeat Carry -> place -> Carry at least ten times with the same object and
  another player. Each completed placement clears state, busy flag and lease.
- Carry longer than five seconds, then release at the displayed location using
  both Release and placement confirmation. No scripted relocation should occur.
- Reject a blocked placement, adjust the still-carried object, then retry. A
  delayed completion/cancellation from the first attempt must not affect retry.
- Delay requests, duplicate confirmation, change owner during settling, and
  interrupt with death/disconnect. No permanent busy/frozen state should remain
  once safe recovery is possible; original simulation/damage flags are retained.
- Load native, custom and virtual cargo after carrying, then unload and carry
  again. Retain the existing loading checks below.

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
| Carry, then load using the action menu and placement confirmation | Both routes accept the temporary freeze; original flags and carry lease clear after success. |
| Legacy hidden storage, native cargo, and custom attachment points | Cargo remains at its destination beyond 10 seconds; placement cleanup and watchdog do not unload it. |
| Successful load, unload to ground, reload with the same and a second player | Restored cargo has a Load action and can be loaded again. |
| Destination becomes full/locked after client validation | Owner rejects transfer, safely recovers cargo, and the client reports failure. |
| Duplicate LOAD, delayed cancellation, old LOAD token after completion | No repeated release or new protection state; settled cargo remains loaded. |
| Configured cargo/static weapon without QS_logistics, carried into a compatible native/custom/hidden destination | Load succeeds, QS_logistics becomes true after physical loading, and cargo appears in the unload menu. |
| Hidden load into an empty carrier and one with existing physical/virtual cargo | Capacity checks retain the worker's object reference; no Array/Object script errors, and protection clears after success. |
| Originally simulation-disabled cargo or cargo outside all supported eligibility routes | The temporary-freeze exception does not bypass normal loading restrictions. |
| Carry and serialize virtual cargo, then unload it again | Serialized simulation/damage reflects the original flags, not the temporary freeze. |
| Ammo crate/static weapon unloaded and immediately reloaded | A delayed old unload callback does not enable damage on loaded cargo. |
| Native aircraft paradrop, simple objects, incapacitated units | Existing behavior remains functional. |

Also verify UI placement, rotation and height adjustment while simulation is
disabled, and that nearby players can still interact with restored cargo.
