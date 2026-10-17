/*
 * Defend/Mega Defend assault infantry only. The server owns the roster and one
 * one-second worker; batched TICKs execute on the current unit owner (server/HC).
 * No world scans, per-soldier workers, teleporting or repeated path resets.
 * REGISTER is called after infantry setup; pilots and vehicle crews never opt in.
 */
params [['_mode',''],['_units',[]],['_epoch',-1],['_hq',[]]];
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {FALSE};
private _current = missionNamespace getVariable ['QS_defendControl_active',FALSE] &&
    {(missionNamespace getVariable ['QS_defendControl_epoch',-2]) isEqualTo _epoch};
private _features = ['TARGET','AUTOTARGET','AUTOCOMBAT','COVER','SUPPRESSION'];
private _fn_exempt = {
    params ['_unit'];
    isPlayer _unit || {captive _unit} || {!isNull (remoteControlled _unit)} ||
    {!isNull (_unit getVariable ['bis_fnc_moduleRemoteControl_owner',objNull])} ||
    {((side (group _unit)) getFriend WEST) >= 0.6} ||
    {((units (group _unit)) findIf {isPlayer _x}) >= 0}
};
if (_mode isEqualTo 'MANAGED') exitWith {
    _current && {(_units getVariable ['QS_defendAssault_epoch',-3]) isEqualTo _epoch} &&
    {!([_units] call _fn_exempt)}
};
if (_mode isEqualTo 'REGISTER') exitWith {
    if (!isServer || {!_current} || {count _hq < 2}) exitWith {FALSE};
    private _added = [];
    {
        private _unit = _x;
        if (alive _unit && {_unit isKindOf 'CAManBase'} && {!([_unit] call _fn_exempt)} &&
            {(_unit getVariable ['QS_defendAssault_epoch',-3]) isNotEqualTo _epoch}) then {
            private _group = group _unit;
            if ((_group getVariable ['QS_defendAssault_epoch',-3]) isNotEqualTo _epoch) then {
                _group setVariable ['QS_defendAssault_restore',
                    [attackEnabled _group,combatMode _group,behaviour (leader _group),speedMode _group],TRUE];
                _group setVariable ['QS_defendAssault_epoch',_epoch,TRUE];
            };
            _unit setVariable ['QS_defendAssault_restore',
                [_features apply {_unit checkAIFeature _x},unitCombatMode _unit,unitPos _unit,
                 getForcedSpeed _unit,_unit getVariable ['QS_AI_UNIT_regroup_disable',FALSE]],TRUE];
            _unit setVariable ['QS_defendAssault_epoch',_epoch,TRUE];
            _unit setVariable ['QS_defendAssault_released',FALSE,TRUE];
            _added pushBackUnique _unit;
        };
    } forEach _units;
    // Spawns and the scheduled worker may interleave. Commit against the fresh
    // roster atomically so pruning cannot discard a newly admitted soldier.
    isNil {
        private _roster = missionNamespace getVariable ['QS_defendAssault_roster',[]];
        {_roster pushBackUnique _x;} forEach _added;
        missionNamespace setVariable ['QS_defendAssault_roster',_roster];
    };
    // Immediate owner-local setup closes the spawn-to-first-tick firing window.
    ['TICK',_units,_epoch,_hq] call QS_fnc_defendAssault;
    TRUE
};
if (_mode isEqualTo 'RUN') exitWith {
    if (!isServer || {!canSuspend}) exitWith {};
    while {missionNamespace getVariable ['QS_defendControl_active',FALSE] &&
        {(missionNamespace getVariable ['QS_defendControl_epoch',-2]) isEqualTo _epoch}} do {
        private _batches = createHashMap;
        private _roster = [];
        isNil {
            _roster = (missionNamespace getVariable ['QS_defendAssault_roster',[]]) select {
                alive _x && {(_x getVariable ['QS_defendAssault_epoch',-3]) isEqualTo _epoch}
            };
            missionNamespace setVariable ['QS_defendAssault_roster',_roster];
        };
        {
            private _owner = owner _x;
            if (_owner > 0) then {
                private _key = str _owner;
                private _batch = _batches getOrDefault [_key,[]];
                _batch pushBack _x;
                _batches set [_key,_batch];
            };
        } forEach _roster;
        {
            private _target = parseNumber _x;
            if (_target isEqualTo clientOwner) then {
                ['TICK',_y,_epoch,_hq] call QS_fnc_defendAssault;
            } else {
                ['TICK',_y,_epoch,_hq] remoteExecCall ['QS_fnc_defendAssault',_target];
            };
        } forEach _batches;
        uiSleep 1;
    };
};
if (_mode isEqualTo 'STOP') exitWith {
    if (!isServer || {(missionNamespace getVariable ['QS_defendControl_epoch',-2]) isNotEqualTo _epoch}) exitWith {};
    ['RELEASE',missionNamespace getVariable ['QS_defendAssault_roster',[]],_epoch] remoteExecCall ['QS_fnc_defendAssault',0];
    missionNamespace setVariable ['QS_defendAssault_roster',[]];
};
if (_mode isEqualTo 'RELEASE') exitWith {
    private _groups = [];
    {
        private _unit = _x;
        if (local _unit && {(_unit getVariable ['QS_defendAssault_epoch',-3]) isEqualTo _epoch}) then {
            private _restore = _unit getVariable ['QS_defendAssault_restore',[]];
            if (_restore isNotEqualTo []) then {
                { _unit enableAIFeature [_x,(_restore # 0) # _forEachIndex]; } forEach _features;
                _unit setUnitCombatMode (_restore # 1);
                _unit setUnitPos (_restore # 2);
                _unit forceSpeed (_restore # 3);
                _unit setVariable ['QS_AI_UNIT_regroup_disable',_restore # 4,TRUE];
            };
            _unit setVariable ['QS_defendAssault_epoch',nil,TRUE];
            _unit setVariable ['QS_defendAssault_restore',nil,TRUE];
            _unit setVariable ['QS_defendAssault_local',nil,FALSE];
            _unit removeEventHandler ['Local',_unit getVariable ['QS_defendAssault_localEH',-1]];
            _unit setVariable ['QS_defendAssault_localEH',nil,FALSE];
            _groups pushBackUnique (group _unit);
        };
    } forEach _units;
    {
        private _group = _x;
        if (local _group && {(_group getVariable ['QS_defendAssault_epoch',-3]) isEqualTo _epoch}) then {
            private _restore = _group getVariable ['QS_defendAssault_restore',[]];
            if (_restore isNotEqualTo [] && {((units _group) findIf {[_x] call _fn_exempt}) < 0}) then {
                _group enableAttack (_restore # 0);
                _group setCombatMode (_restore # 1);
                _group setBehaviour (_restore # 2);
                _group setSpeedMode (_restore # 3);
            };
            _group setVariable ['QS_defendAssault_epoch',nil,TRUE];
            _group setVariable ['QS_defendAssault_restore',nil,TRUE];
            _group setVariable ['QS_defendAssault_owner',nil,FALSE];
        };
    } forEach _groups;
};
if (_mode isNotEqualTo 'TICK' || {!_current} || {count _hq < 2}) exitWith {FALSE};
{
    private _unit = _x;
    if (local _unit && {alive _unit} && {simulationEnabled _unit} &&
        {(_unit getVariable ['QS_defendAssault_epoch',-3]) isEqualTo _epoch} &&
        {!([_unit] call _fn_exempt)}) then {
        private _group = group _unit;
        if ((_group getVariable ['QS_defendAssault_owner',[-1,-1]]) isNotEqualTo [_epoch,clientOwner]) then {
            _group setVariable ['QS_defendAssault_owner',[_epoch,clientOwner],FALSE];
            _group enableAttack FALSE;
            _group setCombatMode 'YELLOW';
            _group setBehaviour 'AWARE';
            _group setSpeedMode 'FULL';
            _group allowFleeing 0;
        };
        private _released = _unit getVariable ['QS_defendAssault_released',FALSE];
        private _state = _unit getVariable ['QS_defendAssault_local',[]];
        private _fresh = _state isEqualTo [] || {(_state # 0) isNotEqualTo clientOwner} || {(_state # 1) isNotEqualTo _epoch};
        if (_fresh) then {
            // Reapply after locality transfer without losing the permanent unlock.
            _state = [clientOwner,_epoch,FALSE,getPosATL _unit,diag_tickTime,0];
            if (isNil {_unit getVariable 'QS_defendAssault_localEH'}) then {
                private _eh = _unit addEventHandler ['Local',{
                    params ['_entity','_isLocal'];
                    if (_isLocal) then {
                        _entity setVariable ['QS_defendAssault_local',nil,FALSE];
                        (group _entity) setVariable ['QS_defendAssault_owner',nil,FALSE];
                    };
                }];
                _unit setVariable ['QS_defendAssault_localEH',_eh,FALSE];
            };
            _unit setVariable ['QS_AI_UNIT_regroup_disable',TRUE,TRUE];
            _unit allowFleeing 0;
            if (!_released) then {
                _unit doTarget objNull;
                _unit suppressFor 0;
                _unit setVariable ['QS_AI_coverUntil',0,FALSE];
            };
        };
        if (!_released) then {
            // Group-leader/HC orders can overwrite individual ROE. Repair only
            // changed flags, without issuing a new destination or clearing a path.
            {if (_unit checkAIFeature _x) then {_unit enableAIFeature [_x,FALSE];};} forEach _features;
            if (unitCombatMode _unit isNotEqualTo 'BLUE') then {_unit setUnitCombatMode 'BLUE';};
        };
        // Cargo, parachutes and rappel scripts retain their movement ownership.
        private _grounded = isNull (objectParent _unit) &&
            {!(_group getVariable ['QS_taruDelivery_busy',FALSE])} &&
            {!(_unit getVariable ['AR_Is_Rappelling',FALSE])} &&
            {((getPosATL _unit) # 2) < 3 || {isTouchingGround _unit}};
        if (_grounded && {lifeState _unit in ['HEALTHY','INJURED']}) then {
            if (!_released && {(_unit distance2D _hq) <= 100}) then {
                _released = TRUE;
                _unit setVariable ['QS_defendAssault_released',TRUE,TRUE];
                _fresh = TRUE;
            };
            if (_released && {_fresh}) then {
                {_unit enableAIFeature [_x,TRUE];} forEach _features;
                _unit setUnitCombatMode 'YELLOW';
                _unit forceSpeed -1;
                _unit setUnitPos 'AUTO';
            };
            if (!_released) then {
                // Individual orders prevent trailing men waiting on the leader.
                if (combatBehaviour _unit isNotEqualTo 'AWARE') then {_unit setCombatBehaviour 'AWARE';};
                _unit setUnitPos 'UP';
                _unit forceSpeed 24;
            };
            private _now = diag_tickTime;
            private _position = getPosATL _unit;
            if ((_position distance2D (_state # 3)) >= 3) then {
                _state set [3,_position];
                _state set [4,_now];
            };
            private _distance = _unit distance2D _hq;
            // At most one retry per eight seconds, only after six seconds without
            // positional progress or a lost order. Combat inside HQ can pause.
            private _retry = _now >= (_state # 5) &&
                {(_now - (_state # 4)) >= 6 || {currentCommand _unit in ['','STOP','WAIT']}};
            if (!(_state # 2) || {_distance > ([25,100] select _released) && {_retry}}) then {
                _unit doMove _hq;
                _state set [2,TRUE];
                _state set [3,_position];
                _state set [4,_now];
                _state set [5,_now + 8];
            };
        } else {
            // A new order is needed when passengers actually dismount/land.
            _state set [2,FALSE];
        };
        _unit setVariable ['QS_defendAssault_local',_state,FALSE];
    };
} forEach _units;
TRUE
