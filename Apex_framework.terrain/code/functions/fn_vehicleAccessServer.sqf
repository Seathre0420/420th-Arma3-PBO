/* Validated ownership and lock requests; no client-selected lock commands. */
if (!isServer) exitWith {};
params ['_mode','_unit','_vehicle',['_group','']];
if (isNull _unit || {!isPlayer _unit} || {!alive _unit} || {(owner _unit) isNotEqualTo remoteExecutedOwner} || {isNull _vehicle} || {!alive _vehicle}) exitWith {};
private _uid = getPlayerUID _unit;
if (_uid isEqualTo '') exitWith {};
if (_mode isEqualTo 'TAKE') exitWith {
	if ((_unit isNotEqualTo driver _vehicle) || {(_vehicle getVariable ['QS_vehicleAccess_ownerUID','']) isNotEqualTo ''}) exitWith {};
	_vehicle setVariable ['QS_vehicleAccess_ownerUID',_uid,TRUE];
	_vehicle setVariable ['QS_vehicleAccess_driverLocked',TRUE,TRUE];
	[_vehicle] remoteExecCall ['QS_fnc_vehicleAccessApply',0,_vehicle];
};
if ((_vehicle getVariable ['QS_vehicleAccess_ownerUID','']) isNotEqualTo _uid) exitWith {};
if ((objectParent _unit) isNotEqualTo _vehicle && {(_unit distance _vehicle) > 3}) exitWith {};
if (_mode isEqualTo 'BOARD' && {isNull objectParent _unit}) exitWith {
	[_unit,_vehicle] remoteExecCall ['QS_fnc_vehicleAccessBoard',_unit];
};
if (_mode isEqualTo 'TOGGLE' && {_group in ['driver','gunner','commander','passenger']}) then {
	private _key = format ['QS_vehicleAccess_%1Locked',_group];
	_vehicle setVariable [_key,!(_vehicle getVariable [_key,FALSE]),TRUE];
	[_vehicle] remoteExecCall ['QS_fnc_vehicleAccessApply',_vehicle];
};
