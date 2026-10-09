# Halo Jump multiplayer validation

Run these checks with a graphical multiplayer client against the built mission.
Static checks cannot confirm action-menu updates, freefall physics, or replication.

| Scenario | Expected behavior |
| --- | --- |
| Base arsenal | Both `Arsenal` and `Halo Jump` appear while standing still, on foot, looking at an arsenal within the existing interaction range. Exercise both a simple-object arsenal and an object flagged `QS_arsenal_object`. |
| Base boundary | Arsenals inside the configured main base polygon offer Halo Jump; arsenals outside it and at a FOB do not. Test a concave indentation and the circular fallback with invalid base markers. |
| Zero, one, or two Transport Pilots | Selecting Halo Jump puts the caller at the current `QS_aoPos` X/Y, with `(getPosATL player) # 2` initially approximately 2,000. Test elevated terrain. |
| Three or more Transport Pilots | Halo Jump stays visible. Selecting it leaves position unchanged and shows exactly `Halo Jump is unavailable when there are more than two Transport Pilots.` |
| Mixed roles | Count regular and whitelisted Transport Pilots together. Fighter/CAS pilots, AI pilots, and players waiting in the Transport Pilot queue do not count. Dead and distant players still holding a Transport Pilot role count. |
| Role and connection changes | With the action already visible, a third pilot joining/accepting the role blocks the next selection. A pilot disconnecting or changing role to bring the count back to two allows the next selection. |
| Current AO | Change the AO while the action is visible; selection uses the new center. With `QS_aoPos` unset or `[0,0,0]`, selection shows the missing-center hint without teleporting. |
| Freefall and landing | With an ordinary backpack and again with a parachute backpack, jump, open the parachute, and land. Equipment survives unchanged and the normal parachute controls work. |
| Action lifecycle | Look between base arsenals, then an outside arsenal, walk away, enter a vehicle, die, and respawn. No duplicate or stale Halo Jump action remains. |
| Multiplayer/JIP | A joining client sees the action. Only the selecting player teleports; other players and the arsenal remain in place. Repeat after respawn. |
| Action security | With `QS_missionConfig_AH` enabled, a regular player can select Halo Jump without an unapproved-action report or removal of their action menu. |
