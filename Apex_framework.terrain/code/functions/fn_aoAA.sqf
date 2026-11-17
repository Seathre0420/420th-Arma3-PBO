/* Reserve and create the complete Classic AO AA allocation before activation.
 * Result: [success, reason, requestedTeams]. No asynchronous spawn workers.
 */
if ((_this # 0) isEqualTo 'CANCEL') exitWith {
	if (!isServer) exitWith {};
	private _pending = missionNamespace getVariable ['QS_classic_aaGroups',[-1,[]]];
	private _cancelEpoch = _this param [1,-1];
	if (_cancelEpoch >= 0 && {_cancelEpoch isNotEqualTo (_pending # 0)}) exitWith {};
	missionNamespace setVariable ['QS_classic_aaGroups',[-1,[]],FALSE];
	{private _group = _x; {deleteVehicle _x;} forEach units _group; deleteGroup _group;} forEach (_pending # 1);
};
params ['_center','_radius','_epoch'];
if (!isServer) exitWith {[FALSE,'NOT_SERVER',0]};
private _players = count (allPlayers select {!(_x isKindOf 'HeadlessClient_F')});
private _count = 1 + ((floor (_players / 10)) min 9);
private _owner = format ['CLASSIC_AA_%1',_epoch];
private _deadline = diag_tickTime + 10;
private _plans = [];
private _groups = [];
private _reason = '';
private _fn_current = {
	private _context = missionNamespace getVariable ['QS_classicDamage_context',[-1,FALSE]];
	(_context # 0) isEqualTo _epoch && {_context # 1} &&
	{!(missionNamespace getVariable ['QS_aoSuspended',FALSE])} &&
	{!(missionNamespace getVariable ['QS_aoCycleVar',FALSE])} &&
	{!(missionNamespace getVariable ['QS_customAO_active',FALSE])}
};
private _fn_valid = {
	params ['_point'];
	(_point distance2D _center) < (_radius * 1.5) &&
	{['BLACKLIST',_point] call QS_fnc_findRandomPos}
};
// Sample anchors directly. Each bounded footprint search receives the same
// absolute deadline; no nested thirty-second random-position searches.
while {count _plans < _count && {diag_tickTime < _deadline} && {call _fn_current}} do {
	private _anchor = _center getPos [sqrt (random 1) * _radius,random 360];
	private _heading = random 360;
	private _slots = ['SLOTS',_anchor,4,_heading,'O_Soldier_F',TRUE,FALSE,-1,_fn_valid,_deadline,_owner] call QS_fnc_spawnGroup;
	if (_slots isNotEqualTo []) then {_plans pushBack [_anchor,_heading,_slots];};
};
if (count _plans isNotEqualTo _count) then {_reason = 'PLACEMENT_DEADLINE';};
if (!(call _fn_current)) then {_reason = 'CANCELLED';};
if (_reason isEqualTo '') then {
	{
		if (!(call _fn_current)) exitWith {_reason = 'CANCELLED';};
		_x params ['_anchor','_heading','_slots'];
		// The helper consumes the matching reservation and creates atomically.
		// Fresh units ensure all four requested class roles can be checked.
		private _grp = [_anchor,_heading,EAST,'oia_infteam_aa',FALSE,grpNull,FALSE,TRUE,_fn_valid,-1,[_owner,_slots]] call QS_fnc_spawnGroup;
		if (!isNull _grp) then {_groups pushBack _grp;};
		if (isNull _grp || {count units _grp isNotEqualTo 4}) exitWith {_reason = 'INCOMPLETE_GROUP';};
		private _composition = QS_core_groups_map get 'oia_infteam_aa';
		private _units = units _grp;
		// findIf does not supply _forEachIndex: the old check inherited the
		// outer plan index and compared every role with the same soldier.
		// Compare sorted class lists, preserving duplicates without relying on
		// the engine's group-member ordering.
		private _expectedClasses = _composition apply {
			private _class = _x # 0;
			toLowerANSI (QS_core_units_map getOrDefault [toLowerANSI _class,_class])
		};
		private _actualClasses = _units apply {toLowerANSI (typeOf _x)};
		_expectedClasses sort TRUE;
		_actualClasses sort TRUE;
		if (_actualClasses isNotEqualTo _expectedClasses) exitWith {
			diag_log format ['[ClassicAA] Composition mismatch expected=%1 actual=%2',_expectedClasses,_actualClasses];
			_reason = 'WRONG_COMPOSITION';
		};
		{_x enableSimulationGlobal FALSE;} forEach _units;
	} forEach _plans;
};
if (!(call _fn_current)) then {_reason = 'CANCELLED';};
// Owner-tagged claims cannot expire during planning. Release every unused claim
// on both outcomes; successfully created units now occupy consumed footprints.
isNil {
	missionNamespace setVariable ['QS_groundSpawn_claims',
		(missionNamespace getVariable ['QS_groundSpawn_claims',[]]) select {(_x param [4,'']) isNotEqualTo _owner},FALSE];
};
if (_reason isNotEqualTo '') exitWith {
	{private _group = _x; {deleteVehicle _x;} forEach units _group; deleteGroup _group;} forEach _groups;
	diag_log format ['[ClassicAA] PREPARATION_FAILED epoch=%1 teams=%2 reason=%3',_epoch,_count,_reason];
	[FALSE,_reason,_count]
};
missionNamespace setVariable ['QS_classic_aaGroups',[_epoch,_groups],FALSE];
missionNamespace setVariable ['QS_classic_aaAllocation',[_epoch,_players,_count],FALSE];
diag_log format ['[ClassicAA] PREPARED epoch=%1 players=%2 teams=%3',_epoch,_players,_count];
[TRUE,'',_count]
