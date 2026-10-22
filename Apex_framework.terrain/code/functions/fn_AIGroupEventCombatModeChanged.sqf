/*/
File: fn_AIGroupEventCombatModeChanged.sqf
Author:

	Quiksilver
	
Last Modified:

	22/08/2022 A3 2.10 by Quiksilver
	
Description:

	AI Group Event Combat Mode Changed
___________________________________________/*/

params [['_grp',grpNull],['_newMode','']];
_grp setVariable ['QS_AI_GRP_EH_CMC_cooldown',serverTime + 180,FALSE];
_grp removeEventHandler [_thisEvent,_thisEventHandler];
if (missionNamespace getVariable ['QS_defendControl_active',FALSE] &&
    {(_grp getVariable ['QS_defendAssault_epoch',-2]) isEqualTo (missionNamespace getVariable ['QS_defendControl_epoch',-1])}) exitWith {};
if (_newMode isEqualTo 'COMBAT') then {
	if (isNull (objectParent (leader _grp))) then {
		_grp setFormation (selectRandomWeighted ['WEDGE',1,'LINE',2]);
	};
	{
		if (
			(alive _x) &&
			{(
				(_x getVariable ['QS_AI_UNIT_isMG',FALSE]) || 
				{(_x getVariable ['QS_AI_UNIT_isGL',FALSE])} ||
				{((random 1) > 0.95)}
			)}
		) then {
			if (((_x getEventHandlerInfo ['FiredMan',0]) # 2) isEqualTo 0) then {
				_x addEventHandler ['FiredMan',{call (missionNamespace getVariable 'QS_fnc_AIXSuppressiveFire')}];
			};
		};
	} forEach (units _grp);
};