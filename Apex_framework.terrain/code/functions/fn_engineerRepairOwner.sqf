/* Executed atomically on the vehicle owner before starting the scheduled loop. */
params ['_vehicle','_unit','_token'];
if (!isRemoteExecuted || {isRemoteExecutedJIP} || {!local _vehicle} ||
    {remoteExecutedOwner != owner _unit} || {!([_unit,_vehicle] call QS_fnc_engineerRepairEligible)} ||
    {(_unit getVariable ['QS_engineerRepair_request','']) != _token}) exitWith {};
if ((_vehicle getVariable ['QS_engineerRepair_lock','']) != '') exitWith {
    _unit setVariable ['QS_engineerRepair_status',[_token,'busy'],owner _unit];
};
_vehicle setVariable ['QS_engineerRepair_lock',_token];
[_vehicle,_unit,_token] spawn {
    params ['_vehicle','_unit','_token'];
    private _hitEH = _vehicle addEventHandler ['Hit',{
        (_this # 0) setVariable ['QS_engineerRepair_hit',TRUE];
    }];
    _vehicle setVariable ['QS_engineerRepair_hit',FALSE];
    private _status = 'cancelled';
    private _last = diag_tickTime;
    private _notify = -1;
    while {local _vehicle && {[_unit,_vehicle] call QS_fnc_engineerRepairEligible} &&
        {(_unit getVariable ['QS_engineerRepair_request','']) == _token} &&
        {!(_vehicle getVariable ['QS_engineerRepair_hit',FALSE])}} do {
        private _now = diag_tickTime;
        // Cap elapsed time: a scheduler stall must not cause a large repair jump.
        private _dt = (_now - _last) min 0.5;
        _last = _now;
        private _finished = FALSE;
        // isNil CODE executes unscheduled: no new hit can interleave the
        // read/modify/write of overall and component damage.
        isNil {
        if (!local _vehicle || {_vehicle getVariable ['QS_engineerRepair_hit',FALSE]} ||
            {(_unit getVariable ['QS_engineerRepair_request','']) != _token} ||
            {!([_unit,_vehicle] call QS_fnc_engineerRepairEligible)}) exitWith {};
        private _hits = (getAllHitPointsDamage _vehicle) param [2,[]];
        private _severity = damage _vehicle;
        {_severity = _severity max _x;} forEach _hits;
        private _remaining = 240 * ((_severity max 0) ^ 1.5);
        if (_remaining <= 0.05) exitWith {
            _vehicle setDamage 0;
            _status = 'complete';
            _finished = TRUE;
        };
        // Work(d) = 240*d^1.5. Subtract work from CURRENT damage, never a snapshot.
        // setDamage changes hitpoints too; restore each independently below in
        // the same unsuspended update, including pristine components.
        private _hullWork = 240 * (((damage _vehicle) max 0) ^ 1.5);
        _vehicle setDamage [((((_hullWork - _dt) max 0) / 240) ^ (2/3)),FALSE];
        if (_hits isNotEqualTo []) then {
            {
                private _next = ((((240 * ((_x max 0) ^ 1.5) - _dt) max 0) / 240) ^ (2/3));
                _vehicle setHitIndex [_forEachIndex,_next,FALSE];
            } forEach _hits;
        };
        };
        if (_finished) exitWith {};
        if (_now >= _notify) then {
            _unit setVariable ['QS_engineerRepair_status',[_token,'running',_remaining],owner _unit];
            _notify = _now + 0.5;
        };
        sleep 0.1;
    };
    _vehicle removeEventHandler ['Hit',_hitEH];
    _vehicle setVariable ['QS_engineerRepair_lock',''];
    _vehicle setVariable ['QS_engineerRepair_hit',nil];
    if (!isNull _unit) then {_unit setVariable ['QS_engineerRepair_status',[_token,_status],owner _unit];};
};
