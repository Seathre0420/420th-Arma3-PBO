params ['_launcher','_weapon','','','_ammo','','_projectile',['_gunner',objNull]];
if (!local _launcher) exitWith {};
private _actor = [if (isNull _gunner) then {_launcher} else {_gunner}] call TGC_fnc_damageActor;
private _side = [_actor] call TGC_fnc_damageSide;
if (!isNull _projectile) then {_projectile setVariable ['TGC_damage_provenance',[_side],true]};
if (_weapon isEqualTo 'Put' && {!isNull _projectile}) then {
    private _charges = (_launcher getVariable ['TGC_damage_charges',[]]) select {!isNull (_x # 2)};
    _charges pushBack [_ammo,_side,_projectile];
    _launcher setVariable ['TGC_damage_charges',_charges,true];
};
private _records = (_launcher getVariable ['TGC_damage_shots',[]]) select {serverTime <= (_x # 2)};
private _index = _records findIf {(_x # 0) isEqualTo _ammo && {(_x # 1) isEqualTo _side}};
private _publish = _index < 0;
if (_index < 0) then {_records pushBack [_ammo,_side,serverTime + 300]} else {
    if (((_records # _index) # 2) < serverTime + 290) then {(_records # _index) set [2,serverTime + 300]; _publish = true};
};
if (_publish) then {_launcher setVariable ['TGC_damage_shots',_records,true]};
if (!isNull _projectile && {local _projectile} && {_projectile isKindOf 'MissileBase'}) then {
    [_projectile,_side,_ammo] spawn {
        params ['_projectile','_side','_ammo'];
        while {!isNull _projectile} do {
            private _target = missileTarget _projectile;
            if (!isNull _target) then {
                private _incoming = (_target getVariable ['TGC_damage_incoming',[]]) select {serverTime <= (_x # 2)};
                _incoming = _incoming select {(_x param [3,objNull]) isNotEqualTo _projectile};
                _incoming pushBack [_ammo,_side,serverTime + 0.75,_projectile];
                _target setVariable ['TGC_damage_incoming',_incoming,true];
            };
            uiSleep 0.25;
        };
    };
};
