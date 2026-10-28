/* Canonical seat identity and access group, including empty seats and FFV. */
params ['_vehicle'];
(fullCrew [_vehicle,'',TRUE]) apply {
	_x params ['_unit','_role','_cargo','_turret','_ffv'];
	_role = toLowerANSI _role;
	private _group = if (_role isEqualTo 'driver') then {'driver'} else {
		if (_role isEqualTo 'commander') then {'commander'} else {
			if ((_role isEqualTo 'cargo') || {_ffv}) then {'passenger'} else {'gunner'}
		}
	};
	private _kind = if (_role isEqualTo 'driver') then {'DRIVER'} else {
		if (_role isEqualTo 'cargo') then {'CARGO'} else {'TURRET'}
	};
	private _identity = if (_kind isEqualTo 'CARGO') then {_cargo} else {_turret};
	private _locked = switch _kind do {
		case 'DRIVER': {lockedDriver _vehicle};
		case 'CARGO': {_vehicle lockedCargo _cargo};
		default {_vehicle lockedTurret _turret};
	};
	private _engineRole = if (_ffv) then {'TURRET'} else {toUpperANSI _role};
	[_group,_kind,_identity,_locked,_unit,_engineRole]
}
