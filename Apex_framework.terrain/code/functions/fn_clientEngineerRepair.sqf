params ['_vehicle'];
private _unit = QS_player;
if (missionNamespace getVariable ['QS_repairing_vehicle',FALSE] ||
    {uiNamespace getVariable ['QS_client_progressVisualization_active',FALSE]} ||
    {!([_unit,_vehicle] call QS_fnc_engineerRepairEligible)}) exitWith {};
missionNamespace setVariable ['QS_repairing_vehicle',TRUE];
private _token = format ['%1:%2',clientOwner,diag_tickTime];
_unit setVariable ['QS_engineerRepair_request',_token,TRUE];
_unit setVariable ['QS_engineerRepair_status',[_token,'waiting']];
private _cancel = _unit addAction ['Cancel Repair',{
    (_this # 0) setVariable ['QS_engineerRepair_request','',TRUE];
},nil,99,TRUE,TRUE,'','TRUE'];
[_vehicle,_unit,_token] remoteExecCall ['QS_fnc_engineerRepairOwner',_vehicle];
private _deadline = diag_tickTime + 8;
waitUntil {
    uiSleep 0.1;
    ((_unit getVariable ['QS_engineerRepair_status',[]]) param [1,'']) != 'waiting' ||
    {diag_tickTime > _deadline} || {(_unit getVariable ['QS_engineerRepair_request','']) != _token}
};
private _state = _unit getVariable ['QS_engineerRepair_status',[]];
if ((_state param [1,'']) == 'running') then {
    _unit playActionNow 'PutDown';
    [
        'Repairing vehicle',((_state # 2) + 5) max 0.1,0,
        [[_unit],{
            params ['_progress','_args'];
            private _remaining = ((_args # 0) getVariable ['QS_engineerRepair_status',[]]) param [2,0];
            uiNamespace setVariable ['QS_client_progressVisualization_text',format ['Repairing vehicle — %1 seconds remaining',ceil _remaining]];
        }],
        [[_unit,_vehicle,_token],{
            params ['_unit','_vehicle','_token'];
            (_unit getVariable ['QS_engineerRepair_request','']) != _token ||
            {((_unit getVariable ['QS_engineerRepair_status',[]]) param [1,'']) != 'running'} ||
            {!([_unit,_vehicle] call QS_fnc_engineerRepairEligible)}
        }],
        [[_unit,_vehicle,_token],{
            // The display's estimate is not permission to finish the repair.
            // If the owner is running slowly, keep cancellation available.
            params ['_unit','_vehicle','_token'];
            waitUntil {
                uiSleep 0.1;
                ((_unit getVariable ['QS_engineerRepair_status',[]]) param [1,'']) != 'running' ||
                {(_unit getVariable ['QS_engineerRepair_request','']) != _token} ||
                {!([_unit,_vehicle] call QS_fnc_engineerRepairEligible)}
            };
        }],[[],{FALSE}]
    ] call QS_fnc_clientProgressVisualization;
};
_unit setVariable ['QS_engineerRepair_request','',TRUE];
_unit removeAction _cancel;
missionNamespace setVariable ['QS_repairing_vehicle',FALSE];
50 cutText [(['Repair cancelled. Progress saved.','Vehicle fully repaired.'] select (((_unit getVariable ['QS_engineerRepair_status',[]]) param [1,'']) == 'complete')),'PLAIN DOWN',0.3];
