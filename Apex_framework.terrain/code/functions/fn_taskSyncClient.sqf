/* Only server snapshots may create/remove synchronized tasks on this client. */
if (!hasInterface || {isNull player}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {};
params [['_records',[]]];
private _latest = 0;
{_latest = _latest max (_x # 1)} forEach _records;
if (_latest < (localNamespace getVariable ['QS_taskSync_latest',-1])) exitWith {};
localNamespace setVariable ['QS_taskSync_latest',_latest];
if (isRemoteExecuted) then {localNamespace setVariable ['QS_taskSync_snapshot',_records]};
private _seen = player getVariable ['QS_taskSync_seen',createHashMap];
localNamespace setVariable ['QS_taskSync_applying',TRUE];
// Delete first so a replacement can inherit the old selection in this same call.
{
    _x params ['_id','_revision','_generation','_data'];
    private _var = _id call BIS_fnc_taskVar;
    private _task = player getVariable [_var,taskNull];
    if (_data isEqualTo [] && {_revision >= (_seen getOrDefault [_id,-1])}) then {
        if (!isNull _task) then {
            if (_id isEqualTo 'QS_IA_TASK_AO_0' && {currentTask player isEqualTo _task}) then {
                localNamespace setVariable ['QS_taskSync_handoff',_generation];
            };
            player removeSimpleTask _task;
            player setVariable [_var,nil];
            player setVariable ['BIS_fnc_setTaskLocal_tasks',(player getVariable ['BIS_fnc_setTaskLocal_tasks',[]]) - [_id]];
        };
        player setVariable [_var,nil];
        player setVariable ['BIS_fnc_setTaskLocal_tasks',(player getVariable ['BIS_fnc_setTaskLocal_tasks',[]]) - [_id]];
        for '_i' from 0 to 11 do {missionNamespace setVariable [format ['%1.%2',_var,_i],nil]};
        _seen set [_id,_revision];
    };
} forEach _records;
{
    _x params ['_id','_revision','_generation','_data'];
    if (_data isNotEqualTo [] && {_revision >= (_seen getOrDefault [_id,-1])}) then {
        private _var = _id call BIS_fnc_taskVar;
        private _task = player getVariable [_var,taskNull];
        private _missing = isNull _task || {!(_task in simpleTasks player)};
        private _changed = _revision > (_seen getOrDefault [_id,-1]);
        call {
            private _selected = currentTask player;
            private _eligible = FALSE;
            {
                if (_x isEqualType TRUE && {_x}) then {_eligible = TRUE};
                if (_x isEqualType sideUnknown && {_x isEqualTo side group player}) then {_eligible = TRUE};
                if (_x isEqualType grpNull && {_x isEqualTo group player}) then {_eligible = TRUE};
                if (_x isEqualType '' && {missionNamespace getVariable [_x,objNull] isEqualTo player}) then {_eligible = TRUE};
                if (_x isEqualType [] && {player in _x}) then {_eligible = TRUE};
            } forEach (_data # 3);
            if (_eligible && {_missing || {_changed}}) then {
                for '_i' from 0 to 11 do {missionNamespace setVariable [format ['%1.%2',_var,_i],_data # _i]};
                if (_missing) then {player setVariable [_var,nil]};
                // Apply completion/failure updates, then preserve any still-active selection.
                [_id,FALSE,FALSE,[player],_changed] call BIS_fnc_setTaskLocal;
                if (!isNull _selected && {!taskCompleted _selected} && {_selected in simpleTasks player}) then {player setCurrentTask _selected};
                _task = player getVariable [_var,taskNull];
                if (_id isEqualTo 'QS_IA_TASK_DEFENDHQ' && {_missing}) then {
                    if ((localNamespace getVariable ['QS_taskSync_handoff',-1]) isEqualTo _generation || {isNull _selected} || {taskCompleted _selected}) then {
                        player setCurrentTask _task;
                        diag_log format ['[TaskSync] DEFEND_HANDOFF generation=%1',_generation];
                    };
                    localNamespace setVariable ['QS_taskSync_handoff',-1];
                };
                if (_missing) then {diag_log format ['[TaskSync] RESTORE id=%1 revision=%2 generation=%3',_id,_revision,_generation]};
            };
            if (!_eligible) then {
                if (!isNull _task) then {
                    player removeSimpleTask _task;
                    player setVariable [_var,nil];
                    player setVariable ['BIS_fnc_setTaskLocal_tasks',(player getVariable ['BIS_fnc_setTaskLocal_tasks',[]]) - [_id]];
                };
            };
            _seen set [_id,_revision];
        };
    };
} forEach _records;
player setVariable ['QS_taskSync_seen',_seen];
localNamespace setVariable ['QS_taskSync_applying',FALSE];