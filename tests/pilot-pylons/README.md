# Pilot pylon restriction checks

Run `validate_engine.sqf` on the server in a disposable Arma editor/Server Lab session
after mission initialization (copy it into the mission for `execVM`). It creates
and deletes local test aircraft and an AI pilot. It checks default helicopters
and a fighter, each restricted role, unaffected roles, compatible AA/fuel-tank retention,
AGM/bomb/rocket/gun-pod removal, empty pylons, and preservation of native weapons
and their ammunition. Failures are logged and returned as an array. It must
report that AA, all four fuel-tank variants, and forbidden magazines were exercised.

AA identification requires `MissileCore` ammunition with `airLock = 2` (air-only
targeting), plus compatibility with that pylon. Unknown/modded nonconforming
magazines are removed. The explicit fuel-tank exceptions are `PylonFuelTank_UH80`,
`PylonFuelTank_UH80_Green`, `PylonFuelTank_UH80_Tropic`, and
`PylonFuelTank_UH80_Sand`; these also require pylon compatibility. No replacement
missiles or fuel tanks are automatically fitted.

On a multiplayer server verify:

| Scenario | Expected |
| --- | --- |
| Spawn an aircraft as Transport or Logistics Pilot and inspect before boarding | All default pylon weapons, including AA, are absent; compatible fuel tanks and native guns remain. |
| Spawn the same aircraft as Attack Pilot, Fighter Pilot, or staff | Default loadout remains. |
| Fit compatible AA to a restricted pilot's aircraft after spawning | Normal role checks retain AA. |
| Enter as Transport or Logistics Pilot, including whitelisted transport | Forbidden pylons clear; compatible AA, the four UH-80 fuel-tank variants, and built-in guns/door guns/countermeasures remain. |
| Fit each fuel-tank variant to a compatible Ghost Hawk pylon and enter, switch seats, change roles, rearm, or apply a hangar preset | Tank and added fuel capacity remain through restriction checks. |
| Enter as Attack or Fighter Pilot | Existing loadout remains. |
| Move from passenger or gunner into driver seat | Restriction follows the new driver's role. |
| Restricted pilot with a human gunner on another client | Both pilot-owned and gunner-owned forbidden pylons clear; native turret weapons work. |
| Switch pilot roles while seated, respawn, reconnect, or transfer vehicle locality | Restriction applies within the recurring half-second check once ownership/role is synchronized. |
| Rearm manually, automatically, or via an ammo truck | Removed pylons remain empty; retained AA reloads normally. |
| Change pylons through Zeus/scripts while restricted | Forbidden additions are removed on the next crew-client check. |
| Temporarily enable hangar selection in a test copy and apply a mixed preset | Local turret owners clear forbidden pylons immediately after applying it. |
| Restricted role rides as passenger with an unrestricted driver | Driver's loadout remains. |
| Restricted driver leaves or switches to Attack Pilot | Removed ordnance stays empty until explicitly reconfigured. |

Offline checks cannot prove Arma configuration, turret locality, or multiplayer
replication. The recurring check permits up to about half a second before an
external script's new loadout is cleared; it is not an anti-cheat mechanism.

Configuration reference: [Bohemia targeting configuration](https://community.bistudio.com/wiki/A3_Targeting_config_reference).
