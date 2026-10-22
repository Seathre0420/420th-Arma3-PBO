/* Run server-locally in a standalone editor mission with the repository's
 * Apex_framework.terrain folder available. Refuses a running framework. */
if (!isServer || {!isNil 'QS_megaDefense_core'}) exitWith {
    diag_log '[Defend rotation test] Use a standalone server/editor mission';
};
private _source = loadFile 'Apex_framework.terrain/code/functions/fn_core.sqf';
private _block = {
    params ['_name'];
    private _start = '// DEFEND_ROTATION_' + _name + '_BEGIN';
    private _end = '// DEFEND_ROTATION_' + _name + '_END';
    private _offset = (_source find _start) + count _start;
    _source select [_offset,(_source find _end) - _offset]
};
private _advance = compile (['ADVANCE'] call _block);
private _decision = compile ((['DECISION'] call _block) + '; _normalAO_shouldDefend');
private _savedCount = missionNamespace getVariable ['QS_defendCount',0];
private _savedForce = missionNamespace getVariable ['QS_forceDefend',0];
private _hadCount = !isNil 'QS_defendCount';
private _hadForce = !isNil 'QS_forceDefend';
private _failures = 0;
private _assert = {
    params ['_ok','_label'];
    if (!_ok) then {_failures = _failures + 1;};
    diag_log format ['[Defend rotation test] %1: %2',['FAIL','PASS'] select _ok,_label];
};
private _run = compile ((['INIT'] call _block) + '
    private _ao = [0,0,0,0,0,0,0,0,1];
    private _normalAO_manualDefense = FALSE;
    private _normalAO_staffDefense = FALSE;
    call _advance;
    [call _decision,"First AO eligible"] call _assert;
    missionNamespace setVariable ["QS_defendCount",1];
    call _advance;
    [!(call _decision),"Actual Defend blocks next AO"] call _assert;
    _normalAO_staffDefense = TRUE;
    [call _decision,"Staff queue/force bypass"] call _assert;
    _normalAO_staffDefense = FALSE;
    _normalAO_manualDefense = TRUE;
    [call _decision,"Mega Defense bypass"] call _assert;
    _normalAO_manualDefense = FALSE;
    {
        missionNamespace setVariable ["QS_forceDefend",_x];
        [call _decision,format ["Positive force %1 bypass",_x]] call _assert;
    } forEach [1,2];
    missionNamespace setVariable ["QS_forceDefend",0];
    call _advance;
    [call _decision,"Intervening AO restores eligibility"] call _assert;
    call _advance;
    [call _decision,"Rejected Defend attempt does not block"] call _assert;
    missionNamespace setVariable ["QS_defendCount",2];
    call _advance;
    [!(call _decision),"Staff/failed Defend also blocks following AO"] call _assert;
    _ao set [8,0];
    call _advance;
    [!(call _decision),"AO disabled flag remains effective"] call _assert;
    _normalAO_staffDefense = TRUE;
    [call _decision,"Staff bypasses disabled AO flag"] call _assert;
');
missionNamespace setVariable ['QS_defendCount',0];
missionNamespace setVariable ['QS_forceDefend',0];
call _run;
missionNamespace setVariable ['QS_defendCount',if (_hadCount) then {_savedCount} else {nil}];
missionNamespace setVariable ['QS_forceDefend',if (_hadForce) then {_savedForce} else {nil}];
diag_log format ['[Defend rotation test] COMPLETE failures=%1',_failures];
