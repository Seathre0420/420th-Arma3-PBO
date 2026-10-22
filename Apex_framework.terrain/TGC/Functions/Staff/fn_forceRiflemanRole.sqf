/*
Function: TGC_fnc_forceRiflemanRole

Description:
    Immediately assign Rifleman through the roles system after validating staff.
*/
params [["_uid", "", [""]]];
if (!isServer || {!isRemoteExecuted} || {isRemoteExecutedJIP}) exitWith {};

private _requestOwner = remoteExecutedOwner;
private _requester = (allPlayers select {
    (owner _x) isEqualTo _requestOwner && {!(_x isKindOf "HeadlessClient_F")}
}) param [0, objNull];
if (isNull _requester || {!((getPlayerUID _requester) in (["ALL"] call QS_fnc_whitelist))}) exitWith {};

// Resolve by UID so a respawn while the menu is open still targets this player.
private _unit = (allPlayers select {
    (getPlayerUID _x) isEqualTo _uid && {isPlayer _x} && {!(_x isKindOf "HeadlessClient_F")}
}) param [0, objNull];
if (_uid isEqualTo "" || {isNull _unit}) exitWith {
    ["systemChat", "The selected player is no longer connected."] remoteExec ["QS_fnc_remoteExecCmd", _requestOwner, false];
};

// Rifleman belongs to WEST in the role configuration. The normal handler also
// releases the previous slot/queue, removes role-owned UAVs, and initializes
// the player's Rifleman traits, arsenal, and saved/default loadout on their PC.
["HANDLE_REQUEST_ROLE", _uid, WEST, "rifleman", _unit, false, true, format ["staff:%1", getPlayerUID _requester]] call QS_fnc_roles;
if ((_unit getVariable ["QS_unit_role", ""]) isNotEqualTo "rifleman" || {
    (_unit getVariable ["QS_unit_side", WEST]) isNotEqualTo WEST
}) exitWith {
    ["systemChat", "The Rifleman role could not be assigned. Check the server's role configuration."] remoteExec ["QS_fnc_remoteExecCmd", _requestOwner, false];
};

["QUEUE_PROCESS"] call QS_fnc_roles;
["systemChat", format ["Changed %1's role to Rifleman.", name _unit]] remoteExec ["QS_fnc_remoteExecCmd", _requestOwner, false];
diag_log format ["Staff %1 (%2) forced %3 (%4) to Rifleman.", name _requester, getPlayerUID _requester, name _unit, _uid];
