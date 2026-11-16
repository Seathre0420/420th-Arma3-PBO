/*
 * Classic Primary AO damage gate. Spawn callers pass their captured AO epoch;
 * shared unit/composition helpers inherit _QS_classicDamageEpoch through call.
 * Aircraft, AA operators, the commander and objective objects keep their rules.
 * Only the server registers entities or changes the one-way AO state.
 */
params [['_mode',''],['_arg',objNull],['_epoch',-1]];
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {FALSE};
// Scheduled spawn callers must not be interrupted between checking and writing.
if (_mode in ['LOCAL','ALLOW','RELEASE'] && {canSuspend}) exitWith {
	isNil {_this call QS_fnc_aoDamageProtection;};
};
if (_mode isEqualTo 'RELEASE') then {
	// Explicit release wins even when the replicated context is still locked.
	missionNamespace setVariable ['QS_classicDamage_releasedEpoch',
		_epoch max (missionNamespace getVariable ['QS_classicDamage_releasedEpoch',-1])];
	_mode = 'LOCAL';
};
private _context = missionNamespace getVariable ['QS_classicDamage_context',[-1,FALSE,TRUE,[]]];

if (_mode isEqualTo 'LOCKED') exitWith {
	_context # 1 && {!(_context # 2)} &&
	{(_context # 0) > (missionNamespace getVariable ['QS_classicDamage_releasedEpoch',-1])} &&
	{(_arg getVariable ['QS_classicDamage_epoch',-2]) isEqualTo (_context # 0)} &&
	{_arg getVariable ['QS_classicDamage_protected',FALSE]}
};
if (_mode isEqualTo 'EXEMPT') exitWith {
	if (_arg isKindOf 'Air') exitWith {TRUE};
	if (_arg isKindOf 'CAManBase' && {
		_arg isEqualTo (missionNamespace getVariable ['QS_csatCommander',objNull]) ||
		{_arg getUnitTrait 'QS_trait_commander'}
	}) exitWith {TRUE};
	private _vehicle = _arg;
	if (_arg isKindOf 'CAManBase') then {
		_vehicle = assignedVehicle _arg;
		if (isNull _vehicle) then {_vehicle = objectParent _arg;};
		// Cargo troops remain AO infantry, including helicopter insertions.
		private _cargo = toUpperANSI ((assignedVehicleRole _arg) param [0,'']) isEqualTo 'CARGO';
		if (!_cargo && {!isNull (objectParent _arg)}) then {
			_cargo = ((fullCrew [objectParent _arg,'Cargo',FALSE]) findIf {(_x # 0) isEqualTo _arg}) >= 0;
		};
		if (_cargo) then {_vehicle = objNull;};
	};
	_vehicle isKindOf 'Air' || {(toLowerANSI (typeOf _vehicle)) in [
		'o_apc_tracked_02_aa_f','o_t_apc_tracked_02_aa_ghex_f','i_lt_01_aa_f'
	]}
};
if (_mode isEqualTo 'ALLOW') exitWith {
	// Used by existing delayed spawn callbacks; never bypass a pending AO lock.
	if (_epoch >= 0 && {!(['EXEMPT',_arg] call QS_fnc_aoDamageProtection)} &&
		{_epoch isNotEqualTo (_context # 0) || {!(_context # 1)} ||
			{(_arg getVariable ['QS_classicDamage_epoch',_epoch]) isNotEqualTo _epoch}}) exitWith {};
	if (local _arg) then {_arg allowDamage (!(['LOCKED',_arg] call QS_fnc_aoDamageProtection));};
};
if (_mode isEqualTo 'LOCAL') exitWith {
	if (isNull _arg) exitWith {};
	// Keep handler IDs outside the entity: the recycler clears all entity variables.
	private _handlers = missionNamespace getVariable ['QS_classicDamage_localHandlers',createHashMap];
	missionNamespace setVariable ['QS_classicDamage_localHandlers',_handlers];
	// SQF HashMaps do not support Object keys. Network IDs are stable strings.
	private _key = netId _arg;
	private _entry = _handlers getOrDefault [_key,[-1,-1,-1,-1]];
	private _current = (_arg getVariable ['QS_classicDamage_epoch',-2]) isEqualTo _epoch;
	private _locked = _current && {['LOCKED',_arg] call QS_fnc_aoDamageProtection};
	if (!_locked) exitWith {
		if ((_entry # 0) isEqualTo _epoch) then {
			_arg removeEventHandler ['HandleDamage',_entry # 1];
			_arg removeEventHandler ['Local',_entry # 2];
			_arg removeEventHandler ['Deleted',_entry # 3];
			_handlers deleteAt _key;
			_arg setVariable ['QS_classicDamage_handlerKey',nil,FALSE];
		};
		// A late release must never change a recycled/new AO entity's damage state.
		if (_current && {local _arg}) then {_arg allowDamage TRUE;};
	};
	if ((_entry # 0) isNotEqualTo _epoch) then {
		if ((_entry # 0) >= 0) then {
			_arg removeEventHandler ['HandleDamage',_entry # 1];
			_arg removeEventHandler ['Local',_entry # 2];
			_arg removeEventHandler ['Deleted',_entry # 3];
		};
		private _damageEH = _arg addEventHandler ['HandleDamage',{
			params ['_entity','','','','','_hitIndex'];
			if (['LOCKED',_entity] call QS_fnc_aoDamageProtection) exitWith {
				if (_hitIndex < 0) then {damage _entity} else {_entity getHitIndex _hitIndex}
			};
			// No return value after release: preserve other damage handlers.
		}];
		private _localEH = _arg addEventHandler ['Local',{
			params ['_entity','_isLocal'];
			if (_isLocal) then {
				['LOCAL',_entity,_entity getVariable ['QS_classicDamage_epoch',-1]] call QS_fnc_aoDamageProtection;
			};
		}];
		// Cache the string before deletion, when netId may no longer be available.
		_arg setVariable ['QS_classicDamage_handlerKey',_key,FALSE];
		private _deletedEH = _arg addEventHandler ['Deleted',{
			params ['_entity'];
			private _key = _entity getVariable ['QS_classicDamage_handlerKey',''];
			(missionNamespace getVariable ['QS_classicDamage_localHandlers',createHashMap]) deleteAt _key;
		}];
		_handlers set [_key,[_epoch,_damageEH,_localEH,_deletedEH]];
	};
	if (local _arg) then {_arg allowDamage FALSE;};
};

if (!isServer) exitWith {FALSE};
if (_mode isEqualTo 'START') exitWith {
	['STOP'] call QS_fnc_aoDamageProtection;
	if ((missionNamespace getVariable ['QS_mission_aoType','']) isNotEqualTo 'CLASSIC' ||
		{missionNamespace getVariable ['QS_defendActive',FALSE]}) exitWith {-1};
	private _next = 1 + (_context # 0);
	missionNamespace setVariable ['QS_classicDamage_context',[_next,TRUE,FALSE,+_arg],TRUE];
	missionNamespace setVariable ['QS_classicDamage_entities',[]];
	missionNamespace setVariable ['QS_classicDamage_arrival',[]];
	// One lightweight monitor per locked AO, independent of yielding spawn scripts.
	[_next] spawn {
		params ['_epoch'];
		while {['TICK',objNull,_epoch] call QS_fnc_aoDamageProtection} do {uiSleep 1;};
	};
	_next
};
if (_mode isEqualTo 'REGISTER') exitWith {
	if (_epoch < 0 || {_epoch isNotEqualTo (_context # 0)} || {!(_context # 1)} || {_context # 2}) exitWith {};
	private _expanded = +_arg;
	{if (!isNull _x && {!(_x isKindOf 'CAManBase')}) then {_expanded append (crew _x);};} forEach _arg;
	{
		private _entity = _x;
		// Commit one entity at a time against fresh state; bulk spawns may yield.
		isNil {
			_context = missionNamespace getVariable ['QS_classicDamage_context',[-1,FALSE,TRUE,[]]];
			if (_epoch isNotEqualTo (_context # 0) || {!(_context # 1)} || {_context # 2}) exitWith {};
			if (!isNull _entity && {!isPlayer _entity} &&
				{(_entity isKindOf 'CAManBase') || {_entity isKindOf 'LandVehicle'} || {_entity isKindOf 'Ship'}} &&
				{(side (group _entity)) in [EAST,RESISTANCE] ||
					{!(_entity isKindOf 'CAManBase') && {(getNumber (configOf _entity >> 'side')) in [0,2]}}} &&
				{!(['EXEMPT',_entity] call QS_fnc_aoDamageProtection)} &&
				{(_entity getVariable ['QS_classicDamage_epoch',-2]) isNotEqualTo _epoch}) then {
				private _jipID = format ['QS_classicDamage_%1_%2',_epoch,netId _entity];
				private _entities = missionNamespace getVariable ['QS_classicDamage_entities',[]];
				_entities pushBack [_entity,_jipID];
				missionNamespace setVariable ['QS_classicDamage_entities',_entities];
				_entity setVariable ['QS_classicDamage_epoch',_epoch,TRUE];
				_entity setVariable ['QS_classicDamage_protected',TRUE,TRUE];
				// Protect synchronously before the caller positions/exposes the entity.
				['LOCAL',_entity,_epoch] call QS_fnc_aoDamageProtection;
				['LOCAL',_entity,_epoch] remoteExecCall ['QS_fnc_aoDamageProtection',-2,_jipID];
			};
		};
	} forEach _expanded;
};
if (_mode isEqualTo 'TICK') exitWith {
	if (_epoch isNotEqualTo (_context # 0) || {!(_context # 1)} || {_context # 2}) exitWith {FALSE};
	if ((missionNamespace getVariable ['QS_mission_aoType','']) isNotEqualTo 'CLASSIC' ||
		{missionNamespace getVariable ['QS_defendActive',FALSE]} ||
		{missionNamespace getVariable ['QS_customAO_active',FALSE]} ||
		{missionNamespace getVariable ['QS_aoSuspended',FALSE]} ||
		{missionNamespace getVariable ['QS_aoCycleVar',FALSE]}) exitWith {
		['STOP',objNull,_epoch] call QS_fnc_aoDamageProtection; FALSE
	};
	private _arrival = missionNamespace getVariable ['QS_classicDamage_arrival',[]];
	private _arrived = FALSE;
	if (_arrival isNotEqualTo []) then {
		_arrival params ['_arrivalEpoch','_player','_receivedAt','_owner'];
		_arrived = _arrivalEpoch isEqualTo _epoch && {diag_tickTime - _receivedAt <= 3} &&
			{!isNull _player} && {owner _player isEqualTo _owner} &&
			{isPlayer _player} && {alive _player} && {!isObjectHidden _player} &&
			{isNull (objectParent _player)} && {(_player distance2D (_context # 3)) <= 2000};
	};
	if (_arrived) then {['UNLOCK',objNull,_epoch] call QS_fnc_aoDamageProtection;};
	!_arrived
};
if (_mode in ['UNLOCK','STOP']) exitWith {
	private _entities = [];
	private _releaseEpoch = -1;
	// Close registration and detach the list before any scheduled release work.
	isNil {
		_context = +(missionNamespace getVariable ['QS_classicDamage_context',[-1,FALSE,TRUE,[]]]);
		if (_epoch >= 0 && {_epoch isNotEqualTo (_context # 0)}) exitWith {};
		if (_mode isEqualTo 'UNLOCK' && {!(_context # 1) || {_context # 2}}) exitWith {};
		_releaseEpoch = _context # 0;
		_context set [1,_mode isEqualTo 'UNLOCK'];
		_context set [2,TRUE];
		missionNamespace setVariable ['QS_classicDamage_context',_context,TRUE];
		_entities = missionNamespace getVariable ['QS_classicDamage_entities',[]];
		missionNamespace setVariable ['QS_classicDamage_entities',[]];
		missionNamespace setVariable ['QS_classicDamage_arrival',[]];
	};
	if (_releaseEpoch < 0) exitWith {};
	if (isServer && {_mode isEqualTo 'STOP'}) then {['CANCEL',_releaseEpoch] call QS_fnc_aoAA;};
	{
		_x params ['_entity','_jipID'];
		isNil {
			if (!isNull _entity && {(_entity getVariable ['QS_classicDamage_epoch',-2]) isEqualTo _releaseEpoch}) then {
				_entity setVariable ['QS_classicDamage_protected',FALSE,TRUE];
				['RELEASE',_entity,_releaseEpoch] call QS_fnc_aoDamageProtection;
				['RELEASE',_entity,_releaseEpoch] remoteExecCall ['QS_fnc_aoDamageProtection',-2,FALSE];
			};
			// Remove persistent installation even when a build was cancelled/deleted.
			remoteExec ['',_jipID];
		};
	} forEach _entities;
};
