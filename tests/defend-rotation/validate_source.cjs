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
const randomGate = defend.indexOf('if ((_defendLogRoll > 0.666)');
assert(randomGate >= 0 && admission > randomGate);

const staff = fs.readFileSync(path.join(root, 'Apex_framework.terrain/TGC/Functions/Staff/fn_manageMainAO.sqf'), 'utf8');
const executable = source => source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\r\n]*/g, '');
const entry = executable(defend).split('_defendMessages = [')[0];
assert.equal((entry.match(/\brandom\s+1\b/g) || []).length, 1, 'Entry logging must reuse the single admission roll');
assert.equal((entry.match(/count \(\(units WEST\)/g) || []).length, 1, 'Entry logging must reuse the nearby-unit census');
assert(entry.indexOf('[Defend] START') > entry.indexOf("['QS_defendActive',TRUE,TRUE]"), 'START must confirm admission, not merely an attempt');
assert.equal((entry.match(/\['QS_defendCount',/g) || []).length, 2, 'Only counter read for SKIP and original admission increment');
for (const reason of ['MISSION_TIME', 'FPS', 'NEARBY_UNITS', 'RANDOM_ROLL', 'DISABLED_ONCE', 'DISABLED_PERSISTENT']) {
  assert(entry.includes(`['${reason}',`), `Missing entry rejection reason ${reason}`);
}
assert(core.indexOf('[Defend] AO_START') < core.indexOf('_aoArray = [_ao] call _fn_aoPrepare;'));
assert(core.indexOf('[Defend] DECISION') < core.indexOf('if (_normalAO_shouldDefend) then'));
assert(core.includes('if (_defendLogForceNow isNotEqualTo _defendLogForceLast) then'), 'Force observer must be change-only');
assert(staff.indexOf('[Defend] STAFF_REQUEST') > staff.indexOf('A Defend is already queued'), 'Audit only accepted, validated menu requests');
assert.equal((staff.match(/call _logCancelledDefend;/g) || []).length, 2, 'Cycle and pause must both audit cancellation');
assert(core.includes("setVariable ['QS_staffDefendLogRequest',[]]"), 'Consumed request metadata must be cleared');
assert(entry.includes("setVariable ['QS_staffDefendLogStarting',[]]"), 'Entry must consume starting metadata even if rejected');

// Check every diagnostic format against its arguments, including %10 and above.
// Missing arguments here would hide precisely the state these logs must expose.
function checkLogFormats(source) {
  const pattern = /diag_log format \[(['"])(\[Defend\][^\r\n]*?)\1,/g;
  let match;
  let checked = 0;
  while ((match = pattern.exec(source))) {
    const stack = [];
    let args = 1;
    let i = pattern.lastIndex;
    for (; i < source.length; i++) {
      const char = source[i];
      if (char === '"' || char === "'") {
        const quote = char;
        let closed = false;
        while (++i < source.length) {
          if (source[i] === quote) {
            if (source[i + 1] === quote) i++;
            else { closed = true; break; }
          }
        }
        assert(closed, 'Unclosed diagnostic argument string');
      } else if (char === ']' && stack.length === 0) break;
      else if ('([{'.includes(char)) stack.push(char);
      else if (')]}'.includes(char)) assert.equal(stack.pop(), '([{'[')]}'.indexOf(char)]);
      else if (char === ',' && stack.length === 0) args++;
    }
    assert(i < source.length, 'Unclosed diagnostic format array');
    const fields = [...match[2].matchAll(/%(\d+)/g)].map(field => Number(field[1]));
    assert.equal(Math.max(...fields), args, `Argument count: ${match[2]}`);
    for (let field = 1; field <= args; field++) assert(fields.includes(field), `Unused argument ${field}`);
    checked++;
  }
  return checked;
}
assert(checkLogFormats(core) >= 5);
assert(checkLogFormats(defend) >= 4);
assert(checkLogFormats(staff) >= 3);
console.log('PASS: Defend rotation history, admission accounting, launch and cleanup integration.');
console.log('PASS: Diagnostic format arguments, single-roll admission, accepted staff auditing and metadata consumption.');
