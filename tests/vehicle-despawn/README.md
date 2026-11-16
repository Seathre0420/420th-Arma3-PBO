# Vehicle despawn diagnostics

Run `node tests/vehicle-despawn/validate_source.cjs` and
`node Apex_framework.terrain/tests/validate-server-performance.cjs`.

The server RPT records `[VEHICLE DESPAWN]` after actual deletion, normally within
2.5 seconds. `trace` identifies the removal, `reason` and `source` identify the
decision, and `detail` contains branch-specific facts. UNKNOWN means the global
deletion observer saw removal without matching mission provenance.

Snapshot fields, in order: mission server time, class, network ID, machine owner,
world position, alive, damage, Spawn Menu owner UID, owner name, horizontal owner
distance (-1 if unresolved), occupied crew seats, attached parent network ID,
deployed, packed, simple object, editor variable name. Crew entries contain role,
cargo index, turret path, network ID, name, UID. Capture is immediately before the
instrumented command; for unknown deletions it is at the deletion event.

Client provenance is best effort: it must match an actual server-observed
deletion, the observed machine owner and a short time window. Delayed or rejected
reports leave UNKNOWN rather than creating a fictitious removal. Purely local
client helpers have no server entity and are excluded. Simple vehicle proxies
are covered at instrumented deletion sites if their class or QS_vehicle marker
identifies them; external deletion of an unmarked simple object has no engine
fallback event. Actual removals are not sampled or rate limited. Only unmatched
client provenance is capped (4096 entries) and expires after ten seconds.

On a dedicated multiplayer server verify:

| Case | Expected |
| --- | --- |
| Vehicle stays inside BASE_HIGHSEC_0 while its spawning player remains outside that zone for more than 60 seconds | One ABANDONED record on the next eligible vehicle-manager pass; base result, owner absence duration and 60-second timeout present. Distance from the owner does not matter. |
| Owner stays inside base, even more than 100 m from their vehicle | Vehicle retained regardless of owner distance. |
| Owner returns to base before cleanup, then leaves again | Absence timer resets; the next absence must exceed a fresh 60 seconds. |
| Vehicle is outside BASE_HIGHSEC_0 | Owner must be more than 3000 m away; no base absence timeout applies. |
| Owner meets the absence/distance condition while a living player occupies any seat | Vehicle retained with no ABANDONED record; after the last living player exits, the next eligible pass produces exactly one ABANDONED record even if AI remains. Include an incapacitated living player. |
| Only AI occupies a Spawn Menu vehicle whose owner meets the absence/distance condition | Eligible for abandonment cleanup, including friendly AI. |
| Vehicle is attached, deployed or packed while its owner is outside base | Vehicle retained; owner absence still tracked, including resetting on return to base. Once protection ends, cleanup may occur on the next eligible pass if absence already exceeds 60 seconds. |
| Old Black Wasp wreck is removed while its owner pilots a replacement | WRECK_CLEANUP for the old network ID; replacement retained with no ABANDONED record. |
| Owner occupies vehicle removed in infantry protection zone | One SPAWN_PROTECTION record with driver/pilot seat; same existing chat warning and timing. |
| Manual Despawn, staff deletion, Zeus deletion | One removal record; uninstrumented Zeus deletion may be UNKNOWN. |
| Owner disconnects; role changes remove UAV | DISCONNECT / UAV_CLEANUP respectively. |
| Destroy vehicle; garbage collector removes wreck | One entry at removal, not at destruction; dead state retained. |
| Mission ends, insertion retires, batch/array deletion | One record for each vehicle, not for infantry/projectiles/props. |
| Vehicle changes locality before deletion | One server record; validate both client-owned and server-owned cases. |
| Managed proxy retires, wreck recovers, cargo is virtualized | REPLACED/REMOVED record for old object; replacement remains usable. |
| Invoke CONTEXT without deleting | No removal entry. |
| Initialize logger twice | One observer and one flush worker. |
| Batch cleanup under load | No missing/duplicate events; measure frame times and RPT growth. |

No Arma engine runtime is simulated by the source checks.

Owner base membership is sampled by the existing vehicle manager, normally every
15 seconds. The timeout starts at the first observed absence and cleanup requires
more than 60 seconds since that observation. A return observed on a pass clears
the timer. A return and departure entirely between passes cannot be detected.
The timer is local to the server's player object, so a replacement player object
(for example on respawn) starts a fresh observation interval. UAVs retain their
existing exemption from this abandonment rule.

Packing also emits PACKED after the server verifies the hidden representation;
this is an intentional disappearance rather than destruction. Unpacking resets
that transition marker so a later pack receives its own entry.

Garbage-collector metadata regression: the source validator exercises the captured
instruction/deadline expressions with mixed entries, successful recycling, an
object disappearing before deletion, and consecutive passes. It also pins the
cleanup commands and conditions independently of Git HEAD. These checks do not
execute the Arma engine.

On a dedicated test server, queue disposable vehicles with NOW_FORCED,
NOW_DISCREET, DELAYED_FORCED and DELAYED_DISCREET, using distinct deadlines.
Verify existing timing and player-proximity conditions, one GARBAGE_COLLECTION
record per deletion, matching instruction/deadline fields, and no undefined
_QS_instructions or _QS_timeDelete errors. Mix entries in one pass, include
a successfully recycled object and an object removed before the deletion pass,
and repeat in a later pass to check that metadata never shifts or carries over.
