/* Empty string means eligible. Used on both the client and vehicle owner. */
params ['_unit','_vehicle','_mode'];
if (isNull _unit || {isNull _vehicle}) exitWith {'Player or vehicle no longer exists.'};
if (!alive _unit || {!isPlayer _unit} || {!((lifeState _unit) in ['HEALTHY','INJURED'])}) exitWith {'Engineer is unavailable.'};
if (!isNull (objectParent _unit)) exitWith {'Get out of the vehicle first.'};
if (!(_unit getUnitTrait 'engineer')) exitWith {'Engineer role required.'};
if (!alive _vehicle) exitWith {'Vehicle is destroyed.'};
if ((['LandVehicle','Air','Ship'] findIf {_vehicle isKindOf _x}) == -1) exitWith {'Unsupported vehicle.'};
private _point = _vehicle worldToModel (getPosATL _unit);
private _box = boundingBoxReal _vehicle;
private _nearest = +_point;
for '_axis' from 0 to 2 do {
    _nearest set [_axis,((_point # _axis) max ((_box # 0) # _axis)) min ((_box # 1) # _axis)];
};
if ((_point vectorDistance _nearest) >= 5) exitWith {'Move within five metres of the vehicle.'};
if (isEngineOn _vehicle) exitWith {'Turn the vehicle engine off.'};
if (vectorMagnitude (velocity _vehicle) >= 0.3) exitWith {'Vehicle must be stationary.'};
if (((crew _vehicle) findIf {alive _x && {(side _x) in ([_unit] call QS_fnc_enemySides)}}) != -1) exitWith {'Enemy occupants prevent servicing.'};
private _disabled = format ['QS_services_%1_disabled',_mode];
if (_vehicle getVariable [_disabled,FALSE] || {missionNamespace getVariable [_disabled,FALSE]}) exitWith {'This service is disabled.'};
if (_mode == 'repair') exitWith {
    if (!isNil {_vehicle getVariable 'QS_RD_noRepair'}) exitWith {'Repair is restricted for this vehicle.'};
    if ((((items _unit) apply {toLowerANSI _x}) findAny (missionNamespace getVariable ['QS_core_classNames_itemToolKits',['toolkit']])) == -1) exitWith {'Toolkit required.'};
    ''
};
''
