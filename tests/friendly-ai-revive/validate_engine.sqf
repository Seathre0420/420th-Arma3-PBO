/* Run on the server in a disposable mission with the updated functions loaded.
 * State-machine checks only; use the README for actual combat/network checks.
 */
if (!isServer) exitWith {};
[] spawn {
    private _failures = 0;
    private _check = {
        params ['_condition','_label'];
        if (!_condition) then {_failures = _failures + 1;};
        diag_log format ['[AI revive test] %1: %2',_label,['FAIL','PASS'] select _condition];
    };
    private _group = createGroup [WEST,TRUE];
    private _a = _group createUnit ['B_Soldier_F',[100,100,0],[],0,'NONE'];
    private _b = _group createUnit ['B_Soldier_F',[105,100,0],[],0,'NONE'];
    _b setCaptive TRUE;
    ['DOWN',_a] call TGC_fnc_friendlyAICasualty;
    ['DOWN',_b] call TGC_fnc_friendlyAICasualty;
    uiSleep 0.2;
    [alive _a && {lifeState _a isEqualTo 'INCAPACITATED'},'alive and unconscious'] call _check;
    [!isDamageAllowed _a && {captive _a},'protected casualty'] call _check;
    private _deadline = (_a getVariable 'TGC_aiCasualty') # 0;
    [abs (_deadline - (_a getVariable 'QS_revive_timeDown') - 300) < 0.1,'five minute deadline'] call _check;
    ['DOWN',_a] call TGC_fnc_friendlyAICasualty;
    [((_a getVariable 'TGC_aiCasualty') # 0) isEqualTo _deadline,'repeated down does not reset timer'] call _check;
    ['REVIVE',_a] call TGC_fnc_friendlyAICasualty;
    [alive _a && {lifeState _a in ['HEALTHY','INJURED']} && {damage _a isEqualTo 0},'revive heals'] call _check;
    [isDamageAllowed _a && {!captive _a} && {isNil {_a getVariable 'TGC_aiCasualty'}},'revive clears state'] call _check;
    [lifeState _b isEqualTo 'INCAPACITATED','independent casualty'] call _check;
    ['REVIVE',_b] call TGC_fnc_friendlyAICasualty;
    [captive _b,'original captive state restored'] call _check;
    ['DOWN',_a] call TGC_fnc_friendlyAICasualty;
    [(_a getVariable 'TGC_aiCasualty') isNotEqualTo [],'second episode starts'] call _check;
    private _state = +(_a getVariable 'TGC_aiCasualty');
    _state set [0,serverTime - 1];
    _a setVariable ['TGC_aiCasualty',_state,TRUE];
    ['TICK',_a] call TGC_fnc_friendlyAICasualty;
    [!alive _a,'expired casualty dies'] call _check;
    ['TICK',_a] call TGC_fnc_friendlyAICasualty;
    [isNil {_a getVariable 'TGC_aiCasualty'},'dead casualty tracking cleared'] call _check;
    ['DOWN',_b] call TGC_fnc_friendlyAICasualty;
    _state = +(_b getVariable 'TGC_aiCasualty');
    _state set [0,serverTime - 1];
    _b setVariable ['TGC_aiCasualty',_state,TRUE];
    ['REVIVE',_b] call TGC_fnc_friendlyAICasualty;
    [!alive _b,'revive after deadline cannot rescue casualty'] call _check;
    {deleteVehicle _x;} forEach [_a,_b];
    deleteGroup _group;
    diag_log format ['[AI revive test] Complete: %1 failures',_failures];
};
