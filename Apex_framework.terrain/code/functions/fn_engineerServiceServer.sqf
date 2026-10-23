/* Resolve ownership only on the server. Keep the chosen owner for cancellation
   and authenticate replies before forwarding them to the requesting player. */
if (!isServer || {!isRemoteExecuted} || {isRemoteExecutedJIP}) exitWith {};
params ['_op','_vehicle','_unit','_token','_mode',['_phase',''],['_reason',''],['_remaining',0],['_level',0]];
if (!(_token isEqualType '') || {_token == ''} || {!(_mode in ['repair','refuel'])}) exitWith {};
private _routes = localNamespace getVariable ['QS_engineerService_routes',createHashMap];
localNamespace setVariable ['QS_engineerService_routes',_routes];
private _route = _routes getOrDefault [_token,[]];
if (_op == 'status') exitWith {
    if (count _route != 7) exitWith {};
    _route params ['_expectedVehicle','_expectedUnit','_expectedToken','_expectedMode','_caller','_target'];
    if (remoteExecutedOwner != _target || {_vehicle != _expectedVehicle} ||
        {_unit != _expectedUnit} || {_mode != _expectedMode}) exitWith {};
    if (!(_phase in ['accepted','running','complete','cancelled','rejected'])) exitWith {};
    _route set [6,diag_tickTime + 12];
    [_vehicle,_unit,_token,_mode,_phase,_reason,_remaining,_level] remoteExecCall ['QS_fnc_engineerServiceResponse',_caller];
    if (_phase in ['complete','cancelled','rejected']) then {_routes deleteAt _token;};
};
if (!(_op in ['begin','ready','ping','cancel']) || {isNull _unit} ||
    {!isPlayer _unit} || {remoteExecutedOwner != owner _unit}) exitWith {
    diag_log '[QS ENGINEER] Server rejected unauthenticated control request';
};
private _caller = remoteExecutedOwner;
if (_op == 'begin' && {_route isEqualTo []}) then {
    private _target = owner _vehicle;
    if (_target >= 2) then {
        _route = [_vehicle,_unit,_token,_mode,_caller,_target,diag_tickTime + 12];
        _routes set [_token,_route];
        diag_log format ['[QS ENGINEER] route %1 %2 caller=%3 target=%4',_mode,_token,_caller,_target];
        // A disconnected or unavailable owner cannot leave a permanent route.
        [_route] spawn {
            params ['_route'];
            _route params ['_vehicle','_unit','_token','_mode','_caller','_target'];
            private _routes = localNamespace getVariable 'QS_engineerService_routes';
            waitUntil {sleep 1; !(_token in _routes) || {diag_tickTime > (_route # 6)}};
            if (_token in _routes) then {
                _routes deleteAt _token;
                ['cancel',_vehicle,_unit,_token,_mode,_caller] remoteExecCall ['QS_fnc_engineerServiceOwner',_target];
                [_vehicle,_unit,_token,_mode,'cancelled','Vehicle owner stopped responding.',0,0] remoteExecCall ['QS_fnc_engineerServiceResponse',_caller];
                diag_log format ['[QS ENGINEER] route expired %1 target=%2',_token,_target];
            };
        };
    };
};
if (_route isEqualTo []) exitWith {
    if (_op == 'begin') then {
        [_vehicle,_unit,_token,_mode,'rejected','Vehicle has no network owner.',0,0] remoteExecCall ['QS_fnc_engineerServiceResponse',_caller];
    };
};
if ((_route # 0) != _vehicle || {(_route # 1) != _unit} ||
    {(_route # 3) != _mode} || {(_route # 4) != _caller}) exitWith {};
private _target = _route # 5;
if (owner _vehicle != _target) then {_op = 'cancel';};
[_op,_vehicle,_unit,_token,_mode,_caller] remoteExecCall ['QS_fnc_engineerServiceOwner',_target];
