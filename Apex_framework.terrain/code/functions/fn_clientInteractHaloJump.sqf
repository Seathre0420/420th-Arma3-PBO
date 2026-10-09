/*
File: fn_clientInteractHaloJump.sqf
Description: Jump from a main base arsenal to 2,000 m above the AO center.
*/

if (!hasInterface) exitWith {};
params ['','_caller','','_arsenal'];

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

// ATL places the player 2,000 m above terrain, regardless of the AO's elevation.
// The existing freefall/Open Parachute interaction preserves the player's backpack.
_caller setPosATL [_aoCenter # 0,_aoCenter # 1,2000];
_caller setVelocity [0,0,0];
