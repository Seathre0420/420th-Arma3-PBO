/*
File: fn_clientInteractHaloJump.sqf
Description: Count down, then jump from a main base arsenal to 2,000 m above the AO center.
*/

if (!hasInterface) exitWith {};
params ['','_caller','','_arsenal'];
if (_caller getVariable ['QS_haloJump_countdown',FALSE]) exitWith {};

// Recheck the source and caller when selected; the menu updates periodically.
if (
	(_caller isNotEqualTo player) ||
	{!local _caller} ||
	{!((lifeState _caller) in ['HEALTHY','INJURED'])} ||
	{!isNull (objectParent _caller)} ||
	{!isNull (attachedTo _caller)} ||
	{isNull _arsenal} ||
	{(_caller distance _arsenal) >= 20}
) exitWith {};
private _arsenalModels = ['arsenal_model_1'] call (missionNamespace getVariable 'QS_data_listOther');
if (
	!(_arsenal getVariable ['QS_arsenal_object',FALSE]) &&
	{!((((getModelInfo _arsenal) # 1) in _arsenalModels) && {!simulationEnabled _arsenal})}
) exitWith {};
private _baseZones = (missionNamespace getVariable ['QS_system_zones',[]]) select {(_x # 0) isEqualTo 'BASE_HIGHSEC_0'};
if ((['GET',_arsenal,_baseZones] call QS_fnc_zoneManager) isEqualTo []) exitWith {};

// Include both regular and whitelisted Transport Pilots, even while dead or away from base.
private _pilotCount = {isPlayer _x && {(_x getVariable ['QS_unit_role','']) in ['pilot_heli','pilot_heli_WL']}} count allPlayers;
if (_pilotCount > 2) exitWith {
	hint 'Halo Jump is unavailable when there are more than two Transport Pilots.';
};

private _aoCenter = missionNamespace getVariable ['QS_aoPos',[0,0,0]];
if (_aoCenter isEqualTo [0,0,0]) exitWith {
	hint 'Halo Jump is unavailable because the AO center is not set.';
};

// Set the guard before spawning so repeated action selections cannot overlap.
_caller setVariable ['QS_haloJump_countdown',TRUE,FALSE];
private _startPosition = getPosASL _caller;
private _startTime = diag_tickTime;
systemChat 'Halo Jumping in 10';
[_caller,_arsenal,_startPosition,_startTime] spawn {
	params ['_caller','_arsenal','_startPosition','_startTime'];
	private _cancelled = FALSE;
	private _moved = FALSE;
	private _nextMessageTime = _startTime + 1;
	private _callerValid = {
		(!isNull _caller) &&
		{_caller isEqualTo player} &&
		{local _caller} &&
		{(lifeState _caller) in ['HEALTHY','INJURED']}
	};
	private _hasMoved = {
		((getPosASL _caller) distance _startPosition) > 0.05 ||
		{(vectorMagnitude (velocity _caller)) > 0.1} ||
		{!isNull (objectParent _caller)} ||
		{!isNull (attachedTo _caller)}
	};
	for '_remaining' from 9 to 0 step -1 do {
		waitUntil {
			uiSleep 0.01;
			_cancelled = !(call _callerValid);
			if (!_cancelled) then {
				// Ignore tiny physics jitter; check throughout each second so moving back still cancels.
				_moved = call _hasMoved;
			};
			_cancelled || {_moved} || {diag_tickTime >= _nextMessageTime}
		};
		if (_cancelled || {_moved}) exitWith {};
		if (_remaining > 0) then {
			// This runs only on the caller's client; no chat messages are broadcast.
			systemChat (str _remaining);
		};
		_nextMessageTime = _nextMessageTime + 1;
	};
	// Final checks, chat, and teleport run together without a scheduler interruption.
	isNil {
		_caller setVariable ['QS_haloJump_countdown',FALSE,FALSE];
		if (_moved) exitWith {
			['Halo Jump cancelled. Player moved.'] call QS_fnc_hint;
		};
		if (_cancelled || {!(call _callerValid)}) exitWith {};
		if (call _hasMoved) exitWith {
			['Halo Jump cancelled. Player moved.'] call QS_fnc_hint;
		};

		// Recheck availability and use the current AO when the countdown finishes.
		private _baseZones = (missionNamespace getVariable ['QS_system_zones',[]]) select {(_x # 0) isEqualTo 'BASE_HIGHSEC_0'};
		if (isNull _arsenal || {(['GET',_arsenal,_baseZones] call QS_fnc_zoneManager) isEqualTo []}) exitWith {};
		private _pilotCount = {isPlayer _x && {(_x getVariable ['QS_unit_role','']) in ['pilot_heli','pilot_heli_WL']}} count allPlayers;
		if (_pilotCount > 2) exitWith {
			hint 'Halo Jump is unavailable when there are more than two Transport Pilots.';
		};
		private _aoCenter = missionNamespace getVariable ['QS_aoPos',[0,0,0]];
		if (_aoCenter isEqualTo [0,0,0]) exitWith {
			hint 'Halo Jump is unavailable because the AO center is not set.';
		};

		systemChat 'Good luck soldier!';
		// ATL places the player 2,000 m above terrain, regardless of the AO's elevation.
		// The existing freefall/Open Parachute interaction preserves the player's backpack.
		_caller setPosATL [_aoCenter # 0,_aoCenter # 1,2000];
		_caller setVelocity [0,0,0];
	};
};
