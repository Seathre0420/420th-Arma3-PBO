/*
File: fn_haloJumpAvailability.sqf
Description: Return an unavailable reason, or an empty string when Halo Jump is available.
Shared by client jump checks and server availability announcements.
*/

params [['_players',allPlayers]];
private _humanPlayers = _players select {isPlayer _x && {!(_x isKindOf 'HeadlessClient_F')}};
private _baseZones = (missionNamespace getVariable ['QS_system_zones',[]]) select {(_x # 0) isEqualTo 'BASE_HIGHSEC_0'};
private _pilotOnBase = (_humanPlayers findIf {
	((_x getVariable ['QS_unit_role','']) in ['pilot_heli','pilot_heli_WL']) &&
	{(['GET',_x,_baseZones] call QS_fnc_zoneManager) isNotEqualTo []}
}) isNotEqualTo -1;
if (_pilotOnBase) exitWith {
	'Halo Jump is unavailable when there is a Transport Pilot on base'
};
if ((count _humanPlayers) >= 20) exitWith {
	'Halo Jump is unavailable when there are 20 or more players on the server'
};
''
