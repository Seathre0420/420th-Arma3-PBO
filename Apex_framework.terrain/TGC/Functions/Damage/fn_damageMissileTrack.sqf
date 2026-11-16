/* One sampling worker per firing machine; no per-missile script or broadcast. */
params ['_projectile','_side','_ammo'];
if (isNull _projectile || {!local _projectile} || {!(_projectile isKindOf 'MissileBase')}) exitWith {};
private _sequence = (localNamespace getVariable ['TGC_missile_sequence',0]) + 1;
localNamespace setVariable ['TGC_missile_sequence',_sequence];
private _tracked = localNamespace getVariable ['TGC_missile_tracked',[]];
if ((_tracked findIf {(_x # 0) isEqualTo _projectile}) >= 0) exitWith {};
if (count _tracked >= 4096) exitWith {};
_tracked pushBack [_projectile,_side,_ammo,format ['%1/%2',clientOwner,_sequence]];
localNamespace setVariable ['TGC_missile_tracked',_tracked];
if (localNamespace getVariable ['TGC_missile_worker',FALSE]) exitWith {};
localNamespace setVariable ['TGC_missile_worker',TRUE];
[] spawn {
    while {TRUE} do {
        private _rows = [];
        // No suspension while updating the shared registry: Fired can add entries
        // between ticks without a scheduled worker overwriting them.
        isNil {
            private _tracked = (localNamespace getVariable ['TGC_missile_tracked',[]]) select {!isNull (_x # 0)};
            localNamespace setVariable ['TGC_missile_tracked',_tracked];
            private _sampled = serverTime;
            {
                _x params ['_projectile','_side','_ammo','_key'];
                private _target = missileTarget _projectile;
                if (!isNull _target) then {
                    _rows pushBack [_target,_ammo,_side,_sampled + 0.75,_projectile,_key,_sampled];
                };
            } forEach _tracked;
            if (_tracked isEqualTo []) then {localNamespace setVariable ['TGC_missile_worker',FALSE];};
        };
        if !(localNamespace getVariable ['TGC_missile_worker',FALSE]) exitWith {};
        for '_offset' from 0 to ((count _rows) - 1) step 128 do {
            private _batch = _rows select [_offset,128];
            if (isServer) then {
                ['REPORT',_batch] call TGC_fnc_damageMissileSync;
            } else {
                ['REPORT',_batch] remoteExecCall ['TGC_fnc_damageMissileSync',2,FALSE];
            };
        };
        uiSleep 0.25;
    };
};
