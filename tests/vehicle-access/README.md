# Engine seat locks (Arma 3 2.22+)

Use a dedicated server, owner A, non-owner B, and joining player C. Run with
script errors enabled and inspect client/server RPTs. Source checks:
`node tests/vehicle-access/validate_source.cjs`.

| Scenario | Expected result |
| --- | --- |
| A takes ownership while driving | Driver locks by default; B loses driver entry action. |
| Toggle Driver, Gunner, Commander, Passenger separately | Corresponding entry and seat-switch actions disappear/reappear; unrelated groups remain available. |
| Ghost Hawk and armed Huron | Gunner controls both weapon turrets, including auxiliary side gun. |
| Vehicle with FFV and ordinary cargo | Passenger controls both; Gunner does not control FFV. |
| Every group locked; A exits | A can open Vehicle Access within 3 m of vehicle bounds and use the separate owner role actions; B stays locked out throughout boarding. |
| Non-developer A, anti-hack enabled | Take Ownership, Vehicle Access, and all five boarding choices survive opening/using the action menu; no non-whitelisted action warning or removal. |
| Large Ghost Hawk/Huron; A at a door beyond 3 m of model origin | Outside Vehicle Access and available role choices are visible and work; walking beyond 3 m of vehicle bounds closes the access dialog and rejects changes. |
| Owner boarding | Only the selected role is used, even if a higher-priority role is empty; full role causes no displacement or fallback to another role. Auxiliary Turret / FFV and Passenger each select the first available seat in that engine role, not an exact numbered seat. |
| Independent disabled/locked seat, including MH-9 benches | Ownership unlock preserves restriction; owner bypass excludes any role with independently locked empty candidates. |
| Role restrictions, reports, safe zones, wreck, carried casualty | Owner boarding obeys existing boarding restrictions. |
| A wants to switch seats inside a stationary ground vehicle or landed aircraft | Owner role choices bypass ownership locks and move A to the selected role; locks remain set and other players remain blocked. |
| A wants to switch seats in flight | Custom transfer refuses to move A out of the aircraft; Vehicle Access remains available to unlock the destination, switch normally, and relock. |
| B uses quick cargo boarding | No boarding into a locked cargo/FFV position. |
| A changes locks while someone is seated | Current occupant remains; existing eject buttons retain their behavior and altitude restriction. |
| B tries old context driver-lock action | Directed to Vehicle Access; ownership settings unchanged. |
| Driver exits, another permitted driver enters; repeated locality transfers | Engine state continues to match ownership settings; no driver auto-unlock. |
| C joins after ownership was taken | Locks and locality hook present; C cannot enter locked seats. |
| A respawns/reconnects | UID ownership retained for surviving vehicles; outside actions work without duplicates. |
| Spawned vehicle deleted on disconnect | Existing deletion behavior; persistent RPC removed with vehicle. |
| Rapid toggles; request from non-owner or spoofed player argument | Requests serialized on server; non-owner/spoofed request rejected. |

Engine locks are the normal entry barrier. Existing entry/seat-change checks
remain as fallback for scripts that explicitly bypass locks. Existing occupants
are not automatically ejected by a lock toggle. Independent lock state is captured
when ownership begins and tracked through the framework remote lock dispatcher;
third-party scripts issuing engine commands directly must integrate with
`QS_fnc_vehicleAccessExternalLock` to participate in lock composition.
