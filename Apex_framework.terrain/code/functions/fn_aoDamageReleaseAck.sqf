/* Only a pending entity's current owner can confirm its damage state. */
params [['_epoch',-1,[0]],['_ids',[],[[]]]];
if (!isServer || {!isRemoteExecuted} || {count _ids > 32}) exitWith {};
private _sender = remoteExecutedOwner;
private _jobs = missionNamespace getVariable ['QS_classicDamage_releaseJobs',createHashMap];
private _job = _jobs getOrDefault [_epoch,[]];
if (_job isEqualTo []) exitWith {};
private _requests = _job # 2;
{
	if (_x isEqualType '') then {
		private _request = _requests getOrDefault [_x,[objNull,-1,FALSE]];
		_request params ['_entity','_requestedOwner'];
		if (!isNull _entity && {_requestedOwner isEqualTo _sender} && {owner _entity isEqualTo _sender} &&
			{(_entity getVariable ['QS_classicDamage_epoch',-2]) isEqualTo _epoch}) then {
			_request set [2,TRUE];
		};
	};
} forEach _ids;
