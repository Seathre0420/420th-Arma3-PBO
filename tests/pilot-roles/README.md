# Pilot role acceptance checks

Deploy the updated mission and `@Apex_cfg` configuration together. Compare both
new roles with the active Transport Pilot (`pilot_heli`) using the role menu.
The current configuration has no terrain-specific overrides.

| Scenario | Expected result |
| --- | --- |
| Open the role menu and inspect the roster, current-role label, and map tooltip | `Attack Pilot (Whitelisted)` and `Logistics Pilot (Whitelisted)` appear with no additional `[Whitelisted]` prefix. Transport Pilot retains its existing label. |
| Select either new role with an S3-whitelisted WEST player | Selection succeeds with the same restrictions as Transport Pilot. |
| Open the menu with a player outside the S3 whitelist, including a pilot-leaderboard-only whitelist player | Both new roles are disabled, matching the active Transport Pilot's S3 selection condition. |
| Inspect each new role's description and preview | Same transport description and existing transport image; no missing image on arid or tropical terrain. |
| Select each role, reset its loadout, open the arsenal, and respawn | Same default equipment, arsenal choices, pilot/CAS traits, and helicopter spawn as Transport Pilot. Compare both arid and tropical equipment. |
| Switch from infantry, UAV Operator, Fighter Pilot, or Commander to either new role | Aircraft radio membership matches Transport Pilot, including the player's saved aircraft-radio preference. |
| Use `pilot1`, `pilot2`, `pilot3`, `logistics_pilots`, `logistics_pilots2`, and `ai_pilots` terminals | Each new role can use the same terminal options as Transport Pilot; the server accepts the spawns. |
| Occupy slots in one of the three roles | Counts and vacancies remain independent. Each new role starts with 5 slots and scales to 15 using the same thresholds as Transport Pilot. |
| Fill a new role, queue for it, and release a slot | Existing queue notifications and acceptance work, with helicopter spawn on assignment. |
| While holding either new role, queue for another full role and release a slot there | The offer lasts 180 seconds, with reminders at 120 and 60 seconds remaining, as for Transport Pilot. |
| Attempt a role change while piloting with human passengers | Existing passenger drop-off restriction applies. |
| Save a customized loadout in one new role and switch among all three | Each role restores its own saved loadout; default loadouts are identical when no saved loadout exists. |

These are in-engine checks; source validation alone cannot confirm multiplayer
UI, radio, spawn locality, or queue timing.
