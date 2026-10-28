/* Runs on vehicle locality owner. Only the server may invoke remotely. */
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {};
params ['_vehicle'];
if (isNull _vehicle) exitWith {};
if !(_vehicle getVariable ['QS_vehicleAccess_localEH',FALSE]) then {
	_vehicle setVariable ['QS_vehicleAccess_localEH',TRUE];
	_vehicle addEventHandler ['Local',{params ['_vehicle','_local']; if (_local) then {[_vehicle] call QS_fnc_vehicleAccessApply;};}];
};
if (!local _vehicle) exitWith {};
if ((_vehicle getVariable ['QS_vehicleAccess_ownerUID','']) isEqualTo '') exitWith {};
private _seats = [_vehicle] call QS_fnc_vehicleAccessSeats;
private _base = _vehicle getVariable ['QS_vehicleAccess_base',[]];
{
	_x params ['_group','_kind','_identity','_locked'];
	private _index = _base findIf {((_x # 0) isEqualTo _kind) && {(_x # 1) isEqualTo _identity}};
	if (_index < 0) then {
		_index = _base pushBack [_kind,_identity,_locked];
	};
	private _effective = ((_base # _index) # 2) || {_vehicle getVariable [format ['QS_vehicleAccess_%1Locked',_group],FALSE]};
	switch _kind do {
		case 'DRIVER': {_vehicle lockDriver _effective};
		case 'CARGO': {_vehicle lockCargo [_identity,_effective]};
		default {_vehicle lockTurret [_identity,_effective]};
	};
} forEach _seats;
_vehicle setVariable ['QS_vehicleAccess_base',_base,TRUE];
