// Integration/structural regression checks. Actual SQF behavior: validate_engine.sqf.
const fs = require('node:fs');
const path = require('node:path');
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
          else {closed = true; break;}
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
for (const name of ['defendAssault', 'aoDefend', 'AIHandleUnit', 'AIHandleGroup', 'AIXHeliInsert', 'AIDoSuppressiveFire', 'AIXSuppressiveFire', 'AIGroupEventEnemyDetected', 'AIGroupEventCombatModeChanged']) balanced(fn(name), name);
balanced(read('tests/defend-assault/validate_engine.sqf'), 'engine harness');
const defend = fn('aoDefend');
const controller = fn('defendAssault');
assert.equal((defend.match(/\['REGISTER',/g) || []).length, 6, 'All six infantry arrival paths must register');
assert(!/FiredNear|removeAllEventHandlers 'Hit'|QS_defendFlank|_fn_flank|QS_defend_propulsion/.test(defend), 'Legacy unlock/diversion/propulsion must be retired');
for (const subject of ['units _grp', 'units _grp2', 'units _grp3', '[_parajumper]', '[_paratrooper]']) {
  assert(defend.includes(`['REGISTER',${subject},_defendEpoch,_centerPos]`), `Missing ${subject} registration`);
}
assert(defend.indexOf("['STOP',[],_defendEpoch]") < defend.indexOf('sleep 3;', defend.indexOf('MEGA_DEFENSE_CLOSING_BEGIN')), 'Release before native cleanup');
assert(controller.includes('isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}'), 'Only server may remotely dispatch orders');
assert(!/\b(allUnits|allGroups|allMissionObjects|nearEntities|nearestObjects)\b/.test(controller), 'Use bounded activity roster');
assert.equal((controller.match(/uiSleep/g) || []).length, 1, 'Only one shared worker');
assert(controller.includes("private _owner = owner _x;"), 'Route to actual unit owner');
assert(controller.includes("if (local _unit && {alive _unit}"), 'Owner-local commands only');
assert(controller.includes("['RELEASE',missionNamespace getVariable ['QS_defendAssault_roster',[]],_epoch]"));
assert(controller.includes("['Local',{") && controller.includes("getForcedSpeed _unit"), 'Locality reinit and speed restoration');
assert(controller.includes("currentCommand _unit in ['','STOP','WAIT']") && controller.includes('_now + 8'), 'Retry only stalled/lost orders with cooldown');
assert(fn('AIHandleUnit').indexOf("['MANAGED'") < fn('AIHandleUnit').indexOf('// Keep non-sniper'), 'Defense bypass precedes native unit mutations');
const handoff = fn('AIXHeliInsert').split("if (_activity isEqualTo 'DEFENSE' && {call _fn_current}) then {")[1].split('_releaseComplete = TRUE;')[0];
assert(handoff.includes("['TICK',units _cargo,_epoch,_goal]"));
assert(!/enableAIFeature|doFollow| move /.test(handoff), 'Delivery cannot unlock targeting or overwrite rush orders');
assert(read('Apex_framework.terrain/description.ext').includes('class defendAssault {file = "code\\functions\\fn_defendAssault.sqf";};'));
assert(read('Apex_framework.terrain/code/config/security.hpp').includes('class QS_fnc_defendAssault {allowedTargets = 0; jip = 0;};'));
console.log('PASS: Defense assault structural, arrival coverage, locality, cleanup and competing-order integration checks.');

assert.equal((controller.match(/\b150\b/g) || []).length, 1, 'One default radius only');
assert(controller.includes("_mode isEqualTo 'COVER_ELIGIBLE'"));
assert(controller.includes('_coverUntil > serverTime && {_coverEligible}'));
assert(controller.includes('if (!_coverActive &&'));
assert(fn('AIHandleUnit').includes("['COVER_ELIGIBLE',_unit"));
assert(fn('AIHandleUnit').includes("['COVER_ELIGIBLE',_x"));
for (const name of ['AIDoSuppressiveFire','AIXSuppressiveFire']) {
 assert(fn(name).includes("['COVER_BLOCKED',_unit]"));
 assert(fn(name).includes("['COVER_BLOCKED',_shooter]"), 'Deferred callback must recheck shooter');
}
