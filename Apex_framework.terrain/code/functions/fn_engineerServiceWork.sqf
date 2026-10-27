params ['_session','_key'];
_session params ['_vehicle','_unit','_token','_mode','_caller'];
private _hitEH = _vehicle addEventHandler ['Hit',{(_this # 0) setVariable ['QS_engineerService_hit',TRUE];}];
_vehicle setVariable ['QS_engineerService_hit',FALSE];
private _last = diag_tickTime;
private _notify = -1;
private _phase = 'cancelled';
private _reason = '';
private _remaining = 0;
private _level = 0;
private _done = FALSE;
while {!_done} do {
    private _now = diag_tickTime;
    private _dt = ((_now - _last) max 0) min 0.5;
    _last = _now;
    // Check cancellation and ownership in the same unscheduled block as the
    // mutation, so a new hit cannot interleave the damage read/write.
    isNil {
        if ((_session # 6) == 'cancelled') exitWith {_reason = _session # 7; _done = TRUE;};
        if (!local _vehicle) exitWith {_reason = 'Vehicle ownership changed. Try again.'; _done = TRUE;};
        if (isNull _unit || {!isPlayer _unit}) exitWith {_reason = 'Engineer disconnected.'; _done = TRUE;};
        if (_now > (_session # 5)) exitWith {_reason = 'Service connection expired.'; _done = TRUE;};
        _reason = [_unit,_vehicle,_mode] call QS_fnc_engineerServiceReason;
        if (_reason != '') exitWith {_done = TRUE;};
        if (_vehicle getVariable ['QS_engineerService_hit',FALSE]) exitWith {_reason = 'Vehicle took a hit.'; _done = TRUE;};
        if ((_session # 6) != 'running') exitWith {};
        if (_mode == 'refuel') then {
            private _current = fuel _vehicle;
            private _next = (_current + (0.01 * _dt)) min 1;
            if (_next > _current) then {_vehicle setFuel _next;};
            _remaining = (1 - _next) * 100;
            _level = _next;
            if (_next >= 1) then {_phase = 'complete'; _done = TRUE;};
        } else {
            private _hits = (getAllHitPointsDamage _vehicle) param [2,[]];
            private _severity = damage _vehicle;
            {_severity = _severity max _x;} forEach _hits;
            _remaining = 120 * ((_severity max 0) ^ 1.5);
            _level = 1 - _severity;
            if (_remaining <= 0.05) exitWith {
                _vehicle setDamage 0;
                _remaining = 0; _level = 1; _phase = 'complete'; _done = TRUE;
            };
            private _hullWork = 120 * (((damage _vehicle) max 0) ^ 1.5);
            _vehicle setDamage [((((_hullWork - _dt) max 0) / 120) ^ (2/3)),FALSE];
            {
                private _next = ((((120 * ((_x max 0) ^ 1.5) - _dt) max 0) / 120) ^ (2/3));
                _vehicle setHitIndex [_forEachIndex,_next,FALSE];
            } forEach _hits;
        };
    };
    if (!_done && {(_session # 6) == 'running'} && {_now >= _notify}) then {
        [_session,'running','',_remaining,_level] call QS_fnc_engineerServiceReply;
        _notify = _now + 0.5;
    };
    if (!_done) then {sleep 0.1;};
};
_vehicle removeEventHandler ['Hit',_hitEH];
if ((_vehicle getVariable ['QS_engineerService_lock','']) == _key) then {
    _vehicle setVariable ['QS_engineerService_lock',''];
    _vehicle setVariable ['QS_engineerService_hit',nil];
};
if ((_unit getVariable ['QS_engineerService_lock','']) == _key) then {_unit setVariable ['QS_engineerService_lock',''];};
(localNamespace getVariable ['QS_engineerService_sessions',createHashMap]) deleteAt _key;
diag_log format ['[QS ENGINEER] finish %1 %2 state=%3 reason=%4',_mode,_key,_phase,_reason];
if (!isNull _unit) then {[_session,_phase,_reason,_remaining,_level] call QS_fnc_engineerServiceReply;};
