/* Run on a player client in a disposable mission after time > 120.
   Extract the production decision before its RPC/UI side effects. All scenarios
   run without scheduler suspension, preventing clientCore from changing fixtures.
   Copy this harness into the test mission and execVM it from the client console. */
if (!hasInterface || {time <= 120}) exitWith {
	diag_log 'QS HEARTBEAT TEST requires a player client after mission time 120';
};
private _source = preprocessFileLineNumbers 'code\functions\fn_clientHeartbeat.sqf';
private _decisionEnd = _source find 'if (!_shouldReport) exitWith {};';
private _core = preprocessFileLineNumbers 'code\functions\fn_clientCore.sqf';
private _refreshStart = _core find 'private _fn_refreshHeartbeat = {';
private _refreshEnd = _core find '[_timeNow] call _fn_refreshHeartbeat;';
if ((_decisionEnd < 0) || {_refreshStart < 0} || {_refreshEnd < _refreshStart}) exitWith {
	diag_log 'QS HEARTBEAT TEST FAIL production extraction markers missing';
};
private _checkHeartbeat = compile ((_source select [0,_decisionEnd]) + '[_shouldReport,_shouldEnd]');
private _refresh = call compile ((_core select [_refreshStart,_refreshEnd - _refreshStart]) + '_fn_refreshHeartbeat');
private _failures = [];
private _check = {
	params ['_condition','_description'];
	if (!_condition) then {_failures pushBack _description;};
};
isNil {
	private _saved = ['QS_client_heartbeat','QS_client_heartbeatFailure','QS_heartAttacks'] apply {
		[_x,isNil {missionNamespace getVariable _x},missionNamespace getVariable [_x,FALSE]]
	};
	missionNamespace setVariable ['QS_heartAttacks',0,FALSE];
	missionNamespace setVariable ['QS_client_heartbeatFailure',[],FALSE];
	[time] call _refresh;
	[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],'healthy heartbeat'] call _check;
	missionNamespace setVariable ['QS_client_heartbeat',time - 61,FALSE];
	[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],'first failure only warns'] call _check;
	private _first = +(missionNamespace getVariable 'QS_client_heartbeatFailure');
	[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],'immediate duplicate waits'] call _check;
	[(missionNamespace getVariable 'QS_client_heartbeatFailure') isEqualTo _first,'duplicate preserves start'] call _check;
	[time] call _refresh;
	[(missionNamespace getVariable 'QS_client_heartbeatFailure') isEqualTo [],'loop recovery clears failure'] call _check;
	missionNamespace setVariable ['QS_client_heartbeat',time - 61,FALSE];
	[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],'new stall gets fresh grace'] call _check;
	missionNamespace setVariable ['QS_client_heartbeatFailure',[diag_tickTime - 61,time - 61,FALSE],FALSE];
	[(call _checkHeartbeat) isEqualTo [TRUE,TRUE],'persistent stall confirms'] call _check;
	[(missionNamespace getVariable 'QS_heartAttacks') isEqualTo 1,'counter increments on confirmation'] call _check;
	[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],'confirmed duplicate suppressed'] call _check;
	[(missionNamespace getVariable 'QS_heartAttacks') isEqualTo 1,'duplicate does not increment counter'] call _check;
	[time] call _refresh;
	missionNamespace setVariable ['QS_client_heartbeat',time + 61,FALSE];
	[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],'future heartbeat gets grace'] call _check;
	missionNamespace setVariable ['QS_client_heartbeatFailure',[diag_tickTime - 61,time + 61,FALSE],FALSE];
	missionNamespace setVariable ['QS_heartAttacks',3,FALSE];
	[(call _checkHeartbeat) isEqualTo [TRUE,FALSE],'existing limit reports without ending'] call _check;
	[(missionNamespace getVariable 'QS_heartAttacks') isEqualTo 3,'limit preserves counter'] call _check;
	{
		missionNamespace setVariable ['QS_client_heartbeat',time + _x,FALSE];
		[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],format ['tolerance boundary %1',_x]] call _check;
		[(missionNamespace getVariable 'QS_client_heartbeatFailure') isEqualTo [],'healthy check clears failure'] call _check;
	} forEach [-60,60];
	missionNamespace setVariable ['QS_client_heartbeat',nil];
	[(call _checkHeartbeat) isEqualTo [FALSE,FALSE],'missing heartbeat gets grace'] call _check;
	[(missionNamespace getVariable 'QS_client_heartbeatFailure') isNotEqualTo [],'missing heartbeat recorded'] call _check;
	{
		_x params ['_name','_missing','_value'];
		if (_missing) then {missionNamespace setVariable [_name,nil];} else {
			missionNamespace setVariable [_name,_value,_name isEqualTo 'QS_heartAttacks'];
		};
	} forEach _saved;
};
diag_log format ['QS HEARTBEAT TEST failures=%1 details=%2',count _failures,_failures];
