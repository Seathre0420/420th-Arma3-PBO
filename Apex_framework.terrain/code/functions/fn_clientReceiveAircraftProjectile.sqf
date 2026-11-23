// An authenticated server announcement can arrive before the projectile replica.
if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner isNotEqualTo 2}) exitWith {};
params [['_projectileId','',['']]];
if (_projectileId in ['','0:0']) exitWith {};

[_projectileId] spawn {
	params ['_projectileId'];
	private _projectile = objNull;
	private _deadline = diag_tickTime + 1;
	waitUntil {
		_projectile = objectFromNetId _projectileId;
		if (!isNull _projectile || {diag_tickTime >= _deadline}) exitWith {TRUE};
		uiSleep 0.05;
		FALSE
	};
	if (isNull _projectile) exitWith {};
	isNil {[_projectile,TRUE,TRUE,FALSE] call QS_fnc_clientTrackProjectile;};
};
