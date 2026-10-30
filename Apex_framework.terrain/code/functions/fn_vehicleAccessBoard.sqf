/* Owner-only boarding, invoked by the server on the player's machine. Requires 2.22. */
if (!isRemoteExecuted || {remoteExecutedOwner isNotEqualTo 2}) exitWith {};
params ['_unit','_vehicle','_requestedRole'];
if (!(_requestedRole in ['DRIVER','COMMANDER','GUNNER','TURRET','CARGO'])) exitWith {};
if (!local _unit || {!alive _unit} || {!([_unit,_vehicle] call QS_fnc_vehicleAccessNear)} || {abs speed _vehicle > 5} || {!((locked _vehicle) in [0,1])} || {(_vehicle getVariable ['QS_vehicleAccess_ownerUID','']) isNotEqualTo getPlayerUID _unit}) exitWith {};
private _inside = (objectParent _unit) isEqualTo _vehicle;
// moveInAny requires an on-foot unit. Never perform the intervening moveOut
// in flight; owners can still use Vehicle Access to unlock and switch normally.
if (_inside && {_vehicle isKindOf 'Air'} && {!isTouchingGround _vehicle}) exitWith {
	systemChat 'For a seat change in flight, unlock the destination in Vehicle Access and switch normally.';
};
private _base = _vehicle getVariable ['QS_vehicleAccess_base',[]];
private _seats = [_vehicle] call QS_fnc_vehicleAccessSeats;
private _roles = [_requestedRole] select {
	private _role = _x;
	private _candidates = _seats select {isNull (_x # 4) && {(_x # 5) isEqualTo _role}};
	(_candidates isNotEqualTo []) && {(_candidates findIf {
		private _seat = _x;
		private _index = _base findIf {((_x # 0) isEqualTo (_seat # 1)) && {(_x # 1) isEqualTo (_seat # 2)}};
		(_index < 0) || {(_base # _index) # 2}
	}) < 0}
};
if (_vehicle getVariable ['QS_driver_disabled',FALSE]) then {_roles = _roles - ['DRIVER'];};
// Reuse normal boarding restrictions (pilot roles, reports, safe zones, wrecks).
// Check every candidate: moveInAny cannot select an individual auxiliary turret.
_roles = _roles select {
	private _role = _x;
	private _action = switch _role do {
		case 'DRIVER': {if (_vehicle isKindOf 'Air') then {'GetInPilot'} else {'GetInDriver'}};
		case 'COMMANDER': {'GetInCommander'};
		case 'GUNNER': {'GetInGunner'};
		case 'TURRET': {'GetInTurret'};
		default {'GetInCargo'};
	};
	private _candidates = (fullCrew [_vehicle,'',TRUE]) select {isNull (_x # 0) && {(toUpperANSI (_x # 1)) isEqualTo _role}};
	(_candidates findIf {
		[_vehicle,_unit,-1,_action,localize (_x param [6,'']),0,FALSE,FALSE,'',1,'Action',TRUE] call QS_fnc_clientInGameUIAction
	}) < 0
};
if (_roles isEqualTo []) exitWith {
	systemChat 'No available seat can be boarded without bypassing another vehicle restriction.';
};
private _oldSeat = _seats select {(_x # 4) isEqualTo _unit};
if (_inside) then {moveOut _unit;};
if !(_unit moveInAny [_vehicle,_roles,TRUE]) then {
	if (_inside && {_oldSeat isNotEqualTo []}) then {
		_unit moveInAny [_vehicle,[(_oldSeat # 0) # 5],TRUE];
	};
	systemChat 'The selected seat is no longer available. Try again.';
};
