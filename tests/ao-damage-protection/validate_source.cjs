// Offline syntax-shape and integration checks; combat/locality require Arma.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8').replace(/\r/g, '');
const fn = name => read(`Apex_framework.terrain/code/functions/fn_${name}.sqf`);

function balanced(source, name) {
  const stack = [];
  let i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      const end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end + 1;
    } else if (source.startsWith('/*', i)) {
      const end = source.indexOf('*/', i + 2);
      assert(end >= 0, `${name}: unterminated comment`);
      i = end + 2;
    } else if ('"\''.includes(source[i])) {
      const quote = source[i++];
      let closed = false;
      while (i < source.length) {
        if (source[i++] === quote) {
          if (source[i] === quote) i++;
          else { closed = true; break; }
        }
      }
      assert(closed, `${name}: unterminated string`);
    } else {
      const char = source[i++];
      if ('([{'.includes(char)) stack.push(char);
      if (')]}'.includes(char)) assert.equal(stack.pop(), '([{'[')]}'.indexOf(char)], `${name}: mismatched delimiter`);
    }
  }
  assert.equal(stack.length, 0, `${name}: unclosed delimiter`);
}
const names = ['aoDamageProtection', 'aoDamageArrival', 'aoDamageReleasePending', 'aoDamageReleaseAck', 'clientCore', 'core', 'AI', 'aoEnemy', 'unitSetup',
  'aoEnemyReinforce', 'aoEnemyReinforceVehicles', 'aoBoatPatrol', 'serverObjectsMapper',
  'serverObjectsRecycler', 'createAAVehicle', 'AIXHeliInsert', 'AIXHeliInsertLanding', 'scSpawnHeli'];
