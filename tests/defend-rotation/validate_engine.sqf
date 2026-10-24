/* Run server-locally in a standalone editor mission with the repository's
 * Apex_framework.terrain folder available. Refuses a running framework. */
if (!isServer || {!isNil 'QS_megaDefense_core'}) exitWith {
    diag_log '[Defend rotation test] Use a standalone server/editor mission';
};
private _coreSource = loadFile 'Apex_framework.terrain/code/functions/fn_core.sqf';
private _defendSource = loadFile 'Apex_framework.terrain/code/functions/fn_aoDefend.sqf';
private _block = {
    params ['_source','_name'];
    private _start = '// DEFEND_ROTATION_' + _name + '_BEGIN';
    private _end = '// DEFEND_ROTATION_' + _name + '_END';
    private _offset = (_source find _start) + count _start;
    _source select [_offset,(_source find _end) - _offset]
};
private _init = [_coreSource,'INIT'] call _block;
private _consume = compile (([_coreSource,'CONSUME'] call _block) + '; _normalAO_defendBlocked');
private _decision = compile (([_coreSource,'DECISION'] call _block) + '; _normalAO_shouldDefend');
private _arm = compile ([_defendSource,'ARM'] call _block);
private _savedCount = missionNamespace getVariable ['QS_defendCount',0];
private _savedForce = missionNamespace getVariable ['QS_forceDefend',0];
private _savedBlock = missionNamespace getVariable ['QS_defend_blockNext',FALSE];
private _hadCount = !isNil 'QS_defendCount';
private _hadForce = !isNil 'QS_forceDefend';
private _hadBlock = !isNil 'QS_defend_blockNext';
private _failures = 0;
private _assert = {
    params ['_ok','_label'];
    if (!_ok) then {_failures = _failures + 1;};
    diag_log format ['[Defend rotation test] %1: %2',['FAIL','PASS'] select _ok,_label];
};
private _run = compile (_init + '
    private _ao = [0,0,0,0,0,0,0,0,1];
    private _normalAO_manualDefense = FALSE;
    private _normalAO_staffDefense = FALSE;
    private _normalAO_defendBlocked = FALSE;
    private _finishAO = {
        _normalAO_defendBlocked = call _consume;
        call _decision
    };
    [call _finishAO,"First AO eligible"] call _assert;
    missionNamespace setVariable ["QS_defendCount",99];
    [call _finishAO,"Counter changes do not affect rotation"] call _assert;
    call _arm;
    [missionNamespace getVariable "QS_defend_blockNext","Actual admission arms block"] call _assert;
    [!(call _finishAO),"Next AO blocked"] call _assert;
    [!(missionNamespace getVariable "QS_defend_blockNext"),"Blocked ending consumes flag"] call _assert;
    [call _finishAO,"Following AO eligible again"] call _assert;
    [call _finishAO,"Rejected attempt without admission does not arm"] call _assert;
    {
        call _arm;
        _normalAO_staffDefense = _x in ["STAFF_QUEUE","STAFF_FORCE"];
        _normalAO_manualDefense = _x isEqualTo "MEGA_DEFENSE";
        missionNamespace setVariable ["QS_forceDefend",switch _x do {case "FORCE_1": {1}; case "FORCE_2": {2}; default {0};}];
        [call _finishAO,format ["%1 bypasses consumed restriction",_x]] call _assert;
        [!(missionNamespace getVariable "QS_defend_blockNext"),"Flag cleared before override admission"] call _assert;
        call _arm;
        _normalAO_staffDefense = FALSE;
        _normalAO_manualDefense = FALSE;
        missionNamespace setVariable ["QS_forceDefend",0];
        [!(call _finishAO),format ["%1 admission protects following AO",_x]] call _assert;
        [call _finishAO,"Intervening AO restores eligibility"] call _assert;
    } forEach ["STAFF_QUEUE","STAFF_FORCE","MEGA_DEFENSE","FORCE_1","FORCE_2"];
    call _arm;
    _ao set [8,0];
    [!(call _finishAO),"Disabled AO cannot automatically Defend"] call _assert;
    _ao set [8,1];
    [call _finishAO,"Disabled AO consumes intervening block"] call _assert;
    call _arm;
    [!(call _finishAO),"Cycled AO uses the same ending and consumes block"] call _assert;
    [call _finishAO,"AO after cycle is eligible"] call _assert;
    call _arm;
    missionNamespace setVariable ["QS_defendCount",0];
    [!(call _finishAO),"Failed Defend or counter reset does not erase block"] call _assert;
    [call _finishAO,"Cancelled request without admission does not arm"] call _assert;
    _ao set [8,0];
    _normalAO_staffDefense = TRUE;
    [call _finishAO,"Staff bypasses disabled AO flag"] call _assert;
    call _arm;
    call (compile _init);
    [!(missionNamespace getVariable "QS_defend_blockNext"),"Mission initialization resets pending block"] call _assert;
');
missionNamespace setVariable ['QS_defendCount',0];
missionNamespace setVariable ['QS_forceDefend',0];
call _run;
missionNamespace setVariable ['QS_defendCount',if (_hadCount) then {_savedCount} else {nil}];
missionNamespace setVariable ['QS_forceDefend',if (_hadForce) then {_savedForce} else {nil}];
missionNamespace setVariable ['QS_defend_blockNext',if (_hadBlock) then {_savedBlock} else {nil}];
diag_log format ['[Defend rotation test] COMPLETE failures=%1',_failures];
