# Engineer Refuel validation

Run `node tests/engineer-refuel/validate_source.cjs` from the repository root.
This checks source integration, delimiters and timing contracts; it is not an
SQF interpreter or an Arma multiplayer test.

In a disposable mission, use an engineer without a toolkit or nearby fuel source:

1. Look at a stationary engine-off car, tracked vehicle, helicopter and boat.
   Refuel should appear within five metres of its bounding box when fuel < 1.
   Look at terrain, infantry, props, a destroyed vehicle or a full tank: hide it.
   Non-engineers and mounted/incapacitated players must not receive the action.
2. Set fuel to 0, .25, .5 and .9 with no fuel leak. Start Refuel and check that
   fuel rises gradually to exactly 1 in approximately 100, 75, 50 and 10 seconds.
   Frame scheduling and network latency can add time. Damage/ammo must not change.
3. Cancel early, halfway and near completion. Fuel must stay at the current value.
   Resume with the same or another engineer: only missing fuel should take time.
4. Look at a second vehicle after starting: the original target must continue
   receiving fuel, and Cancel Refuel must remain available. The second vehicle's
   fuel must remain unchanged. Confirm percentage and seconds remaining display.
5. Walk away, mount a vehicle, change role, become incapacitated, start/move the
   target, or shoot it: stop fueling and keep added fuel. Destroying it must not
   revive it. Check vehicle/mission QS_services_refuel_disabled and enemy occupants.
6. While fueling, attempt Repair; while repairing, attempt Refuel. One player
   must never run both. Existing toolkit repairs must never add fuel.
7. On a dedicated server with two clients, test server-owned empty vehicles and
   vehicles owned by the other client. Simultaneous fueling requests must admit
   only one refueler. Cancel or disconnect the active player, then retry. Change
   ownership mid-session: fueling must stop and a new session must be possible.
8. Use a service provider or debug console to change fuel during fueling.
   Subsequent increments must use the new current fuel, never an initial snapshot.
   A leaking tank may take longer or fail to fill until repaired; normal leakage
   must not be overwritten. Verify normal service-provider refueling still works.
9. Respawn and repeat; confirm one Refuel action and no orphan Cancel Refuel action.
   Check client and server RPT logs for errors throughout these tests.