for (const name of names) balanced(fn(name), name);
balanced(read('tests/ao-damage-protection/validate_engine.sqf'), 'engine harness');
const controller = fn('aoDamageProtection');
// Regression: Object keys raise an engine type error and leave _entry undefined.
assert(controller.includes('private _key = netId _arg;'), 'Handler registry must use string network IDs');
assert(controller.includes('_handlers getOrDefault [_key,[-1,-1,-1,-1]]'), 'Handler lookup must use a supported key and complete default entry');
assert(controller.includes('_handlers set [_key,[_epoch,_damageEH,_localEH,_deletedEH]]'), 'Handler insert must use the same string key');
assert.equal((controller.match(/deleteAt _key;/g) || []).length, 2, 'Release and deletion must both remove the string key');
assert(!/_handlers\s+(?:getOrDefault|set)\s*\[\s*_arg\b|deleteAt\s+_(?:arg|entity)\b/.test(controller), 'Object-key registry operations must not return');
assert(controller.includes("_entity getVariable ['QS_classicDamage_handlerKey','']"), 'Deletion must use the cached key');
assert(read('Apex_framework.terrain/description.ext').includes('class aoDamageProtection {file = "code\\functions\\fn_aoDamageProtection.sqf";};'));
assert(/class QS_fnc_aoDamageProtection \{allowedTargets = 0; jip = 1;\};/.test(read('Apex_framework.terrain/code/config/security.hpp')));
assert(controller.includes('isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}'), 'Remote state changes must reject clients');
assert(controller.includes("if (!isServer) exitWith {FALSE}"), 'Only server may change AO state');
assert(!/\b(allUnits|allMissionObjects|nearestObjects)\b/.test(controller), 'No world-wide enemy census');

// These legacy objective rules are deliberately retained byte-for-byte.
const core = fn('core');
const marker = '/*/Certain targets are invincible until ground elements are near/*/';
const endMarker = '_QS_ao_invincibility_checkDelay = _timeNow + _QS_ao_invincibility_delay;';
const start = core.indexOf(marker);
const end = core.indexOf(endMarker, start) + endMarker.length;
assert(start >= 0 && end > start);
assert.equal(crypto.createHash('sha256').update(core.slice(start, end)).digest('hex'),
  '817b02897d8c59c69f3dc3a6c46c7fb101369bad19d8a39934e5000a441a1fad',
  'Commander/radio-tower legacy damage conditions changed');
assert(!fn('aoDefend').includes('QS_classicDamage'), 'Defend must not opt into protection');
const startLock = core.indexOf("['START',_QS_AOpos,-1,_aoName] call QS_fnc_aoDamageProtection");
assert(startLock >= 0 && startLock < core.indexOf('_aoArray = [_ao] call _fn_aoPrepare;'), 'Lock must precede AO preparation');
assert(core.indexOf("['STOP'] call QS_fnc_aoDamageProtection;") < core.indexOf("diag_log 'Main AO deactivating';"), 'Release must precede Defend handoff/cleanup');

// Validate the scope across asynchronous creation and shared spawn helpers.
assert(fn('aoEnemy').includes("['_QS_classicDamageEpoch',-1]"));
assert(fn('AI').includes('_QS_module_classic_aoData,_QS_classicDamageEpoch] spawn _fn_aoEnemy'));
assert(fn('AI').includes("params ['_spawnUrban','_QS_classicDamageEpoch'];"));
assert(fn('AI').includes("['damageEpoch',(missionNamespace getVariable ['QS_classicDamage_context',[-1]]) # 0]"));
assert(fn('unitSetup').indexOf("['REGISTER',[_unit],_QS_classicDamageEpoch]") < fn('unitSetup').indexOf('exitWith'));
assert(fn('scSpawnHeli').indexOf('private _QS_classicDamageEpoch = -1;') < fn('scSpawnHeli').indexOf('QS_fnc_unitSetup'), 'Unseated aircraft operators must be excluded');
for (const name of ['aoEnemyReinforceVehicles', 'aoBoatPatrol', 'serverObjectsMapper']) {
  assert(fn(name).includes("if (!isNil '_QS_classicDamageEpoch')"), `${name}: must require explicit scope`);
}
assert(fn('AIXHeliInsertLanding').includes("params ['_groupLeader',['_QS_classicDamageEpoch',-1]];"));
assert(fn('AIXHeliInsert').includes("(vehicle (leader _group)) getVariable ['QS_classicDamage_insertEpoch',-1]"));
assert(fn('serverObjectsRecycler').includes("_object setVariable ['QS_classicDamage_epoch',nil,TRUE]"), 'Recycler must invalidate callbacks on every owner');
assert(controller.includes("_epoch isNotEqualTo (_context # 0)"), 'Old spawn epochs must be rejected');
assert(controller.includes("_current && {local _arg}"), 'Stale releases must not change reused entities');
assert(fn('aoEnemy').includes("['ALLOW',_vehicle,_epoch]"), 'Delayed armor callbacks must carry their AO epoch');
assert(fn('createAAVehicle').includes("['ALLOW',_vehicle,_epoch]"), 'Delayed AA-site callbacks must carry their AO epoch');
const release = fn('aoDamageReleasePending');
assert(release.includes("remoteExec ['',_jipID]"), 'Persistent installs must be retired');
const arrival = fn('aoDamageArrival');
assert(/class QS_fnc_aoDamageArrival \{allowedTargets = 2; jip = 0;\};/.test(read('Apex_framework.terrain/code/config/security.hpp')));
assert(read('Apex_framework.terrain/description.ext').includes('class aoDamageArrival {file = "code\\functions\\fn_aoDamageArrival.sqf";};'));
assert(arrival.includes('owner _unit isNotEqualTo _caller'), 'Arrival reports must validate player ownership');
assert(arrival.includes('_epoch isNotEqualTo (_context # 0)'), 'Stale arrival reports must be rejected');
assert(arrival.includes('> 2000'), 'Server must enforce the arrival radius');
assert(!controller.includes('isTouchingGround'), 'Server monitor must not depend on remote ground contact');
assert(fn('clientCore').includes('isTouchingGround player'), 'Client must observe its own ground contact');
assert(fn('clientCore').includes('_classicDamageReportAfter = _QS_uiTime + 1'), 'Arrival retries must be bounded');
assert(controller.includes("_mode in ['LOCAL','ALLOW','RELEASE'] && {canSuspend}"), 'Entity damage updates must be unscheduled');
assert(controller.includes('QS_classicDamage_releasedEpoch'), 'Explicit release must supersede stale replicated lock state');
const transition = controller.slice(controller.indexOf("if (_mode in ['UNLOCK','STOP'])"));
assert(transition.includes("_jobs set [_releaseEpoch,[") &&
  transition.indexOf("missionNamespace setVariable ['QS_classicDamage_entities',[]];") <
  transition.indexOf('call QS_fnc_aoDamageReleasePending'), 'Release must retain a detached job before dispatch');
assert(core.includes("['MONITOR'] call QS_fnc_aoDamageProtection;") &&
  core.includes('call QS_fnc_aoDamageReleasePending;'), 'Core must recover monitor and service release jobs');
assert(/class QS_fnc_aoDamageReleaseAck \{allowedTargets = 2; jip = 0;\};/.test(read('Apex_framework.terrain/code/config/security.hpp')));
const ack = fn('aoDamageReleaseAck');
assert(ack.includes('owner _entity isEqualTo _requestedOwner') && ack.includes('_token isEqualTo _expectedToken'));
assert(ack.includes("if (_sender isEqualTo 0) then {(entities 'HeadlessClient_F') apply {owner _x}} else {[]}") &&
  ack.includes('_requestedOwner isEqualTo _sender || {_requestedOwner in _headlessOwners}'),
  'Only headless owners can use the masked sender path');
assert(release.includes('if ((_request # 1) isNotEqualTo _owner)') && release.includes('_entities pushBack [_entity,_request # 3]') &&
  controller.includes('_verified pushBack [netId _entity,_token]'), 'Preserve the owner token across retries and echo it with the verified entity');
const monitor = controller.slice(controller.indexOf("if (_mode isEqualTo 'MONITOR')"), controller.indexOf("if (_mode isEqualTo 'DIAGNOSE'"));
assert(monitor.includes("['TICK',objNull,_currentEpoch]") && monitor.indexOf("['TICK',objNull,_currentEpoch]") < monitor.indexOf('!scriptDone _monitor'),
  'An accepted arrival must have a path past a stalled live monitor');
assert(release.includes('_epochs findIf {_x > _lastEpoch}') && release.includes("['QS_classicDamage_lastReleaseEpoch',_epoch]"),
  'Another epoch must get a turn when an older queue fills the pass');
assert(release.includes("scriptDone (missionNamespace getVariable ['QS_classicDamage_releaseWorker',scriptNull])") &&
  release.includes('uiSleep 1;\n\t\t\t\tcall QS_fnc_aoDamageReleasePending;'), 'Keep large releases moving while the core loop is busy');
assert(fn('serverObjectsMapper').includes("['ALLOW',_newObj,_QS_classicDamageEpoch]") &&
  fn('serverObjectsMapper').includes("_newObj isKindOf 'StaticWeapon'"), 'Hostile Classic statics must follow the gate across unlock');
assert(fn('aoEnemy').includes("_object allowDamage (_object isKindOf 'StaticWeapon');"), 'Late tower weapons must start vulnerable while walls stay protected');
console.log(`PASS: ${names.length + 1} SQF files structurally balanced; legacy objectives, Defend isolation, spawn scope, recycler and JIP lifecycle checked. Engine test required.`);
