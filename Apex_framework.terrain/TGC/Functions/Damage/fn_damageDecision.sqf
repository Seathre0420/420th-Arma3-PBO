/* HandleDamage -> [blocked, reason, attacker side, victim side]. */
params ['_victim','','','_source',['_ammo',''],'',['_instigator',objNull]];
private _victimSide = [_victim] call TGC_fnc_damageSide;
private _attackSide = sideUnknown;
private _reason = 'actor';
private _record = _source getVariable ['TGC_damage_provenance',[]];
if (_record isNotEqualTo []) then {_attackSide = _record # 0; _reason = 'projectile'};
if (_attackSide isEqualTo sideUnknown && {_ammo isNotEqualTo ''}) then {
    private _recent = (_source getVariable ['TGC_damage_shots',[]]) select {(_x # 0) isEqualTo _ammo && {serverTime <= (_x # 2)}};
    _recent append ((_source getVariable ['TGC_damage_charges',[]]) select {(_x # 0) isEqualTo _ammo && {!isNull (_x # 2)}});
    private _sides = (_recent apply {_x # 1}) arrayIntersect (_recent apply {_x # 1});
    if (count _sides isEqualTo 1) then {_attackSide = _sides # 0; _reason = 'launch'};
};
if (_attackSide isEqualTo sideUnknown && {isNull _source} && {isNull _instigator} && {_ammo isNotEqualTo ''}) then {
    private _incoming = (_victim getVariable ['TGC_damage_incoming',[]]) select {(_x # 0) isEqualTo _ammo && {serverTime <= (_x # 2)}};
    private _sides = (_incoming apply {_x # 1}) arrayIntersect (_incoming apply {_x # 1});
    if (count _sides isEqualTo 1) then {_attackSide = _sides # 0; _reason = 'incoming'};
};
if (_attackSide isEqualTo sideUnknown) then {
    _attackSide = [[_instigator] call TGC_fnc_damageActor] call TGC_fnc_damageSide;
    if (_attackSide in [sideUnknown,sideEnemy] && {_source isNotEqualTo _victim}) then {
        _attackSide = [[_source] call TGC_fnc_damageActor] call TGC_fnc_damageSide;
    };
};
if (_ammo isEqualTo '' && {(isNull _source) || {_source isEqualTo _victim}}) then {
    private _contact = _victim getVariable ['TGC_damage_contact',[]];
    _attackSide = sideUnknown;
    if (count _contact isEqualTo 2 && {diag_tickTime <= (_contact # 1)}) then {_attackSide = _contact # 0; _reason = 'collision'};
};
private _known = !(_victimSide in [sideUnknown,sideEnemy]) && {!(_attackSide in [sideUnknown,sideEnemy])};
private _blocked = _known && {(_victimSide isEqualTo _attackSide) || {(_victimSide getFriend _attackSide) >= 0.6}};
if (!_known && {_ammo isNotEqualTo ''} && {local _victim} &&
    {diag_tickTime > (_victim getVariable ['TGC_damage_logAfter',-1])}) then {
    _victim setVariable ['TGC_damage_logAfter',diag_tickTime + 10];
    diag_log format ['TGC damage unresolved: victim=%1 source=%2 instigator=%3 ammo=%4',typeOf _victim,typeOf _source,typeOf _instigator,_ammo];
};
[_blocked,_reason,_attackSide,_victimSide]
