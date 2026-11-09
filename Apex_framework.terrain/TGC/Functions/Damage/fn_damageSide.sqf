/* Resolve allegiance independently of the machine's player object. */
params [['_entity',objNull]];
if (isNull _entity) exitWith {sideUnknown};
if (_entity isKindOf 'CAManBase') exitWith {side group _entity};
private _commander = effectiveCommander _entity;
private _side = if (isNull _commander) then {
    _entity getVariable ['TGC_damage_side',_entity getVariable ['TGC_vehicle_side',sideUnknown]]
} else {side group _commander};
if (_side in [sideUnknown,sideEnemy]) then {
    private _index = getNumber ((configOf _entity) >> 'side');
    _side = [EAST,WEST,RESISTANCE,CIVILIAN,sideUnknown] param [_index,sideUnknown];
};
if (local _entity && {!(_side in [sideUnknown,sideEnemy])} &&
    {_side isNotEqualTo (_entity getVariable ['TGC_damage_side',sideUnknown])}) then {
    _entity setVariable ['TGC_damage_side',_side,true];
};
_side
