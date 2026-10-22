/*
File: fn_eventEntityRespawned.sqf
Author:

	Quiksilver
	
Last modified:

	30/03/2017 A3 1.68 by Quiksilver
	
Description:

	Event Entity Respawned
__________________________________________________*/

params ['_newEntity','_oldEntity'];
missionNamespace setVariable ['QS_analytics_entities_respawned',((missionNamespace getVariable 'QS_analytics_entities_respawned') + 1),FALSE];
missionNamespace setVariable ['QS_system_entitiesRespawned',((missionNamespace getVariable ['QS_system_entitiesRespawned',0]) + 1),FALSE];
if (!isNull _newEntity) then {
	if (isPlayer _newEntity) then {
		// Rebuild cosmetic status from the server whitelist on the new unit.
		if (isServer) then {
   _newEntity setVariable ['QS_loginStarted',_oldEntity getVariable ['QS_loginStarted',FALSE]];
   private _reply = +(_oldEntity getVariable ['QS_loginReply',[]]);
   if (_reply isNotEqualTo []) then {_reply set [4,_newEntity];};
   _newEntity setVariable ['QS_loginReply',_reply];
   _newEntity setVariable ['QS_roleSession',_oldEntity getVariable ['QS_roleSession',-1]];
   private _state = _oldEntity getVariable ['QS_roleState',[]];
   if (_state isNotEqualTo []) then {
    _newEntity setVariable ['QS_unit_role',_state # 5,TRUE];
    _newEntity setVariable ['QS_unit_side',_state # 4,TRUE];
    ['PUBLISH',_newEntity,'respawn'] call QS_fnc_roles;
    if ((_state # 5) isEqualTo 'pilot_plane' && {(missionNamespace getVariable ['QS_CAS_exhaustedAssignment',[]]) isEqualTo _state}) then {
     missionNamespace setVariable ['QS_CAS_exhaustedAssignment',_newEntity getVariable ['QS_roleState',[]]];
    };
    private _jet = missionNamespace getVariable ['QS_casJet',objNull];
    if (!isNull _jet && {(_jet getVariable ['QS_casAssignment',[]]) isEqualTo _state} && {(_state # 5) isEqualTo 'pilot_plane'}) then {
     _jet setVariable ['QS_casAssignment',_newEntity getVariable ['QS_roleState',[]]];
    };
   };
			_newEntity setVariable ['QS_isDonator',(getPlayerUID _newEntity) in (['DONATOR'] call (missionNamespace getVariable 'QS_fnc_whitelist')),TRUE];
		};
		['SERVER_SYNC',_newEntity] call (missionNamespace getVariable 'QS_fnc_serverPrivateChannels');
		missionNamespace setVariable ['QS_playerRespawnCountServer',((missionNamespace getVariable 'QS_playerRespawnCountServer') + 1),FALSE];
		if ((_newEntity getVariable ['QS_unit_role','']) isEqualTo 'pilot_plane') then {
			if (_oldEntity isEqualTo QS_fighterPilot) then {
				missionNamespace setVariable ['QS_fighterPilot',_newEntity,TRUE];
			};
		};
		if (allCurators isNotEqualTo []) then {
			{
				if (!isNull (getAssignedCuratorUnit _x)) then {
					_x addCuratorEditableObjects [[_newEntity],FALSE];
				};
			} count allCurators;
			if ((getPlayerUID _newEntity) in (['CURATOR'] call (missionNamespace getVariable 'QS_fnc_whitelist'))) then {
				[_newEntity,_oldEntity] spawn {
					params ['_newEntity','_oldEntity'];
					private _module = objNull;
					scriptName 'EventEntityRespawned * Reassigning Curator';
					_module = getAssignedCuratorLogic _oldEntity;
					if (isNull _module) then {
						_module = (allCurators select {(owner _x) isEqualTo (owner _newEntity)}) # 0;
					};
					if (!isNull _module) then {
						waitUntil {
							unassignCurator _module; 
							(isNull (getAssignedCuratorUnit _module)) || 
							(isNull _module)
						};
						waitUntil {
							_newEntity assignCurator _module; 
							((getAssignedCuratorUnit _module) isEqualTo _newEntity) || 
							(isNull _module)
						};
					};
				};
			};
		};
	};
};
