/* Merge existing framework lock requests with ownership restrictions. */
params ['_vehicle','_kind','_value'];
if ((_vehicle getVariable ['QS_vehicleAccess_ownerUID','']) isEqualTo '') exitWith {FALSE};
if (!local _vehicle) exitWith {TRUE};
private _base = _vehicle getVariable ['QS_vehicleAccess_base',[]];
{
	_x params ['_group','_seatKind','_identity','_locked'];
	if (_seatKind isEqualTo _kind) then {
		private _matches = _value isEqualType TRUE;
		private _state = _value;
		if (!_matches) then {
			_state = _value # 1;
			_matches = (_identity isEqualTo (_value # 0)) || {(_kind isEqualTo 'CARGO') && {(_value # 0) isEqualType []} && {_identity in (_value # 0)}};
		};
		if (_matches) then {
			private _index = _base findIf {((_x # 0) isEqualTo _kind) && {(_x # 1) isEqualTo _identity}};
			if (_index < 0) then {_base pushBack [_kind,_identity,_state];} else {(_base # _index) set [2,_state];};
			private _effective = _state || {_vehicle getVariable [format ['QS_vehicleAccess_%1Locked',_group],FALSE]};
			switch _kind do {
				case 'DRIVER': {_vehicle lockDriver _effective};
				case 'CARGO': {_vehicle lockCargo [_identity,_effective]};
				default {_vehicle lockTurret [_identity,_effective]};
			};
		};
	};
} forEach ([_vehicle] call QS_fnc_vehicleAccessSeats);
_vehicle setVariable ['QS_vehicleAccess_base',_base,TRUE];
TRUE
