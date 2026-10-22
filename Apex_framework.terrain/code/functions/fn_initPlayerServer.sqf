/*/
File: fn_initPlayerServer.sqf
Author:

	Quiksilver
	
Last modified:

	24/05/2023 A3 2.12 by Quiksilver
	
Description:

	Init Player Server
__________________________________________________/*/

scriptName 'QS InitPlayerServer';
params ['_client','_jip','_cid','_uid','_profileName'];
if (!(missionNamespace getVariable ['QS_mission_init',FALSE])) then {
	waitUntil {
		uiSleep 0.1;
		(missionNamespace getVariable ['QS_mission_init',FALSE])
	};
};
if (_client isKindOf 'HeadlessClient_F') exitWith {diag_log 'Headless client connecting - exiting QS_fnc_initPlayerServer.sqf';};
_t = diag_tickTime + 15;
waitUntil {
	uiSleep 0.1;
	((!isNull _client) || {(diag_tickTime > _t)})
};
if (isNull _client || {!isPlayer _client} || {owner _client isNotEqualTo _cid} || {getPlayerUID _client isNotEqualTo _uid}) exitWith {};
private _first = FALSE;
isNil {
 if (!(_client getVariable ['QS_loginStarted',FALSE])) then {
  _client setVariable ['QS_loginStarted',TRUE];
  private _session = (missionNamespace getVariable ['QS_loginSerial',0]) + 1;
  missionNamespace setVariable ['QS_loginSerial',_session];
  _client setVariable ['QS_roleSession',_session];
  _first = TRUE;
 };
};
if (!_first) exitWith {
 private _reply = _client getVariable ['QS_loginReply',[]];
 if (_reply isNotEqualTo []) then {[125,_reply] remoteExec ['QS_fnc_remoteExec',_cid,FALSE];};
};
// Covers players whose whitelist query finished before their unit existed,
// as well as servers using the static whitelist. Late DB results update this.
if (isServer) then {
	_client setVariable ['QS_isDonator',_uid in (['DONATOR'] call (missionNamespace getVariable 'QS_fnc_whitelist')),TRUE];
};
if (allCurators isNotEqualTo []) then {
	{
		if (!isNull (getAssignedCuratorUnit _x)) then {
			_x addCuratorEditableObjects [[_client],FALSE];
		};
	} count allCurators;
};
//===== ROBOCOP
_val = QS_robocop getOrDefault [_uid,0,TRUE];
if (_val > 5) exitWith {
	FALSE remoteExecCall ['disableUserInput',_cid,FALSE];
	uiSleep 0.1;
	(call (uiNamespace getVariable 'QS_fnc_serverCommandPassword')) serverCommand (format ['#kick %1',_cid]);
};
//===== Supporter Level
private _sLevel = 0;
if (_uid in (['S3'] call (missionNamespace getVariable 'QS_fnc_whitelist'))) then {
	_sLevel = 2;
};
if (_cid < 3) exitWith {
	diag_log format ['***** DEBUG ***** Invalid Client Owner: %1 *****',_cid];
};
/*/ EXTDB3 - Database - Client Registry could go here /*/
['HANDLE',['HANDLE_CONNECT',_this]] call (missionNamespace getVariable 'QS_fnc_roles');
if ((missionNamespace getVariable ['QS_missionConfig_CAS',2]) isEqualTo 3) then {
	if (_uid in (['CAS'] call (missionNamespace getVariable 'QS_fnc_whitelist'))) then {		/*/EXTDB3 - Database - This is where you would check client if client is in CAS database/*/
		private _aircraftPool = 0;
		private _airIndex = (missionNamespace getVariable 'QS_CAS_jetAllowance') findIf {((_x # 0) isEqualTo _uid)};
		if (_airIndex isEqualTo -1) then {
			(missionNamespace getVariable 'QS_CAS_jetAllowance') pushBack [_uid,_aircraftPool];
		} else {
			_aircraftPool = ((missionNamespace getVariable 'QS_CAS_jetAllowance') # _airIndex) # 1;
		};
		_client setVariable ['QS_client_casAllowance',_aircraftPool,[2,_cid]];
	};
};
private _builtList = QS_hashmap_playerBuildables getOrDefault [_uid,[],TRUE];
if (_builtList isNotEqualTo []) then {
	_builtList = _builtList select {!isNull _x};
	{
		if (!isNull _x) then {
			_x setOwner _cid;
		};
	} forEach _builtList;	
	[_builtList,_cid] spawn {
		params ['_builtList','_cid'];
		private _timeout = 0;
		{
			if (!isNull _x) then {
				_timeout = diag_tickTime + 3;
				waitUntil {
					((_x setOwner _cid) || (diag_tickTime > _timeout))
				};
			};
		} forEach _builtList;
	};
	QS_hashmap_playerBuildables set [_uid,_builtList];
};
_loginVal = 998;
// Dynamic Groups
_grp = group _client;
{
	_grp setVariable _x;
} forEach [
	['BIS_dg_reg',TRUE,TRUE],
	['BIS_dg_cre',_client,TRUE],
	['BIS_dg_pri',FALSE,TRUE],
	['BIS_dg_var',format ['%1_%2_%3',groupId _grp,_uid,time],TRUE]
];
_grp setGroupIdGlobal [groupId _grp];
// Dynamic Groups
_client setVariable ['QS_5551212',_loginVal,FALSE];
_client setVariable ['QS_ClientSupporterLevel',_sLevel,FALSE];
private _notifyWhitelist = _uid in (missionProfileNamespace getVariable ['QS_whitelists_toInform',[]]);
if (_notifyWhitelist) then {
	(missionProfileNamespace getVariable 'QS_whitelists_toInform') deleteAt ((missionProfileNamespace getVariable ['QS_whitelists_toInform',[]]) find _uid);
};
// Acknowledge only once the queued default assignment has committed.
private _deadline = diag_tickTime + 20;
private _session = _client getVariable ['QS_roleSession',-1];
waitUntil {
 uiSleep 0.1;
 if (isNull _client || {!isPlayer _client}) then {
  _client = (allPlayers select {getPlayerUID _x isEqualTo _uid && {owner _x isEqualTo _cid} && {(_x getVariable ['QS_roleSession',-2]) isEqualTo _session}}) param [0,objNull];
  if (!isNull _client && {(_client getVariable ['QS_roleState',[]]) isEqualTo []}) then {
   ['HANDLE',['HANDLE_CONNECT',[_client,_jip,_cid,_uid,'']]] call QS_fnc_roles;
  };
 };
 (diag_tickTime > _deadline) || {!isNull _client && {(_client getVariable ['QS_roleState',[]]) isNotEqualTo []}}
};
if (isNull _client || {!isPlayer _client} || {owner _client isNotEqualTo _cid}) exitWith {};
if ((_client getVariable ['QS_roleState',[]]) isEqualTo []) exitWith {
 _client setVariable ['QS_loginStarted',FALSE];
 diag_log format ['ROLE INIT failed uid=%1 owner=%2 reason=assignment timeout',_uid,_cid];
};
private _reply = [[_uid,_cid,_val,_jip],_sLevel,_loginVal,_notifyWhitelist,_client,_client getVariable ['QS_roleSession',-1]];
_client setVariable ['QS_loginReply',_reply];
[125,_reply] remoteExec ['QS_fnc_remoteExec',_cid,FALSE];
