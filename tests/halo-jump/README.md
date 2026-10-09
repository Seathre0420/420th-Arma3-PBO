# Halo Jump multiplayer validation

Run these checks with a graphical multiplayer client against the built mission.
Static checks cannot confirm action-menu updates, freefall physics, or replication.

| Scenario | Expected behavior |
| --- | --- |
| Base arsenal | Both `Arsenal` and `Halo Jump` appear while standing still, on foot, looking at an arsenal within the existing interaction range. Exercise both a simple-object arsenal and an object flagged `QS_arsenal_object`. |
| Base boundary | Arsenals inside the configured main base polygon offer Halo Jump; arsenals outside it and at a FOB do not. Test a concave indentation and the circular fallback with invalid base markers. |
| Zero, one, or two Transport Pilots | After the ten-second countdown, Halo Jump puts the caller at the current `QS_aoPos` X/Y, with `(getPosATL player) # 2` initially approximately 2,000. Test elevated terrain. |
| Countdown timing and privacy | The caller sees `Halo Jumping in 10` immediately, then only `9` through `1` at one-second intervals. At ten seconds, `Good luck soldier!` and teleportation happen together. No `0` is printed. A second client sees none of these messages. |
| Movement cancellation | Walk, strafe, jump, or move away and return between countdown messages. The countdown stops immediately, no teleport or final chat message occurs, and `QS_fnc_hint` displays exactly `Halo Jump cancelled. Player moved.`. Repeat just after `1`. Checks allow at most 5 cm of position jitter or 0.1 m/s of velocity; larger movement cancels. |
| Stationary countdown | Stand still for all ten seconds on flat and sloped terrain. Physics jitter should not cancel the jump. Turn the view without changing position and verify the countdown continues. |
| Repeated selection | Select Halo Jump repeatedly during the countdown. Only one countdown and one teleport occur. After cancellation, stand still and select it again to start a fresh countdown. |
| Death and respawn during countdown | Die or respawn during the countdown. Messages stop and neither the dead unit nor the respawned player teleports. A fresh countdown can be started after respawn. |
| Three or more Transport Pilots | Halo Jump stays visible. Selecting it leaves position unchanged and shows exactly `Halo Jump is unavailable when there are more than two Transport Pilots.` |
| Mixed roles | Count regular and whitelisted Transport Pilots together. Fighter/CAS pilots, AI pilots, and players waiting in the Transport Pilot queue do not count. Dead and distant players still holding a Transport Pilot role count. |
| Role and connection changes | With the action already visible, a third pilot joining/accepting the role blocks the next selection. A third pilot joining during the countdown also prevents teleportation and shows the pilot hint. A pilot disconnecting or changing role to bring the count back to two allows the next selection. |
| Current AO | Change the AO during the countdown; teleportation uses the new center. With `QS_aoPos` unset or `[0,0,0]` at selection or completion, the missing-center hint appears without teleportation or the final chat message. |
| Freefall and landing | With an ordinary backpack and again with a parachute backpack, jump, open the parachute, and land. Equipment survives unchanged and the normal parachute controls work. |
| Action lifecycle | Look between base arsenals, then an outside arsenal, walk away, enter a vehicle, die, and respawn. No duplicate or stale Halo Jump action remains. |
| Multiplayer/JIP | A joining client sees the action. Only the selecting player teleports; other players and the arsenal remain in place. Repeat after respawn. |
| Action security | With `QS_missionConfig_AH` enabled, a regular player can select Halo Jump without an unapproved-action report or removal of their action menu. |
