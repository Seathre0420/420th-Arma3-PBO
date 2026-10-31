/*
    Owner-local cargo handoff. Freeze BEFORE release, move while frozen, and
    restore only after the pose has settled. The public snapshot survives a
    locality change; only the matching token may finish/recover a handoff.

    ATTACH retains protection for carrying. PLACE and LOAD finish after two
    frames. A server watchdog recovers abandoned carrying/owner disconnects.
*/
params [
    ['_mode','',['']],['_cargo',objNull,[objNull]],['_position',[],[[]]],['_vectors',[],[[]]],['_attachment',[],[[]]],
    ['_actor',objNull,[objNull]],['_token',[],[[]]],['_attempt',0,[0]]
];
if (isNull _cargo || {_cargo isKindOf 'CAManBase'} || {isSimpleObject _cargo}) exitWith {FALSE};
if (isRemoteExecutedJIP) exitWith {FALSE};
if (_token isNotEqualTo [] && {count _token isNotEqualTo 2 || {(_token findIf {!(_x isEqualType 0) || {!finite _x}}) isNotEqualTo -1}}) exitWith {FALSE};
private _state = _cargo getVariable ['QS_cargoMove_state',[]];

if (_mode isEqualTo 'WATCH') exitWith {
    if (!isServer || {_state isEqualTo []} || {(_state # 0) isNotEqualTo _token}) exitWith {FALSE};
    if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo (_state # 6)} && {remoteExecutedOwner isNotEqualTo 2}) exitWith {FALSE};
    if ((_cargo getVariable ['QS_cargoMove_watch',[]]) isEqualTo _token) exitWith {TRUE};
    _cargo setVariable ['QS_cargoMove_watch',_token];
    [_cargo,_token] spawn {
        params ['_cargo','_token'];
        private _nextRecovery = diag_tickTime + 5;
        while {!isNull _cargo && {((_cargo getVariable ['QS_cargoMove_state',[]]) param [0,[]]) isEqualTo _token}} do {
            uiSleep 0.25;
            private _state = _cargo getVariable ['QS_cargoMove_state',[]];
            if (_state isNotEqualTo [] && {(_state # 0) isEqualTo _token}) then {
                private _actor = _state # 4;
                if (
                    diag_tickTime >= _nextRecovery &&
                    {isNull _actor || {!alive _actor} || {!isPlayer _actor} ||
                    {(_actor getVariable ['QS_cargoMove_active',[]]) isNotEqualTo _token} ||
                    {isNull (attachedTo _cargo) && {isNull (isVehicleCargo _cargo)}}}
                ) then {
                    _nextRecovery = diag_tickTime + 5;
                    private _mode = ['RECOVER','FINISH'] select (
                        ((_state param [8,'']) in ['LOAD','PLACE','RECOVER']) || {!isNull (isVehicleCargo _cargo)}
                    );
                    [_mode,_cargo,[],[],[],objNull,_token] remoteExecCall ['QS_fnc_cargoMove',_cargo,FALSE];
                };
            };
        };
    };
    TRUE
};

// Do not expose a general-purpose remote teleport/freeze endpoint.
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) then {
    private _sender = remoteExecutedOwner;
    private _completion = _mode isEqualTo 'FINISH' && {_state isNotEqualTo []} && {(_state # 6) isEqualTo _sender};
    if (!_completion && {isNull _actor || {owner _actor isNotEqualTo _sender} || {!isPlayer _actor} ||
        {_actor distance _cargo > 100}}) exitWith {_mode = '';};
};
if !(_mode in ['ATTACH','PLACE','LOAD','FINISH','RECOVER']) exitWith {FALSE};
if (_mode in ['ATTACH','PLACE']) then {
    private _validVector = {(_this isEqualType []) && {count _this isEqualTo 3} && {(_this findIf {!(_x isEqualType 0) || {!finite _x}}) isEqualTo -1}};
    if (count _vectors isNotEqualTo 2 || {!((_vectors # 0) call _validVector)} || {!((_vectors # 1) call _validVector)}) exitWith {_mode = '';};
    if (_mode isEqualTo 'PLACE' && {!(_position call _validVector)}) exitWith {_mode = '';};
    if (_mode isEqualTo 'ATTACH' && {count _attachment < 2 || {!((_attachment # 0) isEqualType objNull)} || {!((_attachment # 1) call _validVector)}}) exitWith {_mode = '';};
    if (_mode isEqualTo 'ATTACH' && {count _attachment > 4 ||
        {count _attachment > 2 && {!((_attachment # 2) isEqualType '')}} ||
        {count _attachment > 3 && {!((_attachment # 3) isEqualType FALSE)}}}) exitWith {_mode = '';};
};
if (_mode isEqualTo '') exitWith {FALSE};
if (_mode isEqualTo 'LOAD' && {count _attachment < 1 || {!((_attachment # 0) isEqualType objNull)}}) exitWith {FALSE};
if (_mode isEqualTo 'LOAD' && {!((_attachment param [1,'STANDARD']) in ['STANDARD','HIDDEN'])}) exitWith {FALSE};
if (_mode in ['ATTACH','PLACE','LOAD'] && {!isNull _actor}) then {
    if ((getPlayerUID _actor) in (missionNamespace getVariable ['QS_blacklist_logistics',[]])) exitWith {_mode = '';};
    if (_mode isEqualTo 'PLACE' && {(getPosASL _actor) distance _position > 100}) exitWith {_mode = '';};
    if (_mode isEqualTo 'ATTACH' && {!((_attachment # 0) in [_actor,vehicle _actor])}) exitWith {_mode = '';};
    if (_mode isEqualTo 'LOAD' && {_cargo distance (_attachment # 0) > 100}) exitWith {_mode = '';};
    if (_mode isEqualTo 'LOAD' && {lockedInventory (_attachment # 0) || {(_attachment # 0) getVariable ['QS_lockedInventory',FALSE]}}) exitWith {_mode = '';};
};
if (_mode isEqualTo '') exitWith {FALSE};
if (!local _cargo) exitWith {
    if (_attempt < 3) then {
        private _target = [2,_cargo] select isServer;
        [_mode,_cargo,_position,_vectors,_attachment,_actor,_token,_attempt + 1] remoteExecCall ['QS_fnc_cargoMove',_target,FALSE];
    };
    FALSE
};
private _result = FALSE;
isNil {
    _state = _cargo getVariable ['QS_cargoMove_state',[]];
    if (_mode in ['FINISH','RECOVER'] && {_state isEqualTo [] || {(_state # 0) isNotEqualTo _token}}) exitWith {};
    // A delayed carry cancellation must not undo a transfer already settling.
    if (_mode isEqualTo 'RECOVER' && {(_state param [8,'']) in ['LOAD','PLACE','RECOVER']}) exitWith {};
    if (_mode isEqualTo 'LOAD' && {_state isEqualTo [] || {(_state # 0) isNotEqualTo _token}}) exitWith {};
    if (_state isNotEqualTo [] && {!isNull _actor} && {(_state # 4) isNotEqualTo _actor}) exitWith {};
    if (_mode in ['ATTACH','PLACE','LOAD'] && {_cargo getVariable ['QS_cargoMove_busy',FALSE]}) exitWith {};
    if (_mode isEqualTo 'ATTACH' && {count _attachment < 2 || {isNull (_attachment # 0)} || {count _vectors isNotEqualTo 2}}) exitWith {};
    if (_mode isEqualTo 'PLACE' && {count _position isNotEqualTo 3 || {count _vectors isNotEqualTo 2}}) exitWith {};
    if (_mode isEqualTo 'LOAD' && {count _attachment < 1 || {isNull (_attachment # 0)}}) exitWith {};

    if (_state isEqualTo []) then {
        private _parent = attachedTo _cargo;
        private _viv = isVehicleCargo _cargo;
        private _source = [_parent,_viv] select (!isNull _viv);
        private _offset = [0,0,0];
        if (!isNull _parent) then {_offset = _parent worldToModel (getPos _cargo);};
        private _damageAllowed = isDamageAllowed _cargo;
        if (!isNull _viv && {(_cargo isKindOf 'StaticWeapon') || {_cargo isKindOf 'Reammobox_F'}}) then {
            _damageAllowed = _cargo getVariable ['cargo_isDamageAllowed',_damageAllowed];
        };
        if (_token isEqualTo []) then {_token = [clientOwner,diag_tickTime];};
        _state = [_token,simulationEnabled _cargo,_damageAllowed,_source,_actor,
            [_parent,_offset,_viv,getPosASL _cargo,[vectorDir _cargo,vectorUp _cargo],isObjectHidden _cargo,
                (if (isNull _parent) then {[]} else {[_cargo,_parent,TRUE] call BIS_fnc_vectorDirAndUpRelative})],clientOwner,[]];
        _cargo setVariable ['QS_cargoMove_state',_state,TRUE];
    };
    _state set [6,clientOwner];
    _cargo setVariable ['QS_cargoMove_state',_state,TRUE];
    _token = _state # 0;
    ['WATCH',_cargo,[],[],[],objNull,_token] remoteExecCall ['QS_fnc_cargoMove',2,FALSE];
    _cargo setVariable ['QS_cargoMove_busy',TRUE,TRUE];
    _cargo enableSimulationGlobal FALSE;
    _cargo allowDamage FALSE;

    if (_mode isEqualTo 'FINISH' && {(_state param [8,'']) isEqualTo 'PLACE'} &&
        {(!isNull (attachedTo _cargo)) || {!isNull (isVehicleCargo _cargo)} ||
        {(getPosASL _cargo) distance (_state # 9) > 0.25}}) then {_mode = 'RECOVER';};
    if (_mode isEqualTo 'FINISH' && {(_state param [8,'']) isEqualTo 'LOAD'} &&
        {private _target = (_state # 7) # 0;
        (attachedTo _cargo) isNotEqualTo _target && {(isVehicleCargo _cargo) isNotEqualTo _target}}) then {_mode = 'RECOVER';};
    if (_mode isEqualTo 'FINISH' && {isNull (attachedTo _cargo)} && {isNull (isVehicleCargo _cargo)} &&
        {!([_cargo,_state # 3] call QS_fnc_cargoPlacementClear)}) then {_mode = 'RECOVER';};
    if (_mode isEqualTo 'FINISH') exitWith {
        _cargo setVelocity [0,0,0];
        _cargo setAngularVelocity [0,0,0];
        _cargo enableSimulationGlobal (_state # 1);
        private _loaded = !isNull (isVehicleCargo _cargo);
        _cargo allowDamage ((_state # 2) && {!_loaded || {!((_cargo isKindOf 'Reammobox_F') || {_cargo isKindOf 'StaticWeapon'})}});
        _cargo setVariable ['QS_cargoMove_state',nil,TRUE];
        _cargo setVariable ['QS_cargoMove_busy',FALSE,TRUE];
        if (!isNull (_state # 3)) then {
            ['enableCollisionWith',_cargo,_state # 3] remoteExec ['QS_fnc_remoteExecCmd',0,FALSE];
        };
        private _leaseActor = _state # 4;
        if (!isNull _leaseActor && {(_leaseActor getVariable ['QS_cargoMove_active',[]]) isEqualTo _token}) then {
            _leaseActor setVariable ['QS_cargoMove_active',nil,TRUE];
        };
        _result = TRUE;
    };

    private _previousParent = attachedTo _cargo;
    if (!isNull (isVehicleCargo _cargo)) then {objNull setVehicleCargo _cargo;};
    if (!isNull (attachedTo _cargo)) then {detach _cargo;};
    // CargoUnloaded/addon callbacks can run inside the engine command above.
    _cargo enableSimulationGlobal FALSE;
    _cargo allowDamage FALSE;
    _cargo setVelocity [0,0,0];
    _cargo setAngularVelocity [0,0,0];

    if (_mode isEqualTo 'ATTACH') then {
        _cargo attachTo _attachment;
        _cargo setVectorDirAndUp _vectors;
        _state set [7,_attachment];
        _cargo setVariable ['QS_cargoMove_state',_state,TRUE];
        _cargo setVariable ['QS_cargoMove_busy',FALSE,TRUE];
        _result = TRUE;
    } else {
        private _placed = FALSE;
        if (_mode isEqualTo 'PLACE') then {
            _cargo setVectorDirAndUp _vectors;
            _cargo setPosASL _position;
            _placed = [_cargo,_state # 3] call QS_fnc_cargoPlacementClear;
        };
        if (_mode isEqualTo 'LOAD') then {
            private _target = _attachment # 0;
            private _canLoad = [_target,_cargo] call QS_fnc_canVehicleCargo;
            private _hidden = (_attachment param [1,'STANDARD']) isEqualTo 'HIDDEN';
            private _eligible = alive _target && {alive _cargo} &&
                {!lockedInventory _target} && {!(_target getVariable ['QS_lockedInventory',FALSE])} &&
                {!(_target getVariable ['QS_logistics_wreck',FALSE])} &&
                {!(_cargo getVariable ['QS_logistics_immovable',FALSE])};
            if (_hidden) then {
                _eligible = _eligible && {!(_canLoad # 1)} &&
                    {[0,_cargo,_target] call QS_fnc_getCustomCargoParams} &&
                    {[1,_cargo,_target] call QS_fnc_getCustomCargoParams};
            } else {_eligible = _eligible && {_canLoad # 0};};
            if (_eligible) then {
                if (_hidden) then {
                    _cargo attachTo [_target,[0,0,-100]];
                    [71,_cargo,TRUE] remoteExecCall ['QS_fnc_remoteExec',2,FALSE];
                    _placed = (attachedTo _cargo) isEqualTo _target;
                } else {_placed = [_target,_cargo] call QS_fnc_setVehicleCargo;};
                // Preserve legacy registration so newly loaded class-based cargo
                // appears in the unload menu and remains eligible for unloading.
                if (_placed) then {_cargo setVariable ['QS_logistics',TRUE,TRUE];};
                [_target,TRUE,TRUE] call QS_fnc_updateCenterOfMass;
            };
            _state set [7,_attachment];
        };
        // Failed placement/transfer and abandoned carrying return to the original
        // carrier if possible. Otherwise find an empty position before restoring.
        if (!_placed) then {
            _mode = 'RECOVER';
            (_state # 5) params ['_parent','_offset','_viv','_oldPos','_oldVectors','','_relativeVectors'];
            if (!isNull _viv) then {_placed = _viv setVehicleCargo _cargo;};
            if (!_placed && {!isNull _parent} && {!(_parent isKindOf 'CAManBase')}) then {
                _cargo attachTo [_parent,_offset];
                _cargo setVectorDirAndUp _relativeVectors;
                _placed = TRUE;
            };
            if (!_placed) then {
                private _empty = (getPos _cargo) findEmptyPosition [2,50,typeOf _cargo];
                if (_empty isNotEqualTo []) then {
                    _cargo setVectorUp (surfaceNormal _empty);
                    _cargo setPosATL _empty;
                    _placed = [_cargo,_state # 3] call QS_fnc_cargoPlacementClear;
                };
            };
            if (!_placed) then {
                _cargo setVectorDirAndUp _oldVectors;
                _cargo setPosASL _oldPos;
                _placed = [_cargo,_state # 3] call QS_fnc_cargoPlacementClear;
            };
            diag_log format ['[CARGO MOVE] Recovery for %1, safe=%2',typeOf _cargo,_placed];
        };
        _cargo enableSimulationGlobal FALSE;
        _cargo allowDamage FALSE;
        _cargo setVelocity [0,0,0];
        _cargo setAngularVelocity [0,0,0];
        if (_placed) then {
            _state set [8,_mode];
            _state set [9,_position];
            _cargo setVariable ['QS_cargoMove_state',_state,TRUE];
            [_cargo,_token,diag_frameNo + 2] spawn {
                params ['_cargo','_token','_frame'];
                waitUntil {diag_frameNo >= _frame || {isNull _cargo}};
                if (!isNull _cargo) then {
                    ['FINISH',_cargo,[],[],[],objNull,_token] remoteExecCall ['QS_fnc_cargoMove',2,FALSE];
                };
            };
            _result = TRUE;
        } else {
            _cargo setVariable ['QS_cargoMove_busy',FALSE,TRUE];
        };
    };
    if (!isNull _previousParent) then {[_previousParent,TRUE,TRUE] call QS_fnc_updateCenterOfMass;};
    if (!isNull _actor && {isObjectHidden _cargo} &&
        {!(_mode isEqualTo 'LOAD' && {(_attachment param [1,'STANDARD']) isEqualTo 'HIDDEN'})}) then {
        [71,_cargo,FALSE] remoteExec ['QS_fnc_remoteExec',2,FALSE];
    };
};
_result
