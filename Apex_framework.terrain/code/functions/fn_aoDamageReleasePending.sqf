/* The server services detached release jobs even after the next AO starts.
 * Process 32 entities per pass across all epochs, rotating unverified entries.
 */
if (!isServer || {isRemoteExecuted}) exitWith {};
isNil {
	private _jobs = missionNamespace getVariable ['QS_classicDamage_releaseJobs',createHashMap];
	private _budget = 32;
	private _epochs = keys _jobs;
	_epochs sort TRUE;
	// Resume after the last serviced epoch so old retries cannot monopolize the budget.
	private _lastEpoch = missionNamespace getVariable ['QS_classicDamage_lastReleaseEpoch',-1];
	private _nextIndex = _epochs findIf {_x > _lastEpoch};
	if (_nextIndex > 0) then {_epochs = (_epochs select [_nextIndex]) + (_epochs select [0,_nextIndex]);};
	{
		private _epoch = _x;
		private _job = _jobs get _epoch;
		_job params ['_name','_queue','_requests','_verifiedByOwner','_retired','_deadline'];
		private _batches = createHashMap;
		private _unresolved = _job # 6;
		private _sample = _job # 7;
		private _batchSize = _budget min count _queue;
		_budget = _budget - _batchSize;
		private _batch = _queue select [0,_batchSize];
		_queue deleteRange [0,_batchSize];
		{
			_x params ['_entity','_jipID',['_attempts',0]];
			private _id = netId _entity;
			private _observedEpoch = _entity getVariable ['QS_classicDamage_epoch',-2];
			if (_jipID isNotEqualTo '') then {
				remoteExec ['',_jipID];
				_x set [1,''];
				if (!isNull _entity && {_observedEpoch isEqualTo _epoch}) then {
					_entity setVariable ['QS_classicDamage_protected',FALSE,TRUE];
					['RELEASE',_entity,_epoch] call QS_fnc_aoDamageProtection;
					['RELEASE',_entity,_epoch] remoteExecCall ['QS_fnc_aoDamageProtection',-2,FALSE];
				};
			};
			if (isNull _entity || {!alive _entity} || {_observedEpoch isNotEqualTo _epoch}) then {
				_requests deleteAt _id;
				_retired = _retired + 1;
			} else {
				private _owner = owner _entity;
				private _request = _requests getOrDefault [_id,[objNull,-1,FALSE,[],0]];
				private _verified = (_request # 1) isEqualTo _owner && {_request # 2};
				if (local _entity) then {
					['RELEASE',_entity,_epoch] call QS_fnc_aoDamageProtection;
					_verified = isDamageAllowed _entity;
				};
				if (_verified) then {
					_requests deleteAt _id;
					_verifiedByOwner set [_owner,1 + (_verifiedByOwner getOrDefault [_owner,0])];
				} else {
					// Allow a final ownership transfer time to answer, bounded to ten seconds past the job deadline.
					private _waitingForOwner = _owner > 2 && {(_request # 1) isNotEqualTo _owner || {diag_tickTime < (_request # 4)}};
					if (diag_tickTime >= _deadline && {_attempts >= 3} && {!_waitingForOwner || {diag_tickTime >= _deadline + 10}}) then {
						_requests deleteAt _id;
						_unresolved set [_owner,1 + (_unresolved getOrDefault [_owner,0])];
						if (count _sample < 8) then {
							private _reason = if (local _entity) then {'damage-disabled'} else {'no-current-owner-ack'};
							_sample pushBack [_id,_epoch,_observedEpoch,_owner,_reason];
						};
					} else {
						_x set [2,_attempts + 1];
						_queue pushBack _x;
						if (_owner > 2) then {
							// Keep the token on retries to this owner. Replace it when ownership changes.
							if ((_request # 1) isNotEqualTo _owner) then {
								_request = [_entity,_owner,FALSE,[floor random 1000000,floor random 1000000],diag_tickTime + 5];
								_requests set [_id,_request];
							};
							private _entities = _batches getOrDefault [_owner,[]];
							_entities pushBack [_entity,_request # 3];
							_batches set [_owner,_entities];
						};
					};
				};
			};
		} forEach _batch;
		{
			['VERIFY_RELEASE',_y,_epoch] remoteExecCall ['QS_fnc_aoDamageProtection',_x,FALSE];
		} forEach _batches;
		_job set [4,_retired];
		missionNamespace setVariable ['QS_classicDamage_lastReleaseEpoch',_epoch];
		if (_queue isEqualTo []) then {
			diag_log format ['[AO damage] RELEASE_COMPLETE ao=%1 epoch=%2 verifiedByOwner=%3 retired=%4 unresolvedByOwner=%5 sample=%6',
				_name,_epoch,_verifiedByOwner,_retired,_unresolved,_sample];
			_jobs deleteAt _epoch;
		};
		if (_budget isEqualTo 0) exitWith {};
	} forEach _epochs;
	// The main mission loop can spend several seconds preparing the next AO.
	// Continue releasing a large queue during that time, with one worker for all epochs.
	if (count _jobs > 0 && {scriptDone (missionNamespace getVariable ['QS_classicDamage_releaseWorker',scriptNull])}) then {
		private _worker = [] spawn {
			while {count (missionNamespace getVariable ['QS_classicDamage_releaseJobs',createHashMap]) > 0} do {
				uiSleep 1;
				call QS_fnc_aoDamageReleasePending;
			};
		};
		missionNamespace setVariable ['QS_classicDamage_releaseWorker',_worker];
	};
};
