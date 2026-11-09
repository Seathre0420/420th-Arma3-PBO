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
deleteVehicle _charge;
{deleteVehicle _x} forEach [_a,_b,_enemy,_vehicle];
deleteGroup _west; deleteGroup _east;
diag_log format ['FF engine policy tests: %1 failures',_failures];
