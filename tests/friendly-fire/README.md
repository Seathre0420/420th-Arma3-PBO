# Unified friendly-fire validation

Run `node tests/friendly-fire/validate_source.cjs` for delimiter/string validation of changed SQF and registration files. This is not an SQF compiler.

Copy these tests into a disposable dedicated multiplayer mission and run `[] execVM "tests\friendly-fire\validate_engine.sqf"` on the server. Require zero failures. It creates and deletes test entities.

Then test real weapon damage with two clients and a headless client. Record RPT, overall damage and all hit-point damage before and after each shot. Protected hits must leave all values unchanged and must not incapacitate, punish, damage fuel/rotors or schedule delayed damage.

- Defender missiles, terminal and nearby control: Spawn Menu and editor/script aircraft, occupied and empty, planes and helicopters, inside/outside safe zones.
- Release control, disconnect, delete launcher, change target or transfer locality during flight. Test simultaneous hostile/friendly missiles of the same ammo class.
- Bullets, grenades, artillery, direct/indirect explosions, mines and underwater demolition; deliberate enemy remote control by friendly player.
- Friendly/enemy infantry and UAV crews, empty/occupied land/sea/air vehicles; JIP, respawn, server/client/headless transfers.
- Vehicle impacts, sling-load and secondary fuel explosions; verify enemy/environment damage and ordinary repairs still work.
- Restricted/hidden/owned turret: terminal and nearby action must agree on access.
- Profile automatic fire and reconciliation with mission-scale entity counts.

Engine tests and physics matrix have NOT been executed by Codex. Deployment acceptance remains pending their results.
