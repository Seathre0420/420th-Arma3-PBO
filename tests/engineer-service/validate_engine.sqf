/* Disposable MULTIPLAYER mission only. Target must already need the requested
   service. Invokes the production client/owner RPCs and changes that vehicle.
   ['refuel',cursorObject] execVM 'tests\engineer-service\validate_engine.sqf'; */
params [['_mode','refuel'],['_vehicle',cursorObject]];
if (!hasInterface || {!isMultiplayer}) exitWith {diag_log '[QS ENGINEER TEST] Multiplayer player client required';};
private _reason = [player,_vehicle,_mode] call QS_fnc_engineerServiceReason;
if (_reason != '') exitWith {diag_log format ['[QS ENGINEER TEST] Ineligible: %1',_reason];};
private _sample = {
    params ['_vehicle','_mode'];
    if (_mode == 'refuel') exitWith {1 - fuel _vehicle};
    private _value = damage _vehicle;
    {_value = _value max _x;} forEach ((getAllHitPointsDamage _vehicle) param [2,[]]);
    _value
};
private _initial = [_vehicle,_mode] call _sample;
if (_initial < 0.15) exitWith {diag_log '[QS ENGINEER TEST] Prepare at least 15% missing fuel/damage first';};
private _initialFuel = fuel _vehicle;
private _script = [_vehicle,_mode] spawn QS_fnc_clientEngineerService;
private _deadline = diag_tickTime + 12;
waitUntil {sleep 0.1; scriptDone _script || {diag_tickTime > _deadline} || {(((localNamespace getVariable ['QS_engineerService_client',[]]) param [5,[]]) param [0,'']) == 'running'}};
private _running = (((localNamespace getVariable ['QS_engineerService_client',[]]) param [5,[]]) param [0,'']) == 'running';
if (!_running) exitWith {localNamespace setVariable ['QS_engineerService_cancel',TRUE]; diag_log '[QS ENGINEER TEST] FAIL: no running acknowledgement; inspect both RPTs';};
sleep 2;
localNamespace setVariable ['QS_engineerService_cancel',TRUE];
_deadline = diag_tickTime + 12;
waitUntil {sleep 0.1; scriptDone _script || {diag_tickTime > _deadline}};
private _after = [_vehicle,_mode] call _sample;
sleep 2;
private _stable = [_vehicle,_mode] call _sample;
private _passed = scriptDone _script && {_after < _initial} && {abs (_stable - _after) < 0.003};
if (_mode == 'repair') then {_passed = _passed && {abs (fuel _vehicle - _initialFuel) < 0.001};};
diag_log format ['[QS ENGINEER TEST] %1 mode=%2 vehicle=%3 initial=%4 afterCancel=%5 later=%6', ['FAIL','PASS'] select _passed,_mode,netId _vehicle,_initial,_after,_stable];
// Restart exercises owner lock cleanup and continuation from current state.
if (_passed) then {
    _script = [_vehicle,_mode] spawn QS_fnc_clientEngineerService;
    _deadline = diag_tickTime + 300;
    waitUntil {sleep 0.2; scriptDone _script || {diag_tickTime > _deadline}};
    if (!scriptDone _script) then {localNamespace setVariable ['QS_engineerService_cancel',TRUE];};
    diag_log format ['[QS ENGINEER TEST] completion=%1 remaining=%2',scriptDone _script && {([_vehicle,_mode] call _sample) < 0.001},[_vehicle,_mode] call _sample];
};
