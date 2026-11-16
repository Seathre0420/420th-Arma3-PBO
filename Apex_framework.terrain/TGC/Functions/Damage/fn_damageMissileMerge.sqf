/* Local merge, called only by the trusted sync receiver/server.
   Wire row: [target, ammo, launchSide, expiresAt, projectile, stableKey, sampledAt].
   Keep the first four incoming fields compatible with damageDecision. */
if (canSuspend) exitWith {isNil {_this call TGC_fnc_damageMissileMerge;};};
params ['_rows'];
{
    _x params ['_target','_ammo','_side','_expires','_projectile','_key','_sampled'];
    if (!isNull _target && {serverTime <= _expires}) then {
        private _incoming = (_target getVariable ['TGC_damage_incoming',[]]) select {serverTime <= (_x # 2)};
        private _index = _incoming findIf {(_x param [4,'']) isEqualTo _key};
        private _record = [_ammo,_side,_expires,_projectile,_key,_sampled];
        if (_index < 0) then {
            if (count _incoming < 4096) then {_incoming pushBack _record;};
        } else {
            // A handoff snapshot can arrive after a newer live update.
            if (_sampled > ((_incoming # _index) param [5,-1])) then {_incoming set [_index,_record];};
        };
        _target setVariable ['TGC_damage_incoming',_incoming,FALSE];
    };
} forEach _rows;
