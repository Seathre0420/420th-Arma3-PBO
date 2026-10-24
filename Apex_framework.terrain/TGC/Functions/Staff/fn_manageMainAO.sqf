/*
Function: TGC_fnc_manageMainAO

Description:
    Cycle, pause, or guarantee a Defend for the Main AO from a validated staff request.
*/
params [["_action", "", [""]]];
if (!isServer) exitWith {};

private _owner = remoteExecutedOwner;
private _requestingPlayer = objNull;
{
    if ((owner _x) isEqualTo _owner) exitWith {
        _requestingPlayer = _x;
    };
} forEach allPlayers;

if ((isNull _requestingPlayer) || {!((getPlayerUID _requestingPlayer) in (["ALL"] call QS_fnc_whitelist))}) exitWith {};
if (!(_action in ["CYCLE", "PAUSE", "FORCE_DEFEND", "QUEUE_DEFEND"])) exitWith {};

if (!((missionNamespace getVariable ["QS_missionConfig_aoType", "ZEUS"]) in ["CLASSIC", "SC", "GRID"])) exitWith {
    ["systemChat", "Main AOs are disabled by the server configuration."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
};
if (missionNamespace getVariable ["QS_customAO_active", false]) exitWith {
    ["systemChat", "The Main AO cannot be managed while a custom AO is active."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
};

private _defendLogAO = missionNamespace getVariable ["QS_defendLogAO", ["UNKNOWN",-1,false]];
private _logCancelledDefend = {
    private _pendingRequest = missionNamespace getVariable ["QS_staffDefendRequest", 0];
    if (_pendingRequest > 0) then {
        diag_log format ["[Defend] STAFF_CANCEL missionTime=%1 ao=%2 epoch=%3 request=%4 staff=%5 cancelledBy=%6 cancelledByUID=%7 reason=%8",time,_defendLogAO # 0,_defendLogAO # 1,_pendingRequest,missionNamespace getVariable ["QS_staffDefendLogRequest", []],name _requestingPlayer,getPlayerUID _requestingPlayer,_action];
    };
    missionNamespace setVariable ["QS_staffDefendLogRequest", []];
};

switch _action do {
    case "CYCLE": {
        if (missionNamespace getVariable ["QS_aoSuspended", false]) exitWith {
            ["systemChat", "Main AO spawning is paused."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };

        call _logCancelledDefend;
        missionNamespace setVariable ["QS_staffDefendRequest", 0, false];
        missionNamespace setVariable ["QS_aoCycleVar", true, true];
        ["systemChat", format ["%1 (staff) cycled the Main AO", name _requestingPlayer]] remoteExec ["QS_fnc_remoteExecCmd", -2, false];
    };
    case "PAUSE": {
        if (missionNamespace getVariable ["QS_aoSuspended", false]) exitWith {
            ["systemChat", "Main AO spawning is already paused."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };

        call _logCancelledDefend;
        missionNamespace setVariable ["QS_staffDefendRequest", 0, false];
        missionNamespace setVariable ["QS_aoSuspended", true, true];
        missionNamespace setVariable ["QS_aoCycleVar", true, true];
        private _forceBefore = missionNamespace getVariable ["QS_forceDefend", 0];
        missionNamespace setVariable ["QS_forceDefend", -1, true];
        if (_forceBefore isNotEqualTo -1) then {
            diag_log format ["[Defend] FORCE_CHANGE missionTime=%1 ao=%2 epoch=%3 forceBefore=%4 forceAfter=-1 reason=STAFF_PAUSE",time,_defendLogAO # 0,_defendLogAO # 1,_forceBefore];
        };
        missionNamespace setVariable ["QS_defendLogForceLast", -1];
        ["systemChat", format ["%1 (staff) paused Main AO spawning", name _requestingPlayer]] remoteExec ["QS_fnc_remoteExecCmd", -2, false];
    };
    case "FORCE_DEFEND";
    case "QUEUE_DEFEND": {
        if ((missionNamespace getVariable ["QS_mission_aoType", "ZEUS"]) isNotEqualTo "CLASSIC") exitWith {
            ["systemChat", "Defend management is only available for Classic Main AOs."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };
        if (missionNamespace getVariable ["QS_aoSuspended", false]) exitWith {
            ["systemChat", "Main AO spawning is paused."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };
        if (missionNamespace getVariable ["QS_defendActive", false]) exitWith {
            ["systemChat", "A Defend is already active."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };
        if (missionNamespace getVariable ["QS_megaDefense_pending", false]) exitWith {
            ["systemChat", "A Defense transition is already pending."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };

        private _coreState = missionNamespace getVariable ["QS_megaDefense_core", ["IDLE", -1, []]];
        if (!(_coreState isEqualType [] && {count _coreState isEqualTo 3} && {(_coreState # 0) isEqualTo "PRIMARY"})) exitWith {
            ["systemChat", "There is no active Classic Main AO ready for Defend."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };
        if ((missionNamespace getVariable ["QS_staffDefendRequest", 0]) > 0) exitWith {
            ["systemChat", "A Defend is already queued for the current AO."] remoteExec ["QS_fnc_remoteExecCmd", _owner, false];
        };

        private _forceNow = _action isEqualTo "FORCE_DEFEND";
        missionNamespace setVariable ["QS_staffDefendRequest", [1, 2] select _forceNow, false];
        private _requestLog = [_action,name _requestingPlayer,getPlayerUID _requestingPlayer,_coreState # 1];
        missionNamespace setVariable ["QS_staffDefendLogRequest", _requestLog];
        diag_log format ["[Defend] STAFF_REQUEST missionTime=%1 ao=%2 epoch=%3 action=%4 staff=%5 uid=%6 request=%7 force=%8 source=420TH_STAFF_MENU",time,_defendLogAO # 0,_coreState # 1,_action,name _requestingPlayer,getPlayerUID _requestingPlayer,[1,2] select _forceNow,missionNamespace getVariable ["QS_forceDefend", 0]];
        ["systemChat", format [
            ["%1 (staff) queued a Defend for the current Main AO", "%1 (staff) forced the current Main AO into Defend"] select _forceNow,
            name _requestingPlayer
        ]] remoteExec ["QS_fnc_remoteExecCmd", -2, false];
    };
};
