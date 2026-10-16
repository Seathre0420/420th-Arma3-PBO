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
const names = ['aoDamageProtection', 'core', 'AI', 'aoEnemy', 'unitSetup',
  'aoEnemyReinforce', 'aoEnemyReinforceVehicles', 'aoBoatPatrol', 'serverObjectsMapper',
  'serverObjectsRecycler', 'createAAVehicle', 'AIXHeliInsert', 'AIXHeliInsertLanding', 'scSpawnHeli'];
for (const name of names) balanced(fn(name), name);
balanced(read('tests/ao-damage-protection/validate_engine.sqf'), 'engine harness');
const controller = fn('aoDamageProtection');
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
assert(core.indexOf("['START',_QS_AOpos]") < core.indexOf('_aoArray = [_ao] call _fn_aoPrepare;'), 'Lock must precede AO preparation');
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
assert(controller.includes("remoteExec ['',_jipID]"), 'Persistent installs must be retired');
console.log(`PASS: ${names.length + 1} SQF files structurally balanced; legacy objectives, Defend isolation, spawn scope, recycler and JIP lifecycle checked. Engine test required.`);
