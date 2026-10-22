const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const core = fs.readFileSync(path.join(root, 'Apex_framework.terrain/code/functions/fn_core.sqf'), 'utf8');
const defend = fs.readFileSync(path.join(root, 'Apex_framework.terrain/code/functions/fn_aoDefend.sqf'), 'utf8');
function block(name) {
  const start = `// DEFEND_ROTATION_${name}_BEGIN`;
  const end = `// DEFEND_ROTATION_${name}_END`;
  assert.equal(core.split(start).length, 2);
  assert.equal(core.split(end).length, 2);
  return core.split(start)[1].split(end)[0];
}
for (const name of ['INIT', 'ADVANCE', 'DECISION']) assert(block(name).trim());
const advance = core.indexOf('// DEFEND_ROTATION_ADVANCE_BEGIN');
assert(advance > core.indexOf('_ao = selectRandom _aoList;'));
assert(advance < core.indexOf('_classicLastAOId = _ao # 0;'));
assert.equal((core.match(/if \(_normalAO_shouldDefend\) then/g) || []).length, 1);
assert(core.includes('_QS_AOpos,\n') || core.includes('_QS_AOpos,\r\n'));
assert(/_QS_AOpos,[\s\S]*?_normalAO_shouldDefend,[\s\S]*?_normalAO_defendScript\s*\] spawn/.test(core));
// History must use actual admission, not the core's optimistic script-launch flags.
assert(!block('ADVANCE').includes('_defendAOActive'));
const admission = defend.indexOf("['QS_defendCount',((missionNamespace getVariable 'QS_defendCount') + 1)");
assert(admission > defend.indexOf('if (_defendForce isEqualTo -2) exitWith'));
assert(admission > defend.indexOf('if (((random 1) > 0.666)'));
console.log('PASS: Defend rotation history, admission accounting, launch and cleanup integration.');
