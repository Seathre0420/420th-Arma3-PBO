# Defend rotation validation

Run `node tests/defend-rotation/validate_source.cjs` for source integration checks.
The engine harness compiles the marked production blocks from `fn_core.sqf`;
it checks rotation sequences and overrides without spawning combat units.
Run `validate_engine.sqf` server-locally in a standalone editor mission with
the repository's `Apex_framework.terrain` folder available. Expect
`[Defend rotation test] COMPLETE failures=0` and no script errors in the RPT.
The harness refuses an initialized framework and restores its namespace inputs.

On an Arma test server, verify:

- Complete an eligible AO and let Defend start. Finish or fail that Defend.
  Complete the next AO: no automatic Defend; HQ remnants clean up normally.
- Complete another AO: normal Defend entry checks apply again.
- During a blocked AO, separately test Queue Defend, Force Defend and Mega
  Defense. Each should start and block automatic Defend after the next AO.
- A rejected Defend attempt or cancelled Mega Defense request must not block
  the next AO. A cycled AO or AO with Defend disabled consumes the intervening AO.
- Pause/resume without selecting another AO must not advance rotation history.
- Restart the mission: the first AO has no inherited restriction.

## Server RPT diagnostics

Filter the server RPT for `[Defend]`. These transition logs are always enabled:

| Event | Meaning |
| --- | --- |
| `INIT schema=1` | Confirms this logging version is loaded; records initial counter, restriction and force value. |
| `AO_START` | Identifies the new and previous AO, epoch, counter baseline before it changes, current counter and resulting restriction. |
| `DECISION` | Records counter/baseline, restriction, AO eligibility, force, staff/Mega requests and whether the core launches an attempt. `launch=true` does not yet mean Defend started. |
| `STAFF_REQUEST` | An authorized 420th Staff Menu queue/force request was accepted, with staff name/UID and target epoch. |
| `STAFF_HANDOFF` | The core consumed that request for the current AO. |
| `STAFF_CANCEL` | Cycle/pause cleared a pending request; includes original staff metadata and cancelling staff identity. |
| `FORCE_CHANGE` | Records observed force changes and explicit staff handoff, pause, one-shot consumption or disable reset. |
| `SKIP` | Entry rejected the attempt; includes reason, relevant measurement, counter, restriction and raw/effective force values. |
| `START` | Entry passed and incremented the counter; includes before/after counts, restriction, raw/effective/remaining force values, FPS, nearby units, existing random roll and initiation source. |

`source` is `AUTOMATIC`, `FORCE_SETTING`, `STAFF_QUEUE`, `STAFF_FORCE`, or
`MEGA_DEFENSE`; `STAFF_REQUEST` is a fallback when a staff-start flag lacks menu
metadata. Staff metadata arrays contain `[action, name, UID, requestedEpoch]`
and are cleared on cancellation/consumption. The AO baseline in START/SKIP is
the counter at that AO's start; `baselineBefore` in AO_START belongs to the
preceding AO. The counter increments only at actual admission, including for
Defends that subsequently fail.

External force changes are sampled by the existing three-second core loop;
changes that occur and revert between samples may not be observed. Known
force writes in the staff/core/Defend paths log their transitions immediately.
No unchanged-tick messages, additional random draws or extra unit censuses are
introduced. Persistent force `2` remains an override and appears in DECISION
and START even when unchanged.

Check these RPT sequences on an Arma test server:

- Normal start: DECISION `launch=true`, then START with count incremented by one.
- Restricted AO: DECISION `launch=false reason=PREVIOUS_AO_DEFEND`, no START.
- Queue/force: STAFF_REQUEST, STAFF_HANDOFF, then START with the matching staff
  metadata, AO epoch and STAFF_QUEUE/STAFF_FORCE source.
- Queue then cycle/pause: STAFF_CANCEL, no stale identity on a later automatic
  START. A pause that sets force to -1 also records STAFF_PAUSE.
- Rejected entry: SKIP with the applicable reason and no counter increment.
- Force 1: ONE_SHOT_CONSUMED and START with `forceAfter=0`; force -1:
  DISABLE_RESET and SKIP; force -2: SKIP without resetting the setting.
- Force 2: repeated START events show `source=FORCE_SETTING`, `rawForce=2`
  and `forceAfter=2`. Unchanged ticks add no FORCE_CHANGE messages.
- Mega Defense: START identifies MEGA_DEFENSE and distinguishes the raw force
  setting from its effective force of 1.
