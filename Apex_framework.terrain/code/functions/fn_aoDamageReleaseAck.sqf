/* Only a pending entity's current owner can confirm its damage state. */
params [['_epoch',-1,[0]],['_replies',[],[[]]]];
if (!isServer || {count _replies > 32}) exitWith {};
private _sender = remoteExecutedOwner;
private _jobs = missionNamespace getVariable ['QS_classicDamage_releaseJobs',createHashMap];
private _job = _jobs getOrDefault [_epoch,[]];
if (_job isEqualTo []) exitWith {};
private _requests = _job # 2;
// Arma masks a headless sender's ID as zero. Only the targeted owner received its request token.
private _headlessOwners = if (_sender isEqualTo 0) then {(entities 'HeadlessClient_F') apply {owner _x}} else {[]};
{
	if (_x isEqualTypeArray ['',[]]) then {
		_x params ['_id','_token'];
		private _request = _requests getOrDefault [_id,[]];
		if (_request isNotEqualTo []) then {
			_request params ['_entity','_requestedOwner','','_expectedToken'];
			if (!isNull _entity && {owner _entity isEqualTo _requestedOwner} &&
				{_requestedOwner isEqualTo _sender || {_requestedOwner in _headlessOwners}} &&
				{_token isEqualTo _expectedToken} && {(_entity getVariable ['QS_classicDamage_epoch',-2]) isEqualTo _epoch}) then {
				_request set [2,TRUE];
			};
		};
	};
} forEach _replies;
