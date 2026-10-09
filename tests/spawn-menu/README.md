# Spawn Menu abandonment acceptance checks

Run these in multiplayer against the updated mission, using a vehicle created
through the Spawn Menu. Allow at least one vehicle-manager pass (approximately
five seconds) after each change. Distances are horizontal and the owner is the
player who spawned the vehicle.

| Scenario | Expected result |
| --- | --- |
| Inside the `QS_base_safe_#` polygon; owner 24 m, then exactly 25 m, then 26 m away | Retained at 24 m and 25 m; deleted at 26 m. |
| Outside the polygon; owner 1,499 m, then exactly 1,500 m, then 1,501 m away | Retained at 1,499 m and 1,500 m; deleted at 1,501 m. |
| Concave base boundary: vehicle inside the polygon's bounding box but outside the polygon; owner 26 m away | Retained; the polygon, not its bounding box or a base-marker radius, selects the threshold. |
| Vehicle still at its original Spawn Menu position; owner exceeds the applicable threshold | Deleted without first moving the vehicle. |
| Another player or AI occupies the vehicle while the owner exceeds the threshold | Deleted; crew occupancy does not protect the vehicle. |
| Another player or an active vehicle rally point is next to the vehicle; owner exceeds the threshold | Deleted; only the owner's distance matters. |
| Vehicle attached to another object with `attachTo`; owner exceeds the threshold | Retained until detached, then deleted on a subsequent pass. |
| Vehicle is deployed or logistics-packed; owner exceeds the threshold | Retained until both protections are cleared. Exercise the normal deployment and packing actions to verify their lifecycle still works. |
| Non-ship vehicle submerged while the owner remains within the applicable threshold | Retained by abandonment cleanup; the previous submerged-distance rule does not apply. Destruction still permits wreck cleanup. |
| Helicopter with more than 15 players connected; owner is nearby without the pilot trait | Retained; no pilot-trait filter applies. |
| Owner returns within the threshold before the next manager pass | Retained; there is no abandonment countdown. |
| Spawn Menu UAV with owner beyond either threshold | Retained by abandonment cleanup; test UAV role change, disconnect, and destruction separately. |
| Owner disconnects, vehicle is destroyed, or manual Respawn Vehicle completes | Existing deletion behavior still works without automatic replacement. |
| Vehicle spawned by the normal mission vehicle system | Existing abandonment rules still apply. |
| Mission started with invalid/missing base-polygon markers | Existing `BASE_HIGHSEC_0` circular fallback selects the inside/outside threshold. |
