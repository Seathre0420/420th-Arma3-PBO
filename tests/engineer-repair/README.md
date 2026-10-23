# Engineer repair validation

Run `node tests/engineer-repair/validate_source.cjs` from the repository root.
This runs the shared source integration checks, not SQF execution.
See [shared service validation](../engineer-service/README.md) for the dedicated-server
test script, handshake checks, and diagnostic log instructions.

In a disposable Arma mission with an engineer player carrying a toolkit:

1. Damage a stationary, engine-off vehicle to 5%, 25%, 50%, and 90%.
   Repair times should be approximately 3, 30, 85, and 205 seconds (scheduler
   and network latency can add time). Confirm individual damage values fall
   gradually and all damage is zero on completion.
2. Test a single destroyed wheel, track, engine, main rotor and tail rotor,
   with otherwise undamaged components. Pristine components must stay pristine;
   destroyed components must repair gradually. Test hull-only damage too.
3. Cancel early, halfway and just before completion. Record overall and hitpoint
   damage before/after cancellation. Restart, or have another engineer continue.
   Progress must persist and repeated cancellation must not accelerate repair.
4. Test tanks at fuel 0, 0.4 and 1, with the engine off and no leaking tank.
   Compare `fuel vehicle` before start, after cancellation and after completion:
   it must remain unchanged. Repeat with a damaged fuel tank; normal leakage is
   allowed, but repair must never add fuel or restore a saved fuel amount.
5. Walk away, enter a vehicle, remove the toolkit, change role, become
   incapacitated, start the vehicle engine, move it, or shoot the vehicle.
   Each must stop repairs and retain applied work. Destroying it must not revive it.
6. Verify slight component damage still offers the custom Repair vehicle action.
   Check non-engineers, missing toolkits, enemy occupants and QS_RD_noRepair.
7. On a dedicated server with two clients, repair server-owned empty vehicles
   and vehicles owned by the other client. Simultaneous starts must admit one
   repairer. Cancel/disconnect that repairer and retry. Change vehicle ownership
   mid-repair: the session must stop cleanly, then allow a new repair session.
8. Check RPT logs for script errors, respawn and retry, and verify service-pad
   repair/refuel/rearm still works independently.
