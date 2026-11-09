/*
Function: TGC_fnc_addFriendlyAIHandlers

Description:
    Attach friendly-AI protection object handlers to a unit. This function is
    called on every machine by TGC_fnc_initFriendlyAIProtection, so the
    handlers are present wherever the unit is local now or later.

Parameters:
    Object unit:
        Infantry or virtual UAV crew to protect when it is friendly AI.

Author:
    thegamecracks

*/
params [["_unit", objNull, [objNull]]];
[_unit] call TGC_fnc_addDamageProtection;

if (
    (isNull _unit) ||
    {
        !(_unit isKindOf "CAManBase") &&
        {!(_unit isKindOf "B_UAV_AI")} &&
        {!(_unit isKindOf "O_UAV_AI")} &&
        {!(_unit isKindOf "I_UAV_AI")} &&
        {!(_unit isKindOf "C_UAV_AI_F")}
    }
) exitWith {};

private _existingDamageEH = _unit getVariable ["TGC_friendlyAI_damageEH", -1];
private _existingDamageEHInfo = if (_existingDamageEH >= 0) then {
    _unit getEventHandlerInfo ["HandleDamage", _existingDamageEH]
} else {
    []
};
if (
    (_existingDamageEHInfo param [0, false]) &&
    {_existingDamageEHInfo param [1, false]}
) exitWith {};

// Only the last numeric HandleDamage return is honored. If another handler was
// added after ours, move this protection back to the end of the handler list.
if (_existingDamageEHInfo param [0, false]) then {
    _unit removeEventHandler ["HandleDamage", _existingDamageEH];
};

private _damageEH = _unit addEventHandler ["HandleDamage", {
    call {
        params ["_unit", "", "_damage", "_source", "", "_hitIndex", "_instigator"];

        if (!local _unit) exitWith {};
        if (!isPlayer _unit && {(_unit getVariable ['TGC_aiCasualty',[]]) isNotEqualTo []}) exitWith {
            (if (_hitIndex >= 0) then {_unit getHitIndex _hitIndex} else {damage _unit}) min 0.89
        };
        if !([_unit] call TGC_fnc_isFriendlyAI) exitWith {};

        private _oldDamage = if (_hitIndex >= 0) then {
            _unit getHitIndex _hitIndex
        } else {
            damage _unit
        };

        if (_this call TGC_fnc_isFriendlyFire) exitWith {_oldDamage};

        // Recruited AI uses the same configured on-foot enemy-damage multiplier
        // as players. Keep it in this handler instead of a separate later
        // numeric return that would override the player-damage rejection above.
        private _reduced = (
            (_unit getVariable ["QS_unit_isRecruited", false]) &&
            {(call (missionNamespace getVariable ["QS_missionConfig_reducedDamage", {1}])) isEqualTo 1}
        );
        if (_reduced) then {
            _damage = _oldDamage + ((_damage - _oldDamage) * 0.333);
        };
        // Match the player's vital-hit threshold; virtual UAV operators and
        // already-scripted unconscious mission patients retain their behavior.
        if (_unit isKindOf 'CAManBase' &&
            {(['B_UAV_AI','O_UAV_AI','I_UAV_AI','C_UAV_AI_F'] findIf {_unit isKindOf _x}) < 0} && {alive _unit} &&
            {lifeState _unit in ['HEALTHY','INJURED']} && {isDamageAllowed _unit}) exitWith {
            if (_hitIndex in [-1,2,7] && {_damage > 0.89}) then {
                ['DOWN',_unit] call TGC_fnc_friendlyAICasualty;
            };
            _damage min 0.89
        };
        // Outside combat infantry, preserve the original handler's undefined
        // return unless recruited damage reduction actually changed the result.
        if (_reduced) exitWith {_damage};
    };
}];

_unit setVariable ["TGC_friendlyAI_damageEH", _damageEH];
