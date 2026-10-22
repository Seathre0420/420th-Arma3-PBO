/* Client presentation and cancellation; the captured vehicle never follows the cursor. */
params ['_vehicle'];
private _unit = QS_player;
if (missionNamespace getVariable ['QS_repairing_vehicle',FALSE] ||
    {uiNamespace getVariable ['QS_client_progressVisualization_active',FALSE]} ||
    {!([_unit,_vehicle] call QS_fnc_engineerRefuelEligible)} || {fuel _vehicle >= 1}) exitWith {};
missionNamespace setVariable ['QS_repairing_vehicle',TRUE];
private _token = format ['%1:%2',clientOwner,diag_tickTime];
private _vehicleOwner = owner _vehicle;
_unit setVariable ['QS_engineerRefuel_request',_token,TRUE];
_unit setVariable ['QS_engineerRefuel_status',[_token,'waiting']];
private _cancel = _unit addAction ['Cancel Refuel',{
    (_this # 0) setVariable ['QS_engineerRefuel_request','',TRUE];
},nil,99,TRUE,TRUE,'','TRUE'];
[_vehicle,_unit,_token] remoteExecCall ['QS_fnc_engineerRefuelOwner',_vehicle];
private _deadline = diag_tickTime + 8;
private _state = [_token,'waiting'];
private _result = 'cancelled';
private _nextDisplay = -1;
while {(_unit getVariable ['QS_engineerRefuel_request','']) == _token &&
    {owner _vehicle == _vehicleOwner} &&
    {[_unit,_vehicle] call QS_fnc_engineerRefuelEligible}} do {
    private _received = _unit getVariable ['QS_engineerRefuel_status',[]];
    // Ignore delayed replies belonging to a previous session.
    if ((_received param [0,'']) == _token) then {_state = _received;};
    private _phase = _state param [1,'waiting'];
    if (_phase in ['complete','busy','cancelled']) exitWith {_result = _phase;};
    if (_phase == 'waiting' && {diag_tickTime > _deadline}) exitWith {_result = 'timeout';};
    if (diag_tickTime >= _nextDisplay) then {
        private _text = 'Requesting refuel...';
        if (_phase == 'running') then {
            _text = format ['Refueling: %1%2 — %3 seconds remaining',floor ((_state param [3,0]) * 100),'%',ceil (_state param [2,0])];
        };
        50 cutText [_text,'PLAIN DOWN',0.1];
        _nextDisplay = diag_tickTime + 0.5;
    };
    uiSleep 0.1;
};
_unit setVariable ['QS_engineerRefuel_request','',TRUE];
_unit removeAction _cancel;
missionNamespace setVariable ['QS_repairing_vehicle',FALSE];
private _text = switch _result do {
    case 'complete': {'Vehicle fully refueled.'};
    case 'busy': {'Another engineer is refueling this vehicle.'};
    case 'timeout': {'Refueling could not start. Try again.'};
    default {'Refueling cancelled. Fuel retained.'};
};
50 cutText [_text,'PLAIN DOWN',0.3];
