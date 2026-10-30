/*
Read-only despawn diagnostics. CONTEXT returns the exact original deleteVehicle
operand (object or array); deletion still executes at its original call site.
Only the server emits RPT records. Remote reports cannot create deletion events.
Snapshot layout is deliberately fixed and bounded; capture before references die.
*/
params [['_mode',''],['_value',objNull],['_reason','UNKNOWN'],['_source',''],['_detail',[]]];
if (_mode isEqualTo 'SNAPSHOT') exitWith {
	private _v = _value;
	private _uid = _v getVariable ['QS_spawnMenu_spawnedBy',''];
	private _ownerUnit = objNull;
	if (_uid isNotEqualTo '') then {
		private _index = allPlayers findIf {getPlayerUID _x isEqualTo _uid};
		if (_index >= 0) then {_ownerUnit = allPlayers # _index;};
	};
	[serverTime,typeOf _v,netId _v,owner _v,getPosWorld _v,alive _v,damage _v,
		_uid,if (isNull _ownerUnit) then {''} else {name _ownerUnit},
		if (isNull _ownerUnit) then {-1} else {_ownerUnit distance2D _v},
		(fullCrew _v) apply {[_x # 1,_x # 2,_x # 3,netId (_x # 0),name (_x # 0),getPlayerUID (_x # 0)]},
		netId (attachedTo _v),_v getVariable ['QS_logistics_deployed',FALSE],
		_v getVariable ['QS_logistics_packed',FALSE],isSimpleObject _v,vehicleVarName _v]
};
if (_mode isEqualTo 'CONTEXT') exitWith {
	private _requester = if (hasInterface) then {player} else {objNull};
	if (isServer && {isRemoteExecuted} && {remoteExecutedOwner > 2}) then {
		private _index = allPlayers findIf {owner _x isEqualTo remoteExecutedOwner};
		if (_index >= 0) then {_requester = allPlayers # _index;};
	};
	_detail = _detail + ['requester',[getPlayerUID _requester,name _requester,remoteExecutedOwner]];
	{
		private _v = _x;
		if (!isNull _v && {(_v getVariable ['QS_vehicle',FALSE]) || {_v getVariable ['QS_logistics_wreck',FALSE]} || {(['LandVehicle','Air','Ship','StaticWeapon','ParachuteBase'] findIf {_v isKindOf _x}) >= 0}}) then {
			private _snapshot = ['SNAPSHOT',_v] call QS_fnc_vehicleDespawnLog;
			if (isServer) then {
				_v setVariable ['QS_despawn_context',[_snapshot,_reason,_source,_detail]];
				// Simple objects have no EntityDeleted event. Verify actual deletion later.
				if (isSimpleObject _v) then {['DELETED',_v] call QS_fnc_vehicleDespawnLog;};
			} else {
				if (local _v && {(_snapshot # 2) isNotEqualTo '0:0'}) then {
					['REPORT',_snapshot,_reason,_source,_detail] remoteExecCall ['QS_fnc_vehicleDespawnReport',2,FALSE];
				};
			};
		};
	} forEach (if (_value isEqualType []) then {_value} else {[_value]});
	_value
};
if (!isServer) exitWith {};
if (_mode isEqualTo 'UNPACKED') exitWith {_value setVariable ['QS_despawn_packedLogged',FALSE];};
if (_mode isEqualTo 'PACKED') exitWith {
	if (!isNull _value && {isObjectHidden _value} && {!(_value getVariable ['QS_despawn_packedLogged',FALSE])}) then {
		_value setVariable ['QS_despawn_packedLogged',TRUE];
		private _sequence = (serverNamespace getVariable 'QS_despawn_sequence') + 1;
		serverNamespace setVariable ['QS_despawn_sequence',_sequence];
		diag_log format ['[VEHICLE DESPAWN] trace=P%1 reason=PACKED source=fn_logisticsPackVehicle.sqf snapshot=%2',_sequence,['SNAPSHOT',_value] call QS_fnc_vehicleDespawnLog];
	};
};
if (_mode isEqualTo 'DELETED') exitWith {
	private _v = if (_value isEqualType []) then {_value param [0,objNull]} else {_value};
	if (isNull _v || {!(_v getVariable ['QS_vehicle',FALSE]) && {!(_v getVariable ['QS_logistics_wreck',FALSE])} && {(['LandVehicle','Air','Ship','StaticWeapon','ParachuteBase'] findIf {_v isKindOf _x}) < 0}}) exitWith {};
	private _pending = serverNamespace getVariable 'QS_despawn_pending';
	private _key = _v getVariable ['QS_despawn_key',''];
	if (_key isEqualTo '') then {
		private _sequence = (serverNamespace getVariable 'QS_despawn_sequence') + 1;
		serverNamespace setVariable ['QS_despawn_sequence',_sequence];
		_key = format ['V%1',_sequence];
		_v setVariable ['QS_despawn_key',_key];
	};
	if (isNil {_pending get _key}) then {
		private _context = _v getVariable ['QS_despawn_context',[
			['SNAPSHOT',_v] call QS_fnc_vehicleDespawnLog,'UNKNOWN','EntityDeleted',[]]];
		if (abs (serverTime - ((_context # 0) # 0)) > 5) then {
			_context = [['SNAPSHOT',_v] call QS_fnc_vehicleDespawnLog,'UNKNOWN','EntityDeleted',[]];
		};
		_pending set [_key,[diag_tickTime,_v,_context]];
	};
};
if (_mode isEqualTo 'FLUSH') then {
	private _pending = serverNamespace getVariable 'QS_despawn_pending';
	private _reports = serverNamespace getVariable 'QS_despawn_reports';
	{
		(_pending get _x) params ['_at','_object','_context'];
		if (diag_tickTime - _at >= 2) then {
			if (isNull _object) then {
				_context params ['_snapshot','_why','_where','_facts'];
				private _report = _reports getOrDefault [_snapshot # 2,[]];
				if (_why isEqualTo 'UNKNOWN' && {_report isNotEqualTo []} &&
					{abs ((_report # 0) - _at) < 5} && {((_report # 1) # 1) isEqualTo (_snapshot # 1)} && {(_report # 5) isEqualTo (_snapshot # 3)}) then {
					_snapshot = _report # 1; _why = _report # 2; _where = _report # 3; _facts = _report # 4;
				};
				diag_log format ['[VEHICLE DESPAWN] trace=%1 reason=%2 source=%3 snapshot=%4 detail=%5',_x,_why,_where,_snapshot,_facts];
				_reports deleteAt (_snapshot # 2);
			};
			_pending deleteAt _x;
		};
	} forEach (keys _pending);
	{if (diag_tickTime - ((_reports get _x) # 0) > 10) then {_reports deleteAt _x;};} forEach (keys _reports);
};
