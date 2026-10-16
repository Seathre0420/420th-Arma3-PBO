# Base firing-area multiplayer validation

Use a graphical client in the built mission. These checks require Arma 3;
source checks cannot verify weapon input, held automatic fire, or action updates.

Place a rectangle area marker named `QS_marker_base_firing_area` wholly inside
the main base. Start with an ordinary rifle and pistol on a living player whose
spawn protection has expired.

| Scenario | Expected behavior |
| --- | --- |
| Inside, on terrain | Rifle and pistol shots fire normally inside the marker at ground level. Repeat on elevated and sloped terrain to confirm the ceiling follows terrain rather than sea level. |
| Height threshold | In the editor/debug console, position the player inside the marker at ATL heights 4.9, 5, and 5.1 m. Test immediately before gravity changes the height, using temporary local simulation control if necessary. Shooting is allowed at 4.9 and exactly 5, and blocked at 5.1. |
| Buildings | Test on a roof less than 5 m and one greater than 5 m above the terrain below. Only the lower position allows shooting. |
| Crossing horizontally | Walk into and out of the marker while remaining inside base. Shooting is allowed only inside. Repeat while holding automatic fire across the boundary in both directions. |
| Crossing vertically | Rise above 5 m and descend back below it inside the marker while attempting to fire. The safety action follows the current height. Repeat while holding automatic fire. |
| Shapes and rotation | Repeat with a rotated rectangle and with an ellipse. Positions outside the actual rotated rectangle or ellipse remain blocked, even inside its bounding rectangle. |
| Missing or invalid marker | Remove/rename the marker, then try an icon marker with that name. Base shooting remains blocked. Hide a valid area marker using alpha 0; its firing permission still works. |
| Marker changes | Move or resize the marker during a test session, including while holding automatic fire. Permission follows its current area. |
| Base boundary | Outside base, ordinary weapon behavior remains unchanged. Also test the base's circular fallback and a marker partially overlapping the base boundary; only the overlapping base portion needs an exception. |
| Existing protection | Shoot a second player and a protected vehicle inside base. Existing damage protection remains. Grenade throwing, placing explosives, and vehicle manual-fire restrictions remain as before. |
| Lifecycle and multiplayer | Repeat after respawn, remote-control changes, and joining in progress. Two players on opposite sides of the marker or altitude ceiling have independent firing permissions. Check that there are no duplicate safety actions or script errors. |
