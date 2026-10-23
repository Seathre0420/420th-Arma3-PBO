/* Ignore unsolicited replies and replies from an old session or owner. */
if (!isRemoteExecuted || {isRemoteExecutedJIP} || {!hasInterface}) exitWith {};
params ['_vehicle','_unit','_token','_mode','_phase','_reason','_remaining','_level'];
private _active = localNamespace getVariable ['QS_engineerService_client',[]];
if (count _active != 6) exitWith {};
_active params ['_expectedVehicle','_expectedUnit','_expectedToken','_expectedMode','_expectedOwner','_state'];
if (_vehicle != _expectedVehicle || {_unit != _expectedUnit} || {_token != _expectedToken} ||
    {_mode != _expectedMode} || {remoteExecutedOwner != _expectedOwner}) exitWith {};
if (!(_phase in ['accepted','running','complete','cancelled','rejected'])) exitWith {};
_active set [5,[_phase,_reason,_remaining,_level,diag_tickTime]];
localNamespace setVariable ['QS_engineerService_client',_active];
