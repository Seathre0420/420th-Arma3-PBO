/* [HandleDamage arguments, command, command arguments]. Execute on victim owner.
Call before scheduling secondary effects; direct scripted damage bypasses HandleDamage.
*/
params ['_event','_command','_arguments'];
private _target = _event # 0;
if (!local _target) exitWith {false};
private _snapshot = _event param [10,[],[[]]];
private _blocked = if (_snapshot isEqualTo []) then {_event call TGC_fnc_isFriendlyFire} else {_snapshot # 0};
if (_blocked) exitWith {false};
if !(_command in ['setDamage','setHit','setHitIndex','setHitPointDamage']) exitWith {false};
switch _command do {
    case 'setDamage': {_target setDamage _arguments};
    case 'setHit': {_target setHit _arguments};
    case 'setHitIndex': {_target setHitIndex _arguments};
    case 'setHitPointDamage': {_target setHitPointDamage _arguments};
};
true
