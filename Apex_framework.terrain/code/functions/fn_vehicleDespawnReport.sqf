/* Client provenance only; cannot manufacture a server deletion event. */
params [['_mode',''],['_value',[]],['_reason',''],['_source',''],['_detail',[]]];
if (isRemoteExecuted) exitWith {
	if (isServer && {!isRemoteExecutedJIP} && {remoteExecutedOwner > 2} &&
		{_mode isEqualTo 'REPORT'} && {_value isEqualType []} && {count _value isEqualTo 16} &&
		{(_value # 2) isEqualType ''} && {count (_value # 2) <= 64} &&
		{(_value # 3) isEqualTo remoteExecutedOwner} &&
		{(allPlayers findIf {owner _x isEqualTo remoteExecutedOwner}) >= 0} &&
		{_reason in ['ABANDONED','SPAWN_PROTECTION','DISCONNECT','MANUAL','UAV_CLEANUP','WRECK_CLEANUP','GARBAGE_COLLECTION','MISSION_CLEANUP','REPLACED','REMOVED']} &&
		{_source isEqualType ''} && {count _source <= 160} &&
		{count (str _value) <= 8192} && {count (str _detail) <= 2048}
	) then {
		private _reports = serverNamespace getVariable ['QS_despawn_reports',createHashMap];
		// Evict only provenance, never actual deletion records, under hostile input.
		if (count _reports < 4096) then {
			_reports set [_value # 2,[diag_tickTime,_value,_reason,_source,_detail,remoteExecutedOwner]];
		};
	};
};
