/* Shared checks for engineer refueling. No toolkit or fuel source required. */
params ['_unit','_vehicle'];
if (isNull _unit || {isNull _vehicle} ||
    {(['LandVehicle','Air','Ship'] findIf {_vehicle isKindOf _x}) == -1}) exitWith {FALSE};
private _point = _vehicle worldToModel (getPosATL _unit);
private _box = boundingBoxReal _vehicle;
private _nearest = +_point;
for '_axis' from 0 to 2 do {
    _nearest set [_axis,((_point # _axis) max ((_box # 0) # _axis)) min ((_box # 1) # _axis)];
};
alive _unit && {isPlayer _unit} && {alive _vehicle} &&
{(lifeState _unit) in ['HEALTHY','INJURED']} &&
{isNull (objectParent _unit)} && {_unit getUnitTrait 'engineer'} &&
{(_point vectorDistance _nearest) < 5} &&
{!isEngineOn _vehicle} && {vectorMagnitude (velocity _vehicle) < 0.3} &&
{!(_vehicle getVariable ['QS_services_refuel_disabled',FALSE])} &&
{!(missionNamespace getVariable ['QS_services_refuel_disabled',FALSE])} &&
{((crew _vehicle) findIf {alive _x && {(side _x) in ([_unit] call QS_fnc_enemySides)}}) == -1}
