/* Run on server in a disposable MP mission. Tests use real SQF policy/API.
Combat/physics replication scenarios in README still require actual firing.
*/
if (!isServer) exitWith {};
private _failures = 0;
private _assert = {params ['_ok','_message']; if (!_ok) then {_failures = _failures + 1; diag_log ('FAIL FF: ' + _message)}};
private _west = createGroup [WEST,true];
private _east = createGroup [EAST,true];
private _a = _west createUnit ['B_Soldier_F',[100,100,0],[],0,'NONE'];
private _b = _west createUnit ['B_Soldier_F',[110,100,0],[],0,'NONE'];
private _enemy = _east createUnit ['O_Soldier_F',[120,100,0],[],0,'NONE'];
private _vehicle = createVehicle ['B_Heli_Light_01_F',[140,100,0],[],0,'NONE'];
// Player multiplier regression: a fall can report the victim as source. It
// must exit before random combat injuries, even for an extreme damage value.
_a setVariable ['QS_inzone',[false,0,false]];
private _healthBeforeFall = getAllHitPointsDamage _a;
{
    private _fall = [_a,'',_x,_a,'',-1,objNull,'',false];
    [(_fall call QS_fnc_clientDamageModifier) isEqualTo 0,
        format ['self-source fall damage %1 is suppressed',_x]] call _assert;
    _fall set [6,_a];
    [(_fall call QS_fnc_clientDamageModifier) isEqualTo 0,
        'self-instigator fall is suppressed'] call _assert;
    _fall set [3,objNull]; _fall set [6,objNull];
    [(_fall call QS_fnc_clientDamageModifier) isEqualTo 0.025,
        'null-source fall retains original reduction'] call _assert;
} forEach [0.1,1,100];
[(getAllHitPointsDamage _a) isEqualTo _healthBeforeFall,
    'fall multiplier does not apply secondary combat injuries'] call _assert;
