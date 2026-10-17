# Defend assault validation

Defend and Mega Defend share `fn_defendAssault.sqf`. Only explicitly registered
assault infantry participate: ordinary spawns, both parachute waves, helicopter
parajumpers, Taru cargo, ground-transport passengers, and vehicle-paradrop cargo.
Pilots, drivers and combat-vehicle crews retain their existing tasks.

Before reaching 100 m horizontally from HQ, soldiers keep targeting, automatic
combat, cover and suppression reactions disabled, never-fire mode, standing
stance, full movement speed, and zero fleeing. Navigation stays enabled. Each
soldier permanently unlocks targeting/fire and normal combat reactions upon
entering the radius on the ground. Squads retain HQ as their objective and do
not receive flank, regroup, demolition/repair, or covering-fire diversions.
Unlocked soldiers retain the normal unit-handler rearm, heal and support work.

One server worker checks the bounded roster every second and batches commands
by the current unit owner. The server executes its own batch directly. HCs
receive one remote call per occupied owner per tick; no per-unit workers or
world scans are added. Movement is ordered on landing/initialization, then
retried only for stalled/lost orders, with an eight-second minimum interval.
Boundary polls do not themselves reset paths. The legacy `QS_defend_propulsion`
setting is superseded for defense infantry. Spawns, caps and defense timers are
unchanged. Closing defense cancels the worker and restores saved AI settings
before the existing cleanup deletes the roster.

Run offline integration checks:

```powershell
node tests/defend-assault/validate_source.cjs
node tests/ao-damage-protection/validate_source.cjs
python tests/phase-1/validate_scope.py
```

For automatic engine assertions, copy the controller and `validate_engine.sqf`
into a disposable mission and execute the harness on the server via `execVM`.
Run in scheduled execution; VR suffices. The harness refuses an active defense,
creates its own units, tests the boundary, split squads, landing, passengers,
retry pacing, stale epochs and cleanup, and removes its test entities. Inspect
`[Defend assault test] COMPLETE failures=0` and check the RPT for script errors.
This harness simulates owner reinitialization; it does not replace real HC tests.

Before deployment, verify these multiplayer cases in both Defend and Mega Defend:

1. Fire near and wound attackers outside 100 m: they keep advancing without
   firing. Outside infantry must also stay locked when their leader is inside.
2. Run units across 101/100/99 m. Each unlocks independently at <=100 m and keeps
   combat enabled if pushed back outside. Observe actual rifle/launcher fire.
3. Kill the leader during the approach. The remaining soldiers keep moving to
   HQ without waiting for a regroup or following targets away from HQ.
4. Exercise both parachute waves, helicopter jumpers, Taru parachute/rappel
   delivery, ground transports and vehicle-paradrop cargo. No ground orders
   interrupt descent/transport; dismounted troops adopt the same distance gate.
5. Transfer a mixed locked/unlocked squad server -> HC -> server, disconnect the
   HC, and connect a new HC during defense. Unlocks persist, locked men remain
   locked, and only the current owner issues commands. Check the RPT for errors.
6. Block an approach near buildings. Orders retry without teleportation or
   per-second destination resets. Ensure the AI still navigate around obstacles.
7. Cancel/end defense during an insertion and start another defense. No old
   worker, tick, or delivery callback may change the new activity or reused AI.
8. Compare equal-population/AI-count runs: server/HC FPS, controller execution
   time and traffic, and progress into HQ. Actual combat and pathfinding cost
   must be measured in engine; offline checks cannot establish an FPS gain.
