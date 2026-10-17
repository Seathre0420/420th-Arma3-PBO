# Spawn Menu abandonment acceptance checks

For Transport/Logistics Pilot default pylon removal and fuel-tank retention,
also run the spawn checks in `../pilot-pylons/README.md` before boarding.

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

## Shared artillery limit acceptance checks

The restricted classes are `B_MBT_01_arty_F`, `B_MBT_01_mlrs_F`,
`O_MBT_02_arty_F`, and `I_Truck_02_MRL_F`. Run with clear spawn points and
allow the existing 10-second spawn cooldown between normal requests. Keep the
owner nearby so abandonment cleanup does not remove the test vehicle.

| Scenario | Expected result |
| --- | --- |
| For each restricted class, spawn it and then request each of the four classes | First request succeeds; all four subsequent artillery choices are rejected with the active-artillery message. |
| Spawn artillery at `ground1`, then request artillery at `ground2` | Rejected; both terminals share the same allowance. |
| Two players each request artillery | Each player can own one active artillery vehicle. |
| Own artillery, then spawn an ordinary vehicle, recruit AI as a group leader, or spawn a supply object | Normal requests succeed subject to existing limits and cooldowns. |
| Own artillery and reach the existing five-active-vehicle total | Additional vehicle requests remain blocked by the existing total limit; objects and AI retain their existing rules. |
| Destroy the artillery or complete its manual Respawn Vehicle deletion, then request any restricted class | A replacement can be spawned once the previous artillery is destroyed or deleted. |
| Die and respawn, change roles, or let another player drive the artillery while it remains alive | Further artillery requests remain blocked for the original owner's UID, including when that owner is staff. |
| Submit two artillery requests for one UID in the same server scheduling interval, with clear separate spawn points | At most one artillery vehicle is created; the pending reservation prevents duplicate admission. |
| Request artillery with a blocked spawn point, or force vehicle creation to return `objNull` in a controlled server test | No artillery slot remains reserved; a later valid request can succeed after the normal cooldown. |
