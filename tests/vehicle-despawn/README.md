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
| Owner leaves a Spawn Menu vehicle over 50 m inside base or 1500 m outside | One ABANDONED record; owner distance, threshold and base result present. |
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

Packing also emits PACKED after the server verifies the hidden representation;
this is an intentional disappearance rather than destruction. Unpacking resets
that transition marker so a later pack receives its own entry.
