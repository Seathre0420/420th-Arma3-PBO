# Spawn Menu abandonment acceptance checks

For Transport/Logistics Pilot default pylon removal and fuel-tank retention,
also run the spawn checks in `../pilot-pylons/README.md` before boarding.

Run these in multiplayer against the updated mission, using a vehicle created
through the Spawn Menu. Allow at least one vehicle-manager pass (15 seconds plus
processing time) after each change. Distances are horizontal and the owner is the
player who spawned the vehicle. Unless a case specifies occupants, use an empty vehicle.

| Scenario | Expected result |
| --- | --- |
| Inside `BASE_HIGHSEC_0`; owner 99 m, then exactly 100 m, then 101 m away | Retained at 99 m and 100 m; deleted at 101 m. |
| Outside the polygon; owner 1,499 m, then exactly 1,500 m, then 1,501 m away | Retained at 1,499 m and 1,500 m; deleted at 1,501 m. |
| Concave base boundary: vehicle inside the polygon's bounding box but outside the polygon; owner 101 m away | Retained; the configured polygon selects the outside threshold. |
| Vehicle still at its original Spawn Menu position; owner exceeds the applicable threshold | Deleted without first moving the vehicle. |
| Another living player occupies any seat while the owner exceeds the threshold | Retained with no ABANDONED record. Exercise driver/pilot, turret and passenger seats. |
| Only AI occupies the vehicle while the owner exceeds the threshold | Eligible for abandonment cleanup, including friendly AI. |
| Incapacitated but living player occupies a seat while the owner exceeds the threshold | Retained with no ABANDONED record. |
| Last living player exits while the owner remains beyond the threshold, including when AI remains aboard | Deleted on the next eligible pass with exactly one ABANDONED record. Repeat inside base beyond 100 m and outside beyond 1,500 m. |
| Vehicle contains only dead crew while the owner exceeds the threshold | Eligible for abandonment cleanup. |
| Old Black Wasp wreck is cleaned up while the owner pilots a replacement at base | Wreck receives WRECK_CLEANUP; occupied replacement survives subsequent manager passes with no ABANDONED record. |
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

## Logistics container and FOB medical acceptance checks

Run against a dedicated multiplayer server with the regional FOB system enabled
and an existing FOB. Use newly spawned containers; existing objects do not receive
the updated initialization. Inspect variables on the server and record the FOB
flag's `QS_deploy_tickets` before each delivery. Keep other medical assets away
from the FOB during these checks.

| Scenario | Expected result |
| --- | --- |
| Spawn `B_Slingload_01_Medevac_F` through the Spawn Menu outside the FOB's 75 m radius | `QS_services_medical` and `QS_logistics_deployable` are true, `QS_medicalVehicle_reviveTickets` is eight, and `QS_vehicle_isSuppliedFOB` is unset. |
| Bring that container within 75 m of the regional FOB centre while attached or sling-loaded | No tickets are added until the container is detached from both objects and ropes. |
| Detach the container inside the radius and allow the FOB manager to process it | `QS_module_fob_respawnEnabled` becomes true, the flag gains exactly eight `QS_deploy_tickets`, and the container receives `QS_vehicle_isSuppliedFOB = true`. |
| Leave the supplied container in place through further FOB scans without rearming or reattaching it | No additional tickets are added. |
| Deliver a second fresh Spawn Menu medical container under the same conditions | Exactly eight more tickets are added. |
| Repeat with a fresh Zeus medical container and an activated container created through `QS_fnc_registerVehicle` | The medical flag and FOB ticket contribution match the Spawn Menu container. |
| Spawn `Box_B_UAV_06_medical_F` outside the FOB radius and inspect the packed box before assembling its drone | `QS_services_medical` and `QS_logistics_deployable` are true and `QS_medicalVehicle_reviveTickets` is initialized to eight. |
| Deliver that packed medical UAV box to the FOB, detached from objects and ropes, then leave it through further scans | The flag gains exactly eight deployment tickets and the box receives `QS_vehicle_isSuppliedFOB = true`; subsequent scans add no more tickets. |
| Assemble a fresh medical UAV outside the FOB radius; repeat with a directly spawned medical UAV | The UAV has eight revive tickets and `QS_services_medical = true`. Deliver it detached inside the FOB radius and verify eight tickets are credited once. |
| Spawn an ambulance van, either Taru medical asset, each first-aid kit world object, and a portable medical cabinet through shared vehicle setup | Each asset starts with eight revive tickets and contributes eight on a fresh FOB delivery. |
| Spawn HEMTT, Zamak, and Tempest medical trucks through shared vehicle setup | Initial revive tickets are 24, 24, and 18 respectively. Fresh FOB deliveries credit those amounts. |
| Spend a revive ticket from an eight-ticket supplier before FOB delivery | Remaining tickets decrease to seven and the FOB receives seven. The Huron medical container retains its fixed eight-ticket contribution. |
| Service depleted medical assets in an active Level 2 safezone, including eligible attached cargo | Assets with an eight-ticket capacity refill to eight and their supplied-FOB marker is cleared. Larger medical trucks refill to their existing calculated capacities. The asset can supply the FOB again once after servicing. |
| Exercise `QS_fnc_clientServiceVehicle` with an ambulance van, a medical UAV, and a medical truck | The van and UAV receive eight tickets. The truck receives its existing configured passenger-count refill with a minimum of eight. |
| Spawn `FlexibleTank_01_forest_F` | `getFuelCargo` returns zero, `QS_logistics_deployable`, `QS_inventory_disabled`, and `QS_lockedInventory` are true, inventory access is blocked, and the `QS_vSetup_fuelKilledEH` handler is registered. An eligible player can use the deployment action outside restricted build zones. |
| Spawn `Box_NATO_AmmoVeh_F` | `getAmmoCargo` returns zero and `QS_logistics_deployable` is true. An eligible player can use the deployment action outside restricted build zones. |
| Spawn `Land_Pod_Heli_Transport_04_fuel_F` through a logistics pilot terminal | Server-side `getMass` returns 8500; fuel service setup and logistics interactions remain available. Check the black fuel-pod variant through shared vehicle setup as well when its class is available. |
| Spawn Huron ammo, fuel, and repair containers, then deliver each to a fresh regional FOB | Each receives full service setup and enables its matching FOB service; logistics interactions and existing Spawn Menu drag/carry overrides still work. |
| Spawn ordinary supply crates, including `B_CargoNet_01_ammo_F` | Crates retain their existing initialization and contents, including the Cargo Net's custom inventory. |
| Spawn a normal vehicle and recruit an AI soldier | Vehicle setup and AI recruitment retain their existing behavior. |

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
