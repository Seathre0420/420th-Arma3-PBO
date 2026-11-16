/* Server relay/cache and owner-only receiver. No persistent remote executions.
   The server serializes concurrent shooters; owners merge deltas, never replace
   whole arrays. Accepted launch identity survives launcher deletion/transfers. */
// Keep scheduled server producers atomic with remoteExecCall receivers.
if (canSuspend) exitWith {isNil {_this call TGC_fnc_damageMissileSync;};};
params [['_mode','',['']],['_payload',[],[[]]]];
if (isRemoteExecutedJIP) exitWith {};
if (_mode isEqualTo 'APPLY') exitWith {
    if (!isRemoteExecuted || {remoteExecutedOwner isNotEqualTo 2} || {count _payload > 128}) exitWith {};
    // Only the server can produce APPLY rows. Keep nonlocal rows briefly in
    // case the target changes locality while this message is in transit.
    [_payload] call TGC_fnc_damageMissileMerge;
};
if (!isServer || {!(_mode in ['REPORT','REQUEST'])}) exitWith {};
private _sender = if (isRemoteExecuted) then {remoteExecutedOwner} else {2};
if (_sender < 2) exitWith {};
// Bound remote work before inspecting entities. 4096 tracked missiles fit into
// 32 batches per sampling tick; requests have a separate budget.
private _rates = localNamespace getVariable ['TGC_missile_rates',createHashMap];
{if (diag_tickTime > (((_rates get _x) # 0) + 2)) then {_rates deleteAt _x;};} forEach keys _rates;
private _rateKey = format ['%1/%2',_sender,_mode];
if (count _rates >= 512 && {!(_rateKey in _rates)}) exitWith {};
private _rate = _rates getOrDefault [_rateKey,[diag_tickTime,0]];
if (diag_tickTime >= ((_rate # 0) + 1)) then {_rate = [diag_tickTime,0];};
if ((_rate # 1) >= (if (_mode isEqualTo 'REPORT') then {160} else {128})) exitWith {};
_rate set [1,(_rate # 1) + 1];
_rates set [_rateKey,_rate];
localNamespace setVariable ['TGC_missile_rates',_rates];
if (_mode isEqualTo 'REQUEST') exitWith {
    if (count _payload isNotEqualTo 1 || {!((_payload # 0) isEqualType objNull)}) exitWith {};
    private _target = _payload # 0;
    if (isNull _target || {owner _target isNotEqualTo _sender}) exitWith {};
    private _rows = ((_target getVariable ['TGC_damage_incoming',[]]) select {count _x >= 6 && {serverTime <= (_x # 2)}}) apply {
        [_target,_x # 0,_x # 1,_x # 2,_x # 3,_x # 4,_x # 5]
    };
    if (_sender > 2) then {
        for '_offset' from 0 to ((count _rows) - 1) step 128 do {
            ['APPLY',_rows select [_offset,128]] remoteExecCall ['TGC_fnc_damageMissileSync',_sender,FALSE];
        };
    };
};
if (count _payload > 128) exitWith {};
private _launches = localNamespace getVariable ['TGC_missile_launches',createHashMap];
private _targets = localNamespace getVariable ['TGC_missile_targets',[]];
// Recover state saved by the former exitWith-in-select cleanup bug.
if !(_targets isEqualType []) then {_targets = [];};
private _batches = createHashMap;
private _accepted = [];
{
    if (_x isEqualType [] && {count _x isEqualTo 7}) then {
        _x params ['_target','_ammo','_side','_expires','_projectile','_key','_sampled'];
        if (_target isEqualType objNull && {_ammo isEqualType ''} && {_side isEqualType WEST} &&
            {_expires isEqualType 0} && {_projectile isEqualType objNull} && {_key isEqualType ''} && {_sampled isEqualType 0} &&
            {finite _sampled && {finite _expires}} && {count _key <= 64} && {count _ammo <= 128} &&
            {!isNull _target && {_target isKindOf 'AllVehicles'}} &&
            {_side in [WEST,EAST,RESISTANCE,CIVILIAN,sideUnknown,sideEnemy]} &&
            {_sampled <= serverTime + 0.1 && {_expires >= serverTime} && {abs (_expires - _sampled - 0.75) < 0.01}}) then {
            private _launch = _launches getOrDefault [_key,[]];
            if (_launch isEqualTo [] && {count _launches < 4096} &&
                {(_key find (format ['%1/',_sender])) isEqualTo 0} &&
                {!isNull _projectile && {_projectile isKindOf 'MissileBase'}} &&
                {owner _projectile isEqualTo _sender} && {typeOf _projectile isEqualTo _ammo}) then {
                _launch = [_sender,_projectile,_ammo,_side,-1,serverTime];
            };
            if (_launch isNotEqualTo [] && {(_launch # 0) isEqualTo _sender} &&
                {(_launch # 2) isEqualTo _ammo} && {(_launch # 3) isEqualTo _side} &&
                {_sampled > (_launch # 4)} &&
                {!isNull (_launch # 1) || {serverTime <= ((_launch # 5) + 0.75)}}) then {
                _launch set [4,_sampled];
                if (!isNull (_launch # 1)) then {_launch set [5,serverTime];};
                _launches set [_key,_launch];
                private _row = +_x;
                _row set [4,_launch # 1];
                _accepted pushBack _row;
                _targets pushBackUnique _target;
                private _recipient = owner _target;
                if (_recipient > 2) then {
                    private _batch = _batches getOrDefault [str _recipient,[]];
                    _batch pushBack _row;
                    _batches set [str _recipient,_batch];
                };
            };
        };
    };
} forEach _payload;
[_accepted] call TGC_fnc_damageMissileMerge;
localNamespace setVariable ['TGC_missile_launches',_launches];
localNamespace setVariable ['TGC_missile_targets',_targets];
{
    ['APPLY',_y] remoteExecCall ['TGC_fnc_damageMissileSync',parseNumber _x,FALSE];
} forEach _batches;
if (localNamespace getVariable ['TGC_missile_cacheWorker',FALSE]) exitWith {};
localNamespace setVariable ['TGC_missile_cacheWorker',TRUE];
[] spawn {
    while {TRUE} do {
        uiSleep 0.25;
        isNil {
            private _launches = localNamespace getVariable ['TGC_missile_launches',createHashMap];
            {
                private _launch = _launches get _x;
                if (isNull (_launch # 1) && {serverTime > ((_launch # 5) + 0.75)}) then {_launches deleteAt _x;};
            } forEach keys _launches;
            private _targets = localNamespace getVariable ['TGC_missile_targets',[]];
            if !(_targets isEqualType []) then {_targets = [];};
            _targets = _targets select {
                // exitWith here would return FALSE for the whole select,
                // corrupting the saved array as soon as a target is deleted.
                !isNull _x && {
                    private _incoming = (_x getVariable ['TGC_damage_incoming',[]]) select {serverTime <= (_x # 2)};
                    _x setVariable ['TGC_damage_incoming',_incoming,FALSE];
                    // Covers transfers whose Local callback/request raced the first report.
                    private _owner = owner _x;
                    if (_owner > 2 && {_owner isNotEqualTo (_x getVariable ['TGC_missile_cacheOwner',-1])}) then {
                        private _target = _x;
                        private _rows = (_incoming select {count _x >= 6}) apply {[_target,_x # 0,_x # 1,_x # 2,_x # 3,_x # 4,_x # 5]};
                        for '_offset' from 0 to ((count _rows) - 1) step 128 do {
                            ['APPLY',_rows select [_offset,128]] remoteExecCall ['TGC_fnc_damageMissileSync',_owner,FALSE];
                        };
                    };
                    _x setVariable ['TGC_missile_cacheOwner',_owner,FALSE];
                    _incoming isNotEqualTo []
                }
            };
            localNamespace setVariable ['TGC_missile_targets',_targets];
            private _rates = localNamespace getVariable ['TGC_missile_rates',createHashMap];
            {if (diag_tickTime > (((_rates get _x) # 0) + 2)) then {_rates deleteAt _x;};} forEach keys _rates;
            if (count _launches isEqualTo 0 && {_targets isEqualTo []}) then {
                localNamespace setVariable ['TGC_missile_cacheWorker',FALSE];
            };
        };
        if !(localNamespace getVariable ['TGC_missile_cacheWorker',FALSE]) exitWith {};
    };
};
