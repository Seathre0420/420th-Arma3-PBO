/* Validate and reserve the vehicle on its owner before spawning any work. */
params ['_vehicle','_unit','_token'];
if (!isRemoteExecuted || {isRemoteExecutedJIP} || {!local _vehicle} ||
    {remoteExecutedOwner != owner _unit} ||
    {!([_unit,_vehicle] call QS_fnc_engineerRefuelEligible)} ||
    {(_unit getVariable ['QS_engineerRefuel_request','']) != _token} ||
    {(_unit getVariable ['QS_engineerRepair_request','']) != ''}) exitWith {};
if ((_vehicle getVariable ['QS_engineerRefuel_lock','']) != '') exitWith {
    _unit setVariable ['QS_engineerRefuel_status',[_token,'busy'],owner _unit];
};
_vehicle setVariable ['QS_engineerRefuel_lock',_token];
[_vehicle,_unit,_token] spawn {
    params ['_vehicle','_unit','_token'];
    private _hitEH = _vehicle addEventHandler ['Hit',{
        (_this # 0) setVariable ['QS_engineerRefuel_hit',TRUE];
    }];
    _vehicle setVariable ['QS_engineerRefuel_hit',FALSE];
    private _status = 'cancelled';
    private _last = diag_tickTime;
    private _notify = -1;
    // One percentage point of tank capacity per second, independent of tank size.
    private _rate = 0.01;
    while {local _vehicle && {[_unit,_vehicle] call QS_fnc_engineerRefuelEligible} &&
        {(_unit getVariable ['QS_engineerRefuel_request','']) == _token} &&
        {!(_vehicle getVariable ['QS_engineerRefuel_hit',FALSE])}} do {
        private _now = diag_tickTime;
        private _dt = (_now - _last) min 0.5;
        _last = _now;
        private _finished = FALSE;
        // Read current fuel and apply the increment atomically. Never restore
        // an initial snapshot: external fuel changes and cancellation persist.
        isNil {
            if (!local _vehicle || {_vehicle getVariable ['QS_engineerRefuel_hit',FALSE]} ||
                {(_unit getVariable ['QS_engineerRefuel_request','']) != _token} ||
                {!([_unit,_vehicle] call QS_fnc_engineerRefuelEligible)}) exitWith {};
            private _current = fuel _vehicle;
            private _next = (_current + (_rate * _dt)) min 1;
            if (_next > _current) then {_vehicle setFuel _next;};
            if (_next >= 1) exitWith {_finished = TRUE; _status = 'complete';};
            if (_now >= _notify) then {
                _unit setVariable ['QS_engineerRefuel_status',[_token,'running',(1 - _next) / _rate,_next],owner _unit];
                _notify = _now + 0.5;
            };
        };
        if (_finished) exitWith {};
        sleep 0.1;
    };
    _vehicle removeEventHandler ['Hit',_hitEH];
    _vehicle setVariable ['QS_engineerRefuel_lock',''];
    _vehicle setVariable ['QS_engineerRefuel_hit',nil];
    if (!isNull _unit) then {_unit setVariable ['QS_engineerRefuel_status',[_token,_status],owner _unit];};
};
