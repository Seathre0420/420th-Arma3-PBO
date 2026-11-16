/*
File: fn_clientHeartbeat.sqf
Author:
	
	Quiksilver
	
Last Modified:

	28/05/2017 A3 1.70 by Quiksilver

Description:

	Client Heart Beat
__________________________________________________________*/

if (isDedicated) exitWith {};
if (!hasInterface) exitWith {};
private _shouldReport = FALSE;
private _shouldEnd = FALSE;
private _timeNow = time;
private _logEvent = {
	params ['_event','_heartbeat','_elapsed'];
	diag_log format [
		'QS HEARTBEAT %1 missionTime=%2 serverTime=%3 heartbeat=%4 age=%5 graceElapsed=%6 fps=%7 activeScripts=%8 sqfScripts=%9 sqsScripts=%10 fsmScripts=%11 weapon=%12 magazine=%13 inShootingRange=%14',
		_event,time,serverTime,_heartbeat,time - _heartbeat,_elapsed,diag_fps,diag_activeScripts,
		count diag_activeSQFScripts,count diag_activeSQSScripts,count diag_activeMissionFSMs,
		currentWeapon player,currentMagazine player,player inArea 'QS_marker_base_firing_area'
	];
};
// Commit state without scheduler suspension, including across overlapping RPCs.
isNil {
	_timeNow = time;
	private _heartbeat = missionNamespace getVariable ['QS_client_heartbeat',-1];
	// [first failure real time, heartbeat at failure, confirmation reported]
	private _failure = missionNamespace getVariable ['QS_client_heartbeatFailure',[]];
	if ((_timeNow <= 120) || {abs (_timeNow - _heartbeat) <= 60}) exitWith {
		missionNamespace setVariable ['QS_client_heartbeatFailure',[],FALSE];
		if (_failure isNotEqualTo []) then {
			['recovered',_heartbeat,diag_tickTime - (_failure # 0)] call _logEvent;
		};
	};
	if (_failure isEqualTo []) exitWith {
		missionNamespace setVariable ['QS_client_heartbeatFailure',[diag_tickTime,_heartbeat,FALSE],FALSE];
		['suspected stall',_heartbeat,0] call _logEvent;
	};
	if ((_failure # 2) || {(diag_tickTime - (_failure # 0)) < 60}) exitWith {};
	missionNamespace setVariable ['QS_client_heartbeatFailure',[_failure # 0,_failure # 1,TRUE],FALSE];
	['confirmed stall',_heartbeat,diag_tickTime - (_failure # 0)] call _logEvent;
	_shouldReport = TRUE;
	private _heartAttacks = missionNamespace getVariable ['QS_heartAttacks',0];
	_shouldEnd = _heartAttacks < 3;
	if (_shouldEnd) then {
		missionNamespace setVariable ['QS_heartAttacks',_heartAttacks + 1,TRUE];
	};
};
if (!_shouldReport) exitWith {};
[
	40,
	[_timeNow,serverTime,name player,profileName,profileNameSteam,getPlayerUID player,1,localize 'STR_QS_Menu_117',player]
] remoteExec ['QS_fnc_remoteExec',2,FALSE];
if (_shouldEnd) then {
	with uiNamespace do {
		uiSleep 0.1;
		[
			localize 'STR_QS_Menu_116',
			localize 'STR_QS_Menu_109',
			TRUE,FALSE,findDisplay 46,FALSE,FALSE
		] call (missionNamespace getVariable 'BIS_fnc_GUImessage');
	};
	endMission 'QS_RD_end_2';
};
