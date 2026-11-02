/* Server-owned complete task snapshots. Revisions never repeat during a mission. */
if (!isServer) exitWith {};
params [['_mode','REQUEST'],['_id',''],['_data',[]]];
// This writer is deliberately absent from CfgRemoteExec; requests use a read-only endpoint.
private _records = missionNamespace getVariable ['QS_taskSync_records',[]];
if (_mode isEqualTo 'REQUEST') exitWith {
    if (isRemoteExecuted && {remoteExecutedOwner > 2}) then {
        [_records] remoteExecCall ['QS_fnc_taskSyncClient',remoteExecutedOwner];
    };
};
private _index = _records findIf {(_x # 0) isEqualTo _id};
private _previous = if (_index < 0) then {[]} else {_records # _index};
private _revision = (missionNamespace getVariable ['QS_taskSync_revision',0]) + 1;
missionNamespace setVariable ['QS_taskSync_revision',_revision];
private _generation = missionNamespace getVariable ['QS_taskSync_aoGeneration',0];
if (_id isEqualTo 'QS_IA_TASK_AO_0' && {_data isNotEqualTo []} && {_previous isEqualTo [] || {(_previous # 3) isEqualTo []}}) then {
    _generation = _generation + 1;
    missionNamespace setVariable ['QS_taskSync_aoGeneration',_generation];
};
private _record = [_id,_revision,_generation,_data];
if (_index < 0) then {_records pushBack _record} else {_records set [_index,_record]};
missionNamespace setVariable ['QS_taskSync_records',_records];
// A single persistent snapshot replaces the previous one, including tombstones.
[_records] remoteExecCall ['QS_fnc_taskSyncClient',-2,'QS_TASK_SNAPSHOT'];