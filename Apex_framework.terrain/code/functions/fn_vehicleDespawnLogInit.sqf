/* Register before mission setup can retire editor vehicles. No gameplay changes. */
if (!isServer) exitWith {};
if (serverNamespace getVariable ['QS_despawn_initialized',FALSE]) exitWith {};
serverNamespace setVariable ['QS_despawn_initialized',TRUE];
serverNamespace setVariable ['QS_despawn_pending',createHashMap];
serverNamespace setVariable ['QS_despawn_reports',createHashMap];
serverNamespace setVariable ['QS_despawn_sequence',0];
addMissionEventHandler ['EntityDeleted',{
	['DELETED',_this] call QS_fnc_vehicleDespawnLog;
}];
[] spawn {
	while {TRUE} do {
		uiSleep 0.5;
		['FLUSH'] call QS_fnc_vehicleDespawnLog;
	};
};
