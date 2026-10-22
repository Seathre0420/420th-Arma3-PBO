/* Shared start/continuation checks; distance uses the vehicle surface. */
params ['_unit','_vehicle'];
if (isNull _unit || {isNull _vehicle}) exitWith {FALSE};
private _point = _vehicle worldToModel (getPosATL _unit);
private _box = boundingBoxReal _vehicle;
private _nearest = +_point;
for '_axis' from 0 to 2 do {
    _nearest set [_axis,((_point # _axis) max ((_box # 0) # _axis)) min ((_box # 1) # _axis)];
};
alive _unit && {isPlayer _unit} && {alive _vehicle} &&
{(lifeState _unit) in ['HEALTHY','INJURED']} &&
{isNull (objectParent _unit)} && {_unit getUnitTrait 'engineer'} &&
{(((items _unit) apply {toLowerANSI _x}) findAny QS_core_classNames_itemToolKits) != -1} &&
{(['LandVehicle','Air','Ship'] findIf {_vehicle isKindOf _x}) != -1} &&
{(_point vectorDistance _nearest) < 5} &&
{!isEngineOn _vehicle} && {vectorMagnitude (velocity _vehicle) < 0.3} &&
{isNil {_vehicle getVariable 'QS_RD_noRepair'}} &&
{!(_vehicle getVariable ['QS_services_repair_disabled',FALSE])} &&
{!(missionNamespace getVariable ['QS_services_repair_disabled',FALSE])} &&
{((crew _vehicle) findIf {alive _x && {(side _x) in ([_unit] call QS_fnc_enemySides)}}) == -1}
