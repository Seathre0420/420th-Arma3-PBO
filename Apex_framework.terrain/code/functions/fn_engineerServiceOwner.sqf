/* All control messages use this ordered RPC, never public object variables.
   Session layout: vehicle, unit, token, mode, caller, expiry, phase, reason. */
if (!isRemoteExecuted || {isRemoteExecutedJIP} || {remoteExecutedOwner != 2}) exitWith {};
params ['_op','_vehicle','_unit','_token','_mode','_caller'];
if (!(_op in ['begin','ready','ping','cancel']) || {!(_mode in ['repair','refuel'])} ||
    {!(_token isEqualType '')} || {_token == ''} || {isNull _unit} ||
    {_caller < 2}) exitWith {
    diag_log '[QS ENGINEER] Rejected invalid or unauthenticated control request';
};
private _sessions = localNamespace getVariable ['QS_engineerService_sessions',createHashMap];
localNamespace setVariable ['QS_engineerService_sessions',_sessions];
private _key = format ['%1/%2',_caller,_token];
private _session = _sessions getOrDefault [_key,[]];
if (_op != 'begin') exitWith {
    if (_session isEqualTo []) exitWith {};
    if ((_session # 0) != _vehicle || {(_session # 1) != _unit} || {(_session # 3) != _mode}) exitWith {};
    if (_op == 'cancel') then {
        _session set [6,'cancelled']; _session set [7,'Cancelled by player.'];
    } else {
        if (diag_tickTime <= (_session # 5) && {(_session # 6) in ['accepted','running']}) then {
            _session set [5,diag_tickTime + 8];
            if (_op == 'ready') then {_session set [6,'running'];};
        };
    };
};
if (_session isNotEqualTo []) exitWith {[_session,_session # 6,_session # 7] call QS_fnc_engineerServiceReply;};
_session = [_vehicle,_unit,_token,_mode,_caller,diag_tickTime + 8,'accepted',''];
private _reason = if (!local _vehicle) then {'Vehicle ownership changed. Try again.'} else {[_unit,_vehicle,_mode] call QS_fnc_engineerServiceReason};
if (_reason == '' && {(_vehicle getVariable ['QS_engineerService_lock','']) != ''}) then {_reason = 'Another engineer is servicing this vehicle.';};
if (_reason == '' && {(_unit getVariable ['QS_engineerService_lock','']) != ''}) then {_reason = 'Engineer already has an active service session.';};
if (_reason != '') exitWith {
    diag_log format ['[QS ENGINEER] reject %1 %2 owner=%3 reason=%4',_mode,_key,clientOwner,_reason];
    [_session,'rejected',_reason] call QS_fnc_engineerServiceReply;
};
_sessions set [_key,_session];
_vehicle setVariable ['QS_engineerService_lock',_key];
_unit setVariable ['QS_engineerService_lock',_key];
diag_log format ['[QS ENGINEER] accept %1 %2 owner=%3 vehicle=%4',_mode,_key,clientOwner,netId _vehicle];
[_session,'accepted'] call QS_fnc_engineerServiceReply;
// No mutation until the client acknowledges acceptance with "ready".
[_session,_key] spawn QS_fnc_engineerServiceWork;
