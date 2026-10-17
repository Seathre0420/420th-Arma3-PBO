/*
File: fn_clientInteractHaloJump.sqf
Description: Count down, then jump from a marked main base object to 2,000 m above the AO center.
Editor object Init: this setVariable ["QS_haloJump_terminal",true];
*/

if (!hasInterface) exitWith {};
params ['','_caller','','_terminal'];
if (_caller getVariable ['QS_haloJump_countdown',FALSE]) exitWith {};

// Recheck the source and caller when selected; the menu updates periodically.
if (
	(_caller isNotEqualTo player) ||
	{!local _caller} ||
	{!((lifeState _caller) in ['HEALTHY','INJURED'])} ||
	{!isNull (objectParent _caller)} ||
	{!isNull (attachedTo _caller)} ||
	{isNull _terminal} ||
	{!(_terminal getVariable ['QS_haloJump_terminal',FALSE])} ||
	{(_caller distance _terminal) >= 20}
) exitWith {};
private _baseZones = (missionNamespace getVariable ['QS_system_zones',[]]) select {(_x # 0) isEqualTo 'BASE_HIGHSEC_0'};
if ((['GET',_terminal,_baseZones] call QS_fnc_zoneManager) isEqualTo []) exitWith {};

// Count regular and whitelisted Transport Pilots, including dead players and those away from base.
private _pilotCount = {isPlayer _x && {(_x getVariable ['QS_unit_role','']) in ['pilot_heli','pilot_heli_WL']}} count allPlayers;
if (_pilotCount >= 3) exitWith {
	private _message = 'Halo Jump is unavailable when there are 3 or more Transport Pilots';
	systemChat _message;
	hint _message;
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
[_caller,_terminal,_startPosition,_startTime] spawn {
	params ['_caller','_terminal','_startPosition','_startTime'];
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
		if (
			isNull _terminal ||
			{!(_terminal getVariable ['QS_haloJump_terminal',FALSE])} ||
			{(_caller distance _terminal) >= 20} ||
			{(['GET',_terminal,_baseZones] call QS_fnc_zoneManager) isEqualTo []}
		) exitWith {};
		private _pilotCount = {isPlayer _x && {(_x getVariable ['QS_unit_role','']) in ['pilot_heli','pilot_heli_WL']}} count allPlayers;
		if (_pilotCount >= 3) exitWith {
			private _message = 'Halo Jump is unavailable when there are 3 or more Transport Pilots';
			systemChat _message;
			hint _message;
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
