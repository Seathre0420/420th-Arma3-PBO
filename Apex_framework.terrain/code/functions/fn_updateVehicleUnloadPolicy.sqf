/*
File: fn_updateVehicleUnloadPolicy.sqf

Description:

	Prevent automatic combat unloading while friendly AI are aboard a
	player-accessible vehicle. The unload policy is local to the vehicle, so it
	must be refreshed when crew or vehicle locality changes.
_____________________________________________________*/

params [['_vehicle',objNull,[objNull]],['_excludedUnit',objNull,[objNull]]];
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {FALSE};
if (isNull _vehicle || {!local _vehicle}) exitWith {FALSE};

private _hasFriendlyAI = ((crew _vehicle) findIf {
	alive _x &&
	{_x isNotEqualTo _excludedUnit} &&
	{!isPlayer _x} &&
	{(side _x) isEqualTo WEST}
}) isNotEqualTo -1;

_vehicle setUnloadInCombat (
	if (_hasFriendlyAI) then {
		[FALSE,FALSE]
	} else {
		_vehicle getVariable ['QS_vSetup_defaultUnloadInCombat',[TRUE,FALSE]]
	}
);

_hasFriendlyAI
