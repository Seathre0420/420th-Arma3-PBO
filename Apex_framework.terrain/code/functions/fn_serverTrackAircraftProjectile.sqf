// Validate an aircraft launch on the server before sharing it with other players.
if (!isServer || {isRemoteExecutedJIP}) exitWith {};
params [['_projectileId','',['']]];
if ((count _projectileId > 32) || {_projectileId isEqualTo '0:0'} || {!(_projectileId regexMatch '^[0-9]+:[0-9]+$')}) exitWith {};

private _sender = if (isRemoteExecuted) then {remoteExecutedOwner} else {clientOwner};
if (_sender < 2) exitWith {};

// Bound network lookups per sender. Start a fresh table each second.
private _now = diag_tickTime;
private _rateWindow = serverNamespace getVariable ['QS_aircraftProjectileRateWindow',[0]];
if (_now >= (_rateWindow # 0)) then {
	_rateWindow = [_now + 1,createHashMap];
	serverNamespace setVariable ['QS_aircraftProjectileRateWindow',_rateWindow];
};
private _rates = _rateWindow # 1;
private _reports = _rates getOrDefault [_sender,0];
if (_reports >= 16) exitWith {};
_rates set [_sender,_reports + 1];

[_projectileId,_sender] spawn {
	params ['_projectileId','_sender'];
	private _projectile = objNull;
	private _aircraft = objNull;
	private _deadline = diag_tickTime + 1;
	waitUntil {
		_projectile = objectFromNetId _projectileId;
		if (!isNull _projectile) then {
			_aircraft = (getShotParents _projectile) param [0,objNull];
		};
		if ((!isNull _aircraft && {owner _projectile >= 2}) || {diag_tickTime >= _deadline}) exitWith {TRUE};
		uiSleep 0.05;
		FALSE
	};
	if (
		isNull _projectile ||
		{(owner _projectile) isNotEqualTo _sender} ||
		{!(_aircraft isKindOf 'Air')}
	) exitWith {};
	private _simulation = toLowerANSI (getText (configFile >> 'CfgAmmo' >> (typeOf _projectile) >> 'simulation'));
	if ((_simulation isNotEqualTo 'shotmissile') && {!(_projectile isKindOf 'BombCore')}) exitWith {};

	// Claim the relay atomically so repeated reports can share this object only once.
	isNil {
		if (isNull _projectile || {_projectile getVariable ['QS_aircraftProjectileRelayed',FALSE]}) exitWith {};
		_projectile setVariable ['QS_aircraftProjectileRelayed',TRUE,FALSE];
		private _recipients = [];
		{
			private _ownerId = owner _x;
			if ((_ownerId > 2) && {_ownerId isNotEqualTo _sender} && {!(_x isKindOf 'HeadlessClient_F')}) then {
				_recipients pushBackUnique _ownerId;
			};
		} forEach allPlayers;
		if (_recipients isNotEqualTo []) then {
			[_projectileId] remoteExecCall ['QS_fnc_clientReceiveAircraftProjectile',_recipients,FALSE];
		};
		if (hasInterface && {_sender isNotEqualTo clientOwner}) then {
			[_projectile,TRUE,TRUE,FALSE] call QS_fnc_clientTrackProjectile;
		};
	};
};
