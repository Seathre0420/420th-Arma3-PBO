/* Every machine installs; only the owner returns numeric damage. */
params ['_entity'];
if (isNull _entity || {!(_entity isKindOf 'AllVehicles')}) exitWith {};
private _firedID = _entity getVariable ['TGC_damage_firedEH',-1];
if (_firedID < 0 || {!((_entity getEventHandlerInfo ['Fired',_firedID]) param [0,false])}) then {
    _entity setVariable ['TGC_damage_firedEH',_entity addEventHandler ['Fired',{_this call TGC_fnc_damageFired}]];
    _entity addEventHandler ['EpeContactStart',{
        params ['_entity','_other'];
        if (local _entity) then {
            _entity setVariable ['TGC_damage_contact',[[[_other] call TGC_fnc_damageActor] call TGC_fnc_damageSide,diag_tickTime + 0.25]];
        };
    }];
    _entity addEventHandler ['Local',{params ['_entity','_local']; if (_local) then {[_entity] call TGC_fnc_addDamageProtection}}];
};
[_entity] call TGC_fnc_damageSide;
private _id = _entity getVariable ['TGC_damage_EH',-1];
private _info = if (_id < 0) then {[]} else {_entity getEventHandlerInfo ['HandleDamage',_id]};
if ((_info param [0,false]) && {_info param [1,false]}) exitWith {};
if (_info param [0,false]) then {_entity removeEventHandler ['HandleDamage',_id]};
_entity setVariable ['TGC_damage_EH',_entity addEventHandler ['HandleDamage',{
    if (local (_this # 0) && {_this call TGC_fnc_isFriendlyFire}) exitWith {
        if ((_this # 5) >= 0) then {(_this # 0) getHitIndex (_this # 5)} else {damage (_this # 0)}
    };
}]];
