params [['_entity',objNull]];
if (isNull _entity) exitWith {objNull};
private _result = objNull;
{
    private _owner = _x getVariable ['bis_fnc_moduleRemoteControl_owner',objNull];
    if (isPlayer _owner) exitWith {_result = _owner};
    if (isPlayer _x) exitWith {_result = _x};
} forEach ([_entity] + crew (vehicle _entity));
if (!isNull _result) exitWith {_result};
private _v = vehicle _entity;
if (unitIsUAV _v) then {
    private _control = UAVControl _v;
    for '_i' from 0 to ((count _control)-2) step 2 do {
        if ((_control # (_i+1)) in ['DRIVER','GUNNER'] && {isPlayer (_control # _i)}) exitWith {_result = _control # _i};
    };
};
if (isNull _result) then {_result = _entity};
_result
