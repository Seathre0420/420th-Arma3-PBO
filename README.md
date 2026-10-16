Mission file for 420th Delta Invade & Annex.

## Classic AO damage protection

Classic AO ground enemies are protected until a living player on foot and on
the ground reaches within 2,000 m horizontally of the AO center. This unlocks
damage permanently for that AO, including its later reinforcements. Each new
Classic AO starts protected again.

The commander and radio tower retain their existing damage conditions. Enemy
aircraft, aircraft operators, the two Tigris classes (`O_APC_Tracked_02_AA_F`,
`O_T_APC_Tracked_02_AA_ghex_F`), Nyx AA (`I_LT_01_AA_F`), and their operators
retain their existing behavior. Transported infantry remain subject to the AO
protection. Defend and unrelated missions are unaffected.

See `tests/ao-damage-protection/README.md` for offline and multiplayer validation.

## Main base safe zone

Place markers in the Arma 3 Editor named `QS_base_safe_1`, `QS_base_safe_2`,
`QS_base_safe_3`, and so on. Each marker's position defines one vertex of the
main base safe zone. Use unique positive integer suffixes; gaps are allowed.
Markers are sorted numerically (so 2 comes before 10), then connected in that
order, with the last point connected back to the first.

Number the markers clockwise or counterclockwise around the perimeter. Concave
boundaries are supported, but edges must not cross. Use at least three distinct
points enclosing a nonzero area. Marker shape, size, and direction do not affect
the boundary. There is no script-imposed limit on the number of vertices.

The polygon is built at mission initialization and has no altitude restriction.
Adding, removing, or moving these markers in the editor changes the boundary on
the next mission start. With missing markers, malformed or duplicate numeric
suffixes, repeated positions, or zero signed area, the mission logs a diagnostic
and falls back to the original circle (750 m on Altis; 500 m on other maps).
Crossing edges are not automatically validated; check the perimeter in the editor.

This changes only `BASE_HIGHSEC_0`. Its existing protection behavior is retained.
Polygon queries support both objects and coordinate positions so fire-support
target checks also respect the boundary.
The separate 1,000 m `QS_client_inBaseArea` check, vehicle-restricted infantry
spawn polygon, and speed-limit polygons keep their existing definitions.

## Halo Jump

Place a dedicated Halo Jump object (for example, a sign) in the Arma 3 Editor and
put this in its **Init** field, using the same object-variable approach as Spawn
Menu terminals:

```sqf
this setVariable ["QS_haloJump_terminal",true];
```

No variable name or arsenal setup is required. Marked objects offer a `Halo Jump`
action while the player is standing still, on foot, looking at the object within
20 m. The object must be inside `BASE_HIGHSEC_0`, including its circular fallback
when polygon markers are invalid. Ordinary arsenals no longer offer Halo Jump
unless explicitly marked with `QS_haloJump_terminal`.
The flag, object range, and base boundary are checked again before teleportation;
deleting the object or clearing its flag during the countdown prevents the jump.

Selecting the action starts a ten-second countdown in private chat: `Halo Jumping
in 10`, then `9` through `1` at one-second intervals. At ten seconds, `Good luck
soldier!` appears as the player teleports to the current AO center at 2,000 m
above terrain. Moving during the countdown cancels the jump and shows
`Halo Jump cancelled. Player moved.` using `QS_fnc_hint`. Repeated selections do
not start overlapping countdowns. Use the existing `Open Parachute` action during
freefall; the player's backpack and equipment are preserved.

Halo Jump is available with fewer than 30 connected human players in the mission,
regardless of role. At 30 or more, the action remains visible, but selecting it
leaves the player in place and displays:
`Halo Jump is unavailable when there are 30 or more players online.`
The count includes dead players and players outside base, excludes AI and headless
clients, and is checked when selected and again before teleportation. A missing
AO center also prevents teleportation.

## Spawn Menu vehicle abandonment

Non-UAV Spawn Menu vehicles are checked approximately every five seconds. An
unattached vehicle that is neither deployed nor logistics-packed is deleted when
its owner is more than 25 m away inside the main base boundary, or more than
1,500 m away outside it. Owner distance is horizontal (`distance2D`), and exactly
25 m or 1,500 m does not trigger deletion. The main base query uses
`BASE_HIGHSEC_0`, including its existing circular fallback for invalid markers.

This check does not require an empty vehicle, movement from its spawn position,
or absence of other players or rally points. It also replaces submerged cleanup
for these vehicles. Attachment means an `attachedTo` parent; ropes and vehicle
cargo do not independently exempt a vehicle. Deletion retires the vehicle's
manager entry so it is not automatically replaced. Owner disconnect, destruction,
manual vehicle respawn, and UAV cleanup retain their separate behavior.

## Randomized aircraft pylons

Randomized loadouts (mode 2) use the 35-magazine allowlist named
`random_pylon_magazines_1` in
`Apex_framework.terrain/code/config/QS_data_listItems.sqf`. Each pylon selects
only an allowlisted magazine that the aircraft's config reports as compatible.
Matching is case-insensitive, and pylons without eligible magazines stay empty.

The allowlist replaces the old air-to-ground missile blacklist, allowing KH25,
Sharur, and Mk82 where compatible. The existing helicopter AA ammo filter still
applies, and normal AO/defend jets still have bombs removed after loading.
Preset loadouts and Skyfire-only mode keep their existing behavior.

The readable inventory and array are in `docs/reference/`. Keep those copies
synchronized when editing the runtime allowlist, and run
`python tests/randomized-pylons/validate_allowlist.py`. See
`tests/randomized-pylons/README.md` for the in-engine validation procedure.
