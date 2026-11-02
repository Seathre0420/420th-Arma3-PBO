/* Read-only network entry point. Caller-supplied modes/data are ignored. */
if (!isServer || {!isRemoteExecuted} || {remoteExecutedOwner <= 2}) exitWith {};
['REQUEST'] call QS_fnc_taskSyncServer;