// Check immediately, before reconciliation or explicit installation can mask
// a broken EntityCreated callback (Object _this incorrectly indexed as Array).
private _createdFiredEH = _vehicle getVariable ['TGC_damage_firedEH',-1];
private _createdDamageEH = _vehicle getVariable ['TGC_damage_EH',-1];
[_createdFiredEH >= 0,'EntityCreated immediately installs projectile tracking'] call _assert;
[_createdDamageEH >= 0,'EntityCreated immediately installs damage protection'] call _assert;
if (_createdDamageEH >= 0) then {
    [(_vehicle getEventHandlerInfo ['HandleDamage',_createdDamageEH]) param [0,false],
        'creation installs a valid damage handler'] call _assert;
};
private _event = [_a,'',0.8,_b,'B_65x39_Caseless',-1,_b,'',true];
[(_event call TGC_fnc_damageDecision) # 0,'friendly infantry blocked'] call _assert;
_event set [3,_enemy]; _event set [6,_enemy];
[!((_event call TGC_fnc_damageDecision) # 0),'enemy infantry allowed'] call _assert;
_event set [0,_vehicle]; _event set [3,_b]; _event set [6,objNull];
[(_event call TGC_fnc_damageDecision) # 0,'empty aircraft missing instigator protected'] call _assert;
_vehicle setDamage 0.2;
private _before = damage _vehicle;
[!([_event,'setDamage',0.8] call TGC_fnc_applyCombatDamage),'friendly scripted damage refused'] call _assert;
[(damage _vehicle) isEqualTo _before,'blocked damage preserves existing damage'] call _assert;
_event set [3,_enemy]; _event set [6,_enemy];
[[_event,'setDamage',0.4] call TGC_fnc_applyCombatDamage,'hostile scripted damage accepted'] call _assert;
[(damage _vehicle) > _before,'hostile damage applied'] call _assert;
_event set [3,objNull]; _event set [6,objNull]; _event set [4,''];
[!((_event call TGC_fnc_damageDecision) # 0),'environment remains damageable'] call _assert;
_b setVariable ['TGC_damage_shots',[['testMissile',WEST,serverTime+30]]];
_event set [3,_b]; _event set [4,'testMissile'];
[(_event call TGC_fnc_damageDecision) # 0,'launch snapshot survives missing instigator'] call _assert;
[_vehicle] call TGC_fnc_addDamageProtection;
private _id = _vehicle getVariable 'TGC_damage_EH';
[_vehicle] call TGC_fnc_addDamageProtection;
[(_vehicle getVariable 'TGC_damage_EH') isEqualTo _id,'installation idempotent'] call _assert;
private _charge = createVehicle ['DemoCharge_Remote_Ammo',[150,100,0],[],0,'NONE'];
_charge setVariable ['TGC_damage_provenance',[WEST]];
_event set [3,_charge]; _event set [4,'DemoCharge_Remote_Ammo'];
[(_event call TGC_fnc_damageDecision) # 0,'placed-charge provenance protects'] call _assert;
_event set [3,objNull]; _event set [4,''];
_vehicle setVariable ['TGC_damage_contact',[WEST,diag_tickTime+1]];
[(_event call TGC_fnc_damageDecision) # 0,'recent friendly collision protects'] call _assert;
_vehicle setVariable ['TGC_damage_contact',[WEST,diag_tickTime-1]];
[!((_event call TGC_fnc_damageDecision) # 0),'expired collision does not grant immunity'] call _assert;
private _relationship = WEST getFriend EAST;
WEST setFriend [EAST,1];
_event set [3,_enemy]; _event set [6,_enemy]; _event set [4,'testBullet'];
[(_event call TGC_fnc_damageDecision) # 0,'allied different side protects'] call _assert;
WEST setFriend [EAST,_relationship];
// Concurrent missile deltas survive deletion, stale snapshots and expiry.
private _sampled = serverTime;
private _friendlyRow = [_vehicle,'testMissile',WEST,_sampled + 0.75,objNull,'test/friendly',_sampled];
private _hostileRow = [_vehicle,'testMissile',EAST,_sampled + 0.75,objNull,'test/hostile',_sampled];
[[_friendlyRow]] call TGC_fnc_damageMissileMerge;
[[_hostileRow]] call TGC_fnc_damageMissileMerge;
[(count (_vehicle getVariable ['TGC_damage_incoming',[]])) isEqualTo 2,
    'concurrent shooters merge even after projectile deletion'] call _assert;
_event set [3,objNull]; _event set [6,objNull]; _event set [4,'testMissile'];
[!((_event call TGC_fnc_damageDecision) # 0),'mixed same-ammo missiles remain ambiguous'] call _assert;
private _stale = +_friendlyRow;
_stale set [6,_sampled - 0.1]; _stale set [3,_sampled + 0.65];
[[_stale,_friendlyRow]] call TGC_fnc_damageMissileMerge;
private _merged = (_vehicle getVariable ['TGC_damage_incoming',[]]) select {(_x # 4) isEqualTo 'test/friendly'};
[((_merged # 0) # 2) isEqualTo (_sampled + 0.75),
    'stale snapshots and duplicates cannot replace or extend a deadline'] call _assert;
private _expired = +_hostileRow;
_expired set [5,'test/expired']; _expired set [3,serverTime - 0.1];
[[_expired]] call TGC_fnc_damageMissileMerge;
[((_vehicle getVariable ['TGC_damage_incoming',[]]) findIf {(_x # 4) isEqualTo 'test/expired'}) < 0,
    'expired delta is discarded'] call _assert;
_vehicle setVariable ['TGC_damage_incoming',[]];
[[_friendlyRow]] call TGC_fnc_damageMissileMerge;
[(_event call TGC_fnc_damageDecision) # 0,'owner-local missile fallback protects'] call _assert;
['REPORT',[[_vehicle,'testMissile',WEST,serverTime + 0.75,objNull,'2/unregistered',serverTime],['bad']]] call TGC_fnc_damageMissileSync;
[(count (_vehicle getVariable ['TGC_damage_incoming',[]])) isEqualTo 1,
    'unknown projectile and malformed reports rejected'] call _assert;
uiSleep 0.8;
[!((_event call TGC_fnc_damageDecision) # 0),'fallback expires without refresh'] call _assert;
_vehicle setVariable ['TGC_damage_incoming',[]];
// Exercise authoritative acceptance as well as the local merge primitive.
private _missile = createVehicle ['M_Titan_AA',[100,100,10000],[],0,'CAN_COLLIDE'];
private _launchKey = format ['2/test-%1',diag_tickTime];
private _reportAt = serverTime;
private _report = [_vehicle,typeOf _missile,WEST,_reportAt + 0.75,_missile,_launchKey,_reportAt];
['REPORT',[_report]] call TGC_fnc_damageMissileSync;
[((_vehicle getVariable ['TGC_damage_incoming',[]]) findIf {(_x # 4) isEqualTo _launchKey}) >= 0,
    'server accepts a live missile from its owner'] call _assert;
deleteVehicle _missile;
uiSleep 0.02;
private _afterDeletion = +_report;
_afterDeletion set [6,serverTime]; _afterDeletion set [3,serverTime + 0.75];
['REPORT',[_afterDeletion]] call TGC_fnc_damageMissileSync;
private _accepted = (_vehicle getVariable ['TGC_damage_incoming',[]]) select {(_x # 4) isEqualTo _launchKey};
[(count _accepted isEqualTo 1) && {((_accepted # 0) # 5) isEqualTo (_afterDeletion # 6)},
    'accepted launch survives projectile deletion for in-transit reports'] call _assert;
private _forged = +_afterDeletion;
_forged set [2,EAST]; _forged set [6,serverTime + 0.01]; _forged set [3,serverTime + 0.76];
['REPORT',[_forged]] call TGC_fnc_damageMissileSync;
private _protected = (_vehicle getVariable ['TGC_damage_incoming',[]]) select {(_x # 4) isEqualTo _launchKey};
[((_protected # 0) # 1) isEqualTo WEST,'accepted launch allegiance cannot be rewritten'] call _assert;
uiSleep 0.8;
['REPORT',[_report]] call TGC_fnc_damageMissileSync;
[((_vehicle getVariable ['TGC_damage_incoming',[]]) findIf {(_x # 4) isEqualTo _launchKey}) < 0,
    'expired cached launch cannot be revived by an old report'] call _assert;
// Regression: select must skip null/deleted targets without returning a Bool
// or dropping later live entries. Exercise the actual asynchronous cache worker.
private _deletedTarget = createVehicle ['B_Quadbike_01_F',[160,100,0],[],0,'NONE'];
isNil {
    _vehicle setVariable ['TGC_damage_incoming',[
        ['testMissile',WEST,serverTime + 3,objNull,'test/cleanup',serverTime]
    ]];
    localNamespace setVariable ['TGC_missile_targets',[objNull,_deletedTarget,_vehicle]];
    deleteVehicle _deletedTarget;
    ['REPORT',[]] call TGC_fnc_damageMissileSync;
};
private _cleanupDeadline = diag_tickTime + 2;
waitUntil {
    uiSleep 0.05;
    ((localNamespace getVariable ['TGC_missile_targets',[]]) isEqualTo [_vehicle]) ||
        {diag_tickTime >= _cleanupDeadline}
};
[(localNamespace getVariable ['TGC_missile_targets',FALSE]) isEqualTo [_vehicle],
    'cleanup skips null/deleted targets and retains later live targets as an array'] call _assert;
// The worker must also tolerate a cache already corrupted by the old code.
localNamespace setVariable ['TGC_missile_targets',FALSE];
uiSleep 0.35;
[(localNamespace getVariable ['TGC_missile_targets',FALSE]) isEqualType [],
    'cleanup recovers a previously corrupted target list'] call _assert;
localNamespace setVariable ['TGC_missile_targets',FALSE];
['REPORT',[]] call TGC_fnc_damageMissileSync;
[(localNamespace getVariable ['TGC_missile_targets',FALSE]) isEqualType [],
    'report ingestion recovers a previously corrupted target list'] call _assert;
_vehicle setVariable ['TGC_damage_incoming',[]];
deleteVehicle _charge;
{deleteVehicle _x} forEach [_a,_b,_enemy,_vehicle];
deleteGroup _west; deleteGroup _east;
diag_log format ['FF engine policy tests: %1 failures',_failures];
