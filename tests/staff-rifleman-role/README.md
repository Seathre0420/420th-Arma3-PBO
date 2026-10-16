# Force Rifleman Role acceptance checks

Deploy the updated mission and test on a multiplayer server with a staff member
in the existing `ALL` whitelist and at least one other connected player.

| Scenario | Expected result |
| --- | --- |
| Open the 420th Staff Menu and click `Force Rifleman Role` | A dialog titled `Change Player Role to Rifleman` opens with connected human players and a `Change Role` button below the list. |
| Inspect the roster with living, dead, and distant players, plus a headless client | All connected human players, including the staff member, appear alphabetically. The headless client is excluded. |
| Open the dialog without selecting a player | `Change Role` is disabled until a player is selected. |
| Select a player, then connect/disconnect another player | The list refreshes within about one second and preserves the selected UID. If the selected player disconnects, selection clears and the button disables. |
| Use two players with the same name | Hovering shows their UIDs; selecting either row changes only that account. |
| Select a player, have that player respawn, then click `Change Role` | Their current player object receives the change. |
| Force a specialist outside base, including a pilot with passengers | The selected player immediately becomes Rifleman without a base, movement, or passenger restriction. Their traits, arsenal and saved/default Rifleman loadout update through the normal role initializer. Staff receives a success message. |
| Force a player who holds a limited role and is queued for another role, including an active offer | The old slot is released, the queue entry and offer actions clear, and other queue positions/counts update. The target is not queued for Rifleman. |
| Force a player who already holds Rifleman, including when all Rifleman slots are occupied | They remain Rifleman, any pending queue is cancelled, and their existing slot is reused without duplicating manifest entries. |
| Force a UAV operator with Spawn Menu UAVs | Existing role-change cleanup deletes the player's spawned UAVs. |
| Force an OPFOR player | They move to WEST, where the configured `rifleman` role exists, through the normal side-change handler. |
| Disconnect the selected player immediately before the request reaches the server | No other player changes role; staff receives a disconnected-player message. |
| As a non-staff client, attempt to open `TGC_fnc_staffForceRiflemanGUI` or send `[targetUID] remoteExecCall ["TGC_fnc_forceRiflemanRole", 2, false]` | The dialog/action is rejected and no player state changes. |
| Use Back, Cancel, or Escape | Back returns to the staff menu; Cancel and Escape close the dialog without changing a role. |

These checks require Arma 3; offline source checks cannot verify multiplayer
locality, UI rendering, equipment changes, or queue behavior.
