/* Ground contact is observed by the player's owner. The server validates the
 * player, distance and AO epoch before its monitor consumes this report.
 */
params [['_unit',objNull,[objNull]],['_epoch',-1,[0]]];
if (!isServer || {isNull _unit}) exitWith {FALSE};
private _caller = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _unit};
private _accepted = FALSE;
isNil {
	private _context = missionNamespace getVariable ['QS_classicDamage_context',[-1,FALSE,TRUE,[]]];
	if (_epoch isNotEqualTo (_context # 0) || {!(_context # 1)} || {_context # 2}) exitWith {};
	if ((missionNamespace getVariable ['QS_mission_aoType','']) isNotEqualTo 'CLASSIC' ||
		{missionNamespace getVariable ['QS_defendActive',FALSE]} ||
		{missionNamespace getVariable ['QS_customAO_active',FALSE]} ||
		{missionNamespace getVariable ['QS_aoSuspended',FALSE]} ||
		{missionNamespace getVariable ['QS_aoCycleVar',FALSE]}) exitWith {};
	if (!isPlayer _unit || {_unit isKindOf 'HeadlessClient_F'} || {!alive _unit} ||
		{isObjectHidden _unit} || {owner _unit isNotEqualTo _caller} ||
		{!isNull (objectParent _unit)} || {(_unit distance2D (_context # 3)) > 2000}) exitWith {};
	missionNamespace setVariable ['QS_classicDamage_arrival',[_epoch,_unit,diag_tickTime,_caller]];
	_accepted = TRUE;
};
_accepted
