# Unified friendly-fire validation

Run `node tests/friendly-fire/validate_source.cjs` for delimiter/string validation of changed SQF and registration files. This is not an SQF compiler.

Copy these tests into a disposable dedicated multiplayer mission and run `[] execVM "tests\friendly-fire\validate_engine.sqf"` on the server. Require zero failures. It creates and deletes test entities.

The harness checks protection immediately after vehicle creation so the periodic reconciliation cannot hide a broken `EntityCreated` callback. Require no `Type Object, expected Array` errors in the RPT during creation, including client/JIP entity creation.

Then test real weapon damage with two clients and a headless client. Record RPT, overall damage and all hit-point damage before and after each shot. Protected hits must leave all values unchanged and must not incapacitate, punish, damage fuel/rotors or schedule delayed damage.

- Defender missiles, terminal and nearby control: Spawn Menu and editor/script aircraft, occupied and empty, planes and helicopters, inside/outside safe zones.
- Release control, disconnect, delete launcher, change target or transfer locality during flight. Test simultaneous hostile/friendly missiles of the same ammo class.
- Bullets, grenades, artillery, direct/indirect explosions, mines and underwater demolition; deliberate enemy remote control by friendly player.
- Friendly/enemy infantry and UAV crews, empty/occupied land/sea/air vehicles; JIP, respawn, server/client/headless transfers.
- Vehicle impacts, sling-load and secondary fuel explosions; verify enemy/environment damage and ordinary repairs still work.
- Restricted/hidden/owned turret: terminal and nearby action must agree on access.
- Profile automatic fire and reconciliation with mission-scale entity counts.
- Player falls from low, high and extreme heights onto terrain and buildings, outside safe zones, both healthy and already injured. Check the self-source and null-source cases in the harness; real falls must retain the pre-overhaul behavior without random combat injuries. Also verify hostile vehicle impacts and weapon damage still injure players.

Engine tests and physics matrix have NOT been executed by Codex. Deployment acceptance remains pending their results.

## Targeted missile tracking

Missiles are sampled by one worker per firing machine every 0.25 seconds.
Reports go to the server, which validates launch identity and merges records,
then batches deltas only to current target owners. The server retains the same
short-lived records for ownership handoffs. Incoming records retain their
original 0.75-second expiry; no JIP remote-execution queue is used. Projectile
provenance, launcher history, and explosive tracking remain separate.

The engine harness additionally checks concurrent/ambiguous same-ammo merges,
duplicates, stale snapshots, expiry, malformed reports, live-launch admission,
and accepted-launch identity after projectile deletion. These are real SQF
tests, but do not prove network replication or timing under combat load.

With two graphical clients and a headless client, additionally:

1. Fire simultaneous friendly and hostile missiles of the same class at one
   target from different owners; also fire at several targets. Verify incoming
   records retain distinct keys and ambiguous attribution stays unchanged.
2. Transfer the target server -> client -> HC -> server during flight, including
   immediately after launch and impact. Join/reconnect while missiles are live.
   Verify the new owner receives the unexpired snapshot, and a stale snapshot
   cannot overwrite newer records. There is still network delivery latency;
   do not claim an instantaneous handoff without engine evidence.
3. Retarget, delete/release control of the launcher, transfer its ownership,
   disconnect the firing client, and destroy/delete missiles. Accepted launch
   allegiance must not change. No record may protect beyond its original
   deadline without a fresh accepted sample. A disconnected producer stops
   sampling, as with the previous implementation.
4. Attempt APPLY from a nonserver client, REQUEST for another owner's target,
   fabricated REPORT keys/projectiles, altered allegiance, future/expired
   timestamps, malformed rows and oversized batches. None may modify the cache.
5. Compare equal-load baselines at 1, 10 and 30 concurrent targeted missiles:
   public-variable traffic, remote-call counts and recipients, server frame time,
   player ping/desync, and unrelated clients' incoming variables. Unrelated
   clients must receive no incoming-tracking deltas. Confirm only one sampling
   worker per firing machine and that server caches drain after missiles expire.

Batch size is 128; producer/launch and per-target record limits are 4096. Reports
are bounded to 160 batches per sender per second and requests to 128. Saturation
drops excess tracking; existing provenance/history fallback remains available.
The server relay adds a hop for client-to-client tracking, so real friendly-fire
and high-latency tests are required before deployment. No ping reduction has
been measured by the source checks.
