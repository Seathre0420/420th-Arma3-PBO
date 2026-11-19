# Classic AO damage protection validation

Run the offline structural and integration checks from the repository root:

```powershell
node tests/ao-damage-protection/validate_source.cjs
node Apex_framework.terrain/tests/validate-server-performance.cjs
```

These checks do not execute Arma. For engine assertions, create an isolated empty
test mission, copy `fn_aoDamageProtection.sqf`, `fn_aoDamageArrival.sqf` and
`fn_aoDamageReleasePending.sqf` into its `code/functions/` folder,
and copy `validate_engine.sqf` into its root. Run
`[] execVM "validate_engine.sqf"` on the server. Read `[AO damage test]` results
in the RPT; the final line must report zero failures. Never run this harness in
a live mission: it replaces test state and creates/deletes test entities.

The harness exercises initial infantry, armor, crews, statics, reinforcements,
each AA exception, aircraft/operators, commander/tower exclusions, delayed
damage callbacks, permanent unlock, epoch reset, stale callbacks, Defend
isolation and recycler isolation against the actual controller.

On a disposable multiplayer copy of the full Classic mission, also verify:

1. With every player over 2,000 m from `QS_AOpos`, shoot ordinary AO infantry,
   armor, and static weapons; they take no damage. Tigris/Nyx hulls and aircraft
   retain their normal damage behavior. Existing AA crew protection is retained.
2. A vehicle occupant, pilot, parachutist, dead player or spectator within the
   radius does not unlock the AO. A living player dismounted on the ground at
   2,000 m or closer unlocks it within roughly two monitor ticks. Test 2,001 m
   separately. Prone/crouched players and players standing in buildings qualify.
   Exercise this through the normal client loop on a dedicated server. Repeat
   with a player already inside the radius at AO start and a player joining
   during the lock. Inspect `QS_classicDamage_arrival` on the server while locked.
   Its fields are epoch, player, server receive time, player owner, and distance.
   Spectator/Zeus camera use must not submit arrival reports. Also verify that
   stale-epoch reports and reports naming another player's unit are rejected.
   Verify that a player boarding or leaving after the first accepted report
   still unlocks the AO, even after a delayed tick or a monitor restart.
3. After unlocking, leave the radius and board a vehicle: the AO stays unlocked.
   Check both native reinforcements and Altis pressure-controller deliveries;
   transported infantry are protected before unlock, aircraft operators are not.
4. Check the commander's and radio tower's existing 50 m ground-element rules
   before and after the AO unlock. Their damage handlers must remain intact.
5. Before unlocking, transfer an ordinary AO group to a headless client or Zeus,
   then back to the server. Shoot it on each owner; protection must persist.
   Join another client during the lock and repeat. Unlock and confirm damage
   works on the current owner and after another transfer.
6. Cycle/pause a locked AO and force/queue Defend. Old forces must be released;
   Defend forces follow their existing rules. The next Classic AO starts locked.
   Repeat with AI recycling enabled and inspect the RPT for script errors.
7. Arrive while initial forces are still spawning. Shoot infantry, armor, tower
   HMGs and their gunners, then repeat after ownership transfers. Spawn tower
   weapons on both sides of the unlock, including after a player was already
   inside at AO start. Walls remain protected and HMGs become vulnerable.
   Deliver an old `LOCAL` callback after release, and an old `RELEASE` callback
   after the next AO begins. Neither may restore immunity or release a newer AO.
8. Transfer a group during release. The server should retry on the new owner
   and record the verified count by owner in the `[AO damage] RELEASE_COMPLETE`
   RPT entry. Check separately that an unconfirmed release produces an unresolved
   count and samples. While the AO remains locked, run
   `['DIAGNOSE'] call QS_fnc_aoDamageProtection` locally on the server to log the
   arrival record and nearby players' distances and vehicle states.

Use gunfire/explosions to test invulnerability. Engine `setDamage` deliberately
bypasses `allowDamage`, so scripted damage is not a valid combat test.
