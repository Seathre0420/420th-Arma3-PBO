/*
 * Owner-local casualty lifecycle. The public state travels with the unit;
 * serverTime deadlines survive ownership changes and are never extended by
 * transport. Only combat casualties created here are managed by this system.
 */
params ['_mode','_unit'];
if (isNull _unit || {!local _unit} || {isPlayer _unit}) exitWith {FALSE};
private _state = _unit getVariable ['TGC_aiCasualty',[]];
if (_mode isEqualTo 'DOWN') exitWith {
    if (_state isNotEqualTo [] || {!alive _unit} ||
        {lifeState _unit isEqualTo 'INCAPACITATED'}) exitWith {FALSE};
    private _now = serverTime;
    private _deadline = _now + (getMissionConfigValue ['ReviveBleedOutDelay',300]);
    _unit setVariable ['TGC_aiCasualty',[_deadline,captive _unit,
        _unit getVariable ['QS_RD_draggable',FALSE]],TRUE];
    _unit allowDamage FALSE;
    _unit setCaptive TRUE;
    _unit setUnconscious TRUE;
    _unit setVariable ['QS_revive_timeDown',_now,TRUE];
    _unit setVariable ['QS_revive_timeBleedout',_deadline,TRUE];
    _unit setVariable ['QS_RD_draggable',TRUE,TRUE];
    // Defer setDamage until the HandleDamage callback has returned its cap.
    [_unit,_deadline] spawn {
        params ['_unit','_deadline'];
        if (local _unit && {alive _unit} &&
            {((_unit getVariable ['TGC_aiCasualty',[]]) param [0,-1]) isEqualTo _deadline}) then {
            _unit setDamage [0.25,TRUE];
        };
    };
    TRUE
};
if (_state isEqualTo []) exitWith {FALSE};
private _expired = serverTime >= (_state # 0);
if (_mode isEqualTo 'TICK' && {alive _unit} && {!_expired}) exitWith {
    _unit allowDamage FALSE;
    TRUE
};
if (_mode in ['TICK','REVIVE','CLEAR']) exitWith {
    _unit setVariable ['TGC_aiCasualty',nil,TRUE];
    _unit setVariable ['QS_revive_timeDown',nil,TRUE];
    _unit setVariable ['QS_revive_timeBleedout',nil,TRUE];
    _unit setVariable ['QS_RD_draggable',_state # 2,TRUE];
    _unit setCaptive (_state # 1);
    if (alive _unit) then {
        if (_expired && {_mode isNotEqualTo 'CLEAR'}) then {
            _unit setDamage [1,TRUE];
        } else {
            if (_mode isEqualTo 'REVIVE') then {
                _unit setDamage [0,TRUE];
                _unit setBleedingRemaining 0;
                _unit setUnconscious FALSE;
            };
        };
    };
    _unit allowDamage TRUE;
    TRUE
};
FALSE
