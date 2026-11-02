/* Client confirmation of a protected carry placement. Keep the lease until
   the owner confirms completion; Draw3D must not mutate a pending object. */
params ['_cargo','_position','_vectors',['_mode','PLACE'],['_attachment',[]]];
if ((uiNamespace getVariable ['QS_cargoPlacement_pending',[]]) isNotEqualTo []) exitWith {};
private _state = _cargo getVariable ['QS_cargoMove_state',[]];
if (_state isEqualTo []) exitWith {};
private _token = _state # 0;
private _revision = (_state param [10,0]) + 1;
private _pending = [_cargo,_token,_revision];
uiNamespace setVariable ['QS_cargoPlacement_pending',_pending];
// Rejected requests do not advance the owner's revision. Do not consume the
// previous rejection immediately when retrying that revision remotely.
_cargo setVariable ['QS_cargoMove_result',nil,FALSE];
private _request = [_mode,_cargo,_position,_vectors,_attachment,QS_player,_token,0,_revision];
diag_log format ['[CARGO MOVE] Request mode=%1 cargo=%2 local=%3 owner=%4 client=%5 token=%6 revision=%7',
    _mode,_cargo,local _cargo,owner _cargo,clientOwner,_token,_revision];
if (local _cargo) then {
    if !(_request call QS_fnc_cargoMove) then {
        _cargo setVariable ['QS_cargoMove_result',[_token,_revision,'REJECTED'],FALSE];
    };
} else {
    // Authenticate the initiating player once at the server before routing.
    _request remoteExecCall ['QS_fnc_cargoMove',2,FALSE];
};
private _deadline = diag_tickTime + 10;
waitUntil {
    uiSleep 0.05;
    private _reply = _cargo getVariable ['QS_cargoMove_result',[]];
    isNull _cargo || {(uiNamespace getVariable ['QS_cargoPlacement_pending',[]]) isNotEqualTo _pending} ||
    {(_reply param [0,[]]) isEqualTo _token && {(_reply param [1,-1]) isEqualTo _revision}} ||
    {diag_tickTime > _deadline}
};
if ((uiNamespace getVariable ['QS_cargoPlacement_pending',[]]) isNotEqualTo _pending) exitWith {};
uiNamespace setVariable ['QS_cargoPlacement_pending',[]];
private _reply = _cargo getVariable ['QS_cargoMove_result',[]];
private _done = (_reply param [0,[]]) isEqualTo _token && {(_reply param [1,-1]) isEqualTo _revision};
private _current = _cargo getVariable ['QS_cargoMove_state',[]];
private _failureText = ['STR_QS_Text_372','STR_QS_Text_116'] select (_mode isEqualTo 'LOAD');
if (_done && {(_reply # 2) in ['PLACED','LOADED','RECOVERED']}) then {
    uiNamespace setVariable ['QS_cargoPlacement_committing',TRUE];
    missionNamespace setVariable ['QS_targetBoundingBox_placementMode',FALSE,FALSE];
    if ((_reply # 2) isEqualTo 'LOADED') then {
        50 cutText [format ['%1 %3 %2',getText ((configOf _cargo) >> 'displayName'),
            getText ((configOf (_attachment # 0)) >> 'displayName'),localize 'STR_QS_Text_114'],'PLAIN DOWN',0.5];
    };
    if ((_reply # 2) isEqualTo 'RECOVERED') then {
        50 cutText [localize _failureText,'PLAIN DOWN',0.5];
    };
} else {
    if (isNull _cargo || {_current isEqualTo []}) then {
        uiNamespace setVariable ['QS_cargoPlacement_committing',TRUE];
        missionNamespace setVariable ['QS_targetBoundingBox_placementMode',FALSE,FALSE];
    };
    50 cutText [localize (if (_done && {(_reply # 2) isEqualTo 'BLOCKED'}) then {'STR_QS_Text_120'} else {_failureText}),'PLAIN DOWN',0.5];
    diag_log format ['[CARGO MOVE] Placement not completed: %1 token=%2 revision=%3 reply=%4',_cargo,_token,_revision,_reply];
};
