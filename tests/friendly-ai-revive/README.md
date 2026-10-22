# Friendly AI revive validation

Run `node tests/friendly-ai-revive/validate_source.cjs` for the offline syntax
smoke check. It does not compile SQF or prove runtime behavior.

Run `[] execVM "tests\friendly-ai-revive\validate_engine.sqf"` on the server
in a disposable multiplayer mission with these test files copied into it.
The RPT must report zero failures. The harness creates and deletes test units;
it checks lifecycle transitions and advances deadlines for expiry tests.

Also verify in the full mission:

1. Enemy gunfire, head/torso shots and explosions incapacitate friendly infantry.
   Nonlethal hits injure normally. Player damage (including enemy players and
   remote-controlled units) and friendly military AI damage remain blocked.
   Recruited AI retain configured damage reduction. Enemy/civilian units and
   virtual UAV crew retain their existing behavior.
2. Leave a casualty for 300 seconds: it dies within one monitor interval (0.5 s).
   Additional hits cannot kill it or reset its deadline. Down two units together.
3. Revive with a player medic and a remote-controlled medic, both on the unit's
   owner and a different client. Verify full health, normal movement/damage,
   cleared drag state, and a fresh deadline after another incapacitation.
4. Drag/carry, load into a vehicle and unload before expiry. Temporary wake-up
   during unloading must not cancel the episode. Transport never extends time.
5. Transfer a downed group server -> client -> headless client -> server, and
   disconnect its owning player. The deadline stays unchanged; revival and
   expiry work on the current owner. Join a client while a unit is down.
6. Check editor units, Spawn Menu recruits, Zeus units, respawn, deletion and
   recycling. Script-created unconscious mission patients must not acquire an
   automatic timer. Existing player revive and scripted cleanup remain intact.

Use combat damage for damage interception tests; `setDamage` bypasses
`HandleDamage`. Engine execution is required to validate physics and locality.
