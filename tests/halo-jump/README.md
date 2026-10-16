# Halo Jump multiplayer validation

Run these checks with a graphical multiplayer client against the built mission.
Static checks cannot confirm action-menu updates, freefall physics, or replication.

| Scenario | Expected behavior |
| --- | --- |
| Editor setup | Place a sign or other object at base with `this setVariable ["QS_haloJump_terminal",true];` in its Init field. `Halo Jump` appears while standing still, on foot, looking at it within 20 m. Test both a regular object and a simple object; neither needs an arsenal model or `QS_arsenal_object`. |
| Ordinary arsenals and unmarked objects | Regular and simple-object arsenals, including objects flagged only with `QS_arsenal_object`, retain `Arsenal` but do not offer Halo Jump. Unmarked signs and objects with `QS_haloJump_terminal` set to false do not offer Halo Jump. Explicitly marking an arsenal offers both actions. |
| Base boundary | Marked objects inside the configured main base polygon offer Halo Jump; marked objects outside it and at a FOB do not. Test a concave indentation and the circular fallback with invalid base markers. |
| Terminal validation | Delete the marked object, clear its `QS_haloJump_terminal` flag, move it outside base, or move it 20 m or more from the caller during the countdown. No teleportation or final chat message occurs. Stand still and select a valid marked object again to start a fresh countdown. |
| Fewer than 30 players | With 1 and then 29 connected human players, Halo Jump puts the caller at the current `QS_aoPos` X/Y after the ten-second countdown, with `(getPosATL player) # 2` initially approximately 2,000. Test elevated terrain. |
| Countdown timing and privacy | The caller sees `Halo Jumping in 10` immediately, then only `9` through `1` at one-second intervals. At ten seconds, `Good luck soldier!` and teleportation happen together. No `0` is printed. A second client sees none of these messages. |
| Movement cancellation | Walk, strafe, jump, or move away and return between countdown messages. The countdown stops immediately, no teleport or final chat message occurs, and `QS_fnc_hint` displays exactly `Halo Jump cancelled. Player moved.`. Repeat just after `1`. Checks allow at most 5 cm of position jitter or 0.1 m/s of velocity; larger movement cancels. |
| Stationary countdown | Stand still for all ten seconds on flat and sloped terrain. Physics jitter should not cancel the jump. Turn the view without changing position and verify the countdown continues. |
| Repeated selection | Select Halo Jump repeatedly during the countdown. Only one countdown and one teleport occur. After cancellation, stand still and select it again to start a fresh countdown. |
| Death and respawn during countdown | Die or respawn during the countdown. Messages stop and neither the dead unit nor the respawned player teleports. A fresh countdown can be started after respawn. |
| 30 or more players | Test exactly 30 and then 31 connected human players. Halo Jump stays visible. Selecting it leaves position unchanged and shows exactly `Halo Jump is unavailable when there are 30 or more players online.` |
| Mixed roles and client types | Count connected human players in every role, including Transport Pilots, fighter/CAS pilots, infantry, and players queued for roles. Dead and distant players count; AI and headless clients do not. With 29 humans plus a headless client, jumping remains available. |
| Role and connection changes | With the action already visible, a 30th human player joining blocks the next selection. A 30th player joining and remaining through the end of the countdown prevents teleportation and shows the player-count hint. A player disconnecting to bring the count back to 29 allows the next selection. Changing roles does not change availability. |
| Current AO | Change the AO during the countdown; teleportation uses the new center. With `QS_aoPos` unset or `[0,0,0]` at selection or completion, the missing-center hint appears without teleportation or the final chat message. |
| Freefall and landing | With an ordinary backpack and again with a parachute backpack, jump, open the parachute, and land. Equipment survives unchanged and the normal parachute controls work. |
| Action lifecycle | Look between marked base objects, then an unmarked arsenal and a marked object outside base, walk away, enter a vehicle, die, and respawn. Clear and restore the object flag. No duplicate or stale Halo Jump action remains. |
| Multiplayer/JIP | A joining client sees the action on an editor-marked object. Only the selecting player teleports; other players and the terminal remain in place. Repeat after respawn. |
| Action security | With `QS_missionConfig_AH` enabled, a regular player can select Halo Jump without an unapproved-action report or removal of their action menu. |
