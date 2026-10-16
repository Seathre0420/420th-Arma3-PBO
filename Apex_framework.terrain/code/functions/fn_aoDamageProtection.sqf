/*
 * Classic Primary AO damage gate. Spawn callers pass their captured AO epoch;
 * shared unit/composition helpers inherit _QS_classicDamageEpoch through call.
 * Aircraft, AA operators, the commander and objective objects keep their rules.
 * Only the server registers entities or changes the one-way AO state.
 */
params [['_mode',''],['_arg',objNull],['_epoch',-1]];
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {FALSE};
private _context = missionNamespace getVariable ['QS_classicDamage_context',[-1,FALSE,TRUE,[]]];

if (_mode isEqualTo 'LOCKED') exitWith {
	_context # 1 && {!(_context # 2)} &&
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
	private _entry = _handlers getOrDefault [_arg,[-1,-1,-1]];
	private _current = (_arg getVariable ['QS_classicDamage_epoch',-2]) isEqualTo _epoch;
	private _locked = _current && {['LOCKED',_arg] call QS_fnc_aoDamageProtection};
	if (!_locked) exitWith {
		if ((_entry # 0) isEqualTo _epoch) then {
			_arg removeEventHandler ['HandleDamage',_entry # 1];
			_arg removeEventHandler ['Local',_entry # 2];
			_arg removeEventHandler ['Deleted',_entry # 3];
			_handlers deleteAt _arg;
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
		private _deletedEH = _arg addEventHandler ['Deleted',{
			params ['_entity'];
			(missionNamespace getVariable ['QS_classicDamage_localHandlers',createHashMap]) deleteAt _entity;
		}];
		_handlers set [_arg,[_epoch,_damageEH,_localEH,_deletedEH]];
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
	// One lightweight monitor per locked AO, independent of yielding spawn scripts.
	[_next] spawn {
		params ['_epoch'];
		while {['TICK',objNull,_epoch] call QS_fnc_aoDamageProtection} do {uiSleep 1;};
	};
	_next
};
if (_mode isEqualTo 'REGISTER') exitWith {
	if (_epoch < 0 || {_epoch isNotEqualTo (_context # 0)} || {!(_context # 1)} || {_context # 2}) exitWith {};
	private _entities = missionNamespace getVariable ['QS_classicDamage_entities',[]];
	private _expanded = +_arg;
	{if (!isNull _x && {!(_x isKindOf 'CAManBase')}) then {_expanded append (crew _x);};} forEach _arg;
	{
		private _entity = _x;
		if (!isNull _entity && {!isPlayer _entity} &&
			{(_entity isKindOf 'CAManBase') || {_entity isKindOf 'LandVehicle'} || {_entity isKindOf 'Ship'}} &&
			{(side (group _entity)) in [EAST,RESISTANCE] ||
				{!(_entity isKindOf 'CAManBase') && {(getNumber (configOf _entity >> 'side')) in [0,2]}}} &&
			{!(['EXEMPT',_entity] call QS_fnc_aoDamageProtection)} &&
			{(_entity getVariable ['QS_classicDamage_epoch',-2]) isNotEqualTo _epoch}) then {
			private _jipID = format ['QS_classicDamage_%1_%2',_epoch,netId _entity];
			_entities pushBack [_entity,_jipID];
			_entity setVariable ['QS_classicDamage_epoch',_epoch,TRUE];
			_entity setVariable ['QS_classicDamage_protected',TRUE,TRUE];
			// Protect synchronously before the caller positions/exposes the entity.
			['LOCAL',_entity,_epoch] call QS_fnc_aoDamageProtection;
			['LOCAL',_entity,_epoch] remoteExecCall ['QS_fnc_aoDamageProtection',-2,_jipID];
		};
	} forEach _expanded;
	missionNamespace setVariable ['QS_classicDamage_entities',_entities];
};
if (_mode isEqualTo 'TICK') exitWith {
	if (_epoch isNotEqualTo (_context # 0) || {!(_context # 1)} || {_context # 2}) exitWith {FALSE};
	if ((missionNamespace getVariable ['QS_mission_aoType','']) isNotEqualTo 'CLASSIC' ||
		{missionNamespace getVariable ['QS_defendActive',FALSE]} ||
		{missionNamespace getVariable ['QS_customAO_active',FALSE]} ||
		{missionNamespace getVariable ['QS_aoSuspended',FALSE]} ||
		{missionNamespace getVariable ['QS_aoCycleVar',FALSE]}) exitWith {
		['STOP'] call QS_fnc_aoDamageProtection; FALSE
	};
	private _center = _context # 3;
	private _arrived = (allPlayers findIf {
		isPlayer _x && {!(_x isKindOf 'HeadlessClient_F')} && {alive _x} &&
		{isNull (objectParent _x)} &&
		{isTouchingGround _x} && {(_x distance2D _center) <= 2000}
	}) >= 0;
	if (_arrived) then {['UNLOCK'] call QS_fnc_aoDamageProtection;};
	!_arrived
};
if (_mode in ['UNLOCK','STOP']) exitWith {
	_context set [1,_mode isEqualTo 'UNLOCK'];
	_context set [2,TRUE];
	missionNamespace setVariable ['QS_classicDamage_context',_context,TRUE];
	{
		_x params ['_entity','_jipID'];
		if (!isNull _entity && {(_entity getVariable ['QS_classicDamage_epoch',-2]) isEqualTo (_context # 0)}) then {
			_entity setVariable ['QS_classicDamage_protected',FALSE,TRUE];
			['LOCAL',_entity,_context # 0] call QS_fnc_aoDamageProtection;
			['LOCAL',_entity,_context # 0] remoteExecCall ['QS_fnc_aoDamageProtection',-2,FALSE];
		};
		// Remove persistent installation even when a build was cancelled/deleted.
		remoteExec ['',_jipID];
	} forEach (missionNamespace getVariable ['QS_classicDamage_entities',[]]);
	missionNamespace setVariable ['QS_classicDamage_entities',[]];
};
