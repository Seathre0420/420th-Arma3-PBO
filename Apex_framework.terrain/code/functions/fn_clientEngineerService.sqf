params ['_vehicle','_mode'];
private _unit = QS_player;
if (missionNamespace getVariable ['QS_repairing_vehicle',FALSE] ||
    {uiNamespace getVariable ['QS_client_progressVisualization_active',FALSE]}) exitWith {};
private _reason = [_unit,_vehicle,_mode] call QS_fnc_engineerServiceReason;
if (_reason != '') exitWith {50 cutText [_reason,'PLAIN DOWN',0.3];};
private _serial = (localNamespace getVariable ['QS_engineerService_serial',0]) + 1;
localNamespace setVariable ['QS_engineerService_serial',_serial];
private _token = format ['%1:%2:%3',clientOwner,diag_tickTime,_serial];
// The server resolves vehicle ownership; owner returns zero on clients.
private _target = 2;
private _active = [_vehicle,_unit,_token,_mode,_target,['requesting','',0,0,diag_tickTime]];
localNamespace setVariable ['QS_engineerService_client',_active];
localNamespace setVariable ['QS_engineerService_cancel',FALSE];
missionNamespace setVariable ['QS_repairing_vehicle',TRUE];
private _label = ['repair','refuel'] select (_mode == 'refuel');
private _cancel = _unit addAction [(['Cancel Repair','Cancel Refuel'] select (_mode == 'refuel')),{localNamespace setVariable ['QS_engineerService_cancel',TRUE];},nil,99,TRUE,TRUE,'','TRUE'];
50 cutText [format ['Requesting %1...',_label],'PLAIN DOWN',0.1];
diag_log format ['[QS ENGINEER] request %1 %2 target=%3',_mode,_token,_target];
['begin',_vehicle,_unit,_token,_mode] remoteExecCall ['QS_fnc_engineerServiceServer',_target];
private _accepted = FALSE;
private _ready = FALSE;
private _stopping = FALSE;
private _stopAt = 0;
private _stopReason = '';
private _heartbeat = -1;
private _displayAt = -1;
private _result = 'cancelled';
while {TRUE} do {
    private _state = _active # 5;
    _state params ['_phase','_message','_remaining','_level','_receivedAt'];
    if (_phase in ['complete','cancelled','rejected']) exitWith {_result = _phase; _reason = _message;};
    if (_phase in ['accepted','running']) then {_accepted = TRUE;};
    private _now = diag_tickTime;
    if (!_stopping) then {
        _stopReason = [_unit,_vehicle,_mode] call QS_fnc_engineerServiceReason;
        if (localNamespace getVariable ['QS_engineerService_cancel',FALSE]) then {_stopReason = 'Cancelled by player.';};
        if (_now - _receivedAt > 8) then {_stopReason = 'No response from service server.';};
        if (_stopReason != '') then {
            _stopping = TRUE; _stopAt = _now;
            ['cancel',_vehicle,_unit,_token,_mode] remoteExecCall ['QS_fnc_engineerServiceServer',_target];
            diag_log format ['[QS ENGINEER] stop %1 %2 reason=%3',_mode,_token,_stopReason];
        };
    };
    if (_stopping && {_now - _stopAt > 9}) exitWith {_result = 'failed'; _reason = _stopReason;};
    if (!_stopping && {_accepted}) then {
        if (!_ready) then {
            ['ready',_vehicle,_unit,_token,_mode] remoteExecCall ['QS_fnc_engineerServiceServer',_target];
            _ready = TRUE;
        };
        if (_now >= _heartbeat) then {
            ['ping',_vehicle,_unit,_token,_mode] remoteExecCall ['QS_fnc_engineerServiceServer',_target];
            _heartbeat = _now + 1;
        };
    };
    if (_now >= _displayAt) then {
        private _text = format ['Requesting %1...',_label];
        if (_phase == 'running') then {_text = format ['%1: %2%3 — %4 seconds remaining',(['Repairing','Refueling'] select (_mode == 'refuel')),floor (_level * 100),'%',ceil _remaining];};
        if (_stopping) then {_text = format ['Stopping %1... %2',_label,_stopReason];};
        50 cutText [_text,'PLAIN DOWN',0.1];
        _displayAt = _now + 0.5;
    };
    uiSleep 0.1;
};
_unit removeAction _cancel;
localNamespace setVariable ['QS_engineerService_client',[]];
missionNamespace setVariable ['QS_repairing_vehicle',FALSE];
private _text = format ['Could not start %1: %2',_label,_reason];
if (_accepted) then {_text = format ['%1 stopped. %2 %3',_label,_reason,(['Repair progress retained.','Added fuel retained.'] select (_mode == 'refuel'))];};
if (_result == 'complete') then {_text = ['Vehicle fully repaired.','Vehicle fully refueled.'] select (_mode == 'refuel');};
50 cutText [_text,'PLAIN DOWN',0.3];
